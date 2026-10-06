#!/usr/bin/env python3

import json
import subprocess
import sys
import os
import threading
import tempfile
import urllib.parse
import urllib.request
from panel_position import keep_top_on_resize
from panel_grab import dismiss_on_outside_click
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk
from panel_theme import install_panel_css


APP_ID = "dev.local.WeatherPanel"
SCRIPT = Path(__file__).with_name("weather-status.sh")


class WeatherPanel(Adw.Application):
    def __init__(self) -> None:
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.NON_UNIQUE)
        GLib.set_prgname(APP_ID)
        GLib.set_application_name("Weather")
        self.widgets: dict[str, Gtk.Label] = {}
        self.search_timer = 0
        self.search_generation = 0
        self.refresh_running = False
        self.location_generation = 0
        self.session_directory = tempfile.TemporaryDirectory(prefix="weather-panel-")
        self.session_location = None
        self.connect("shutdown", lambda *_: self.session_directory.cleanup())

    def do_activate(self) -> None:
        self.window = Adw.ApplicationWindow(application=self)
        self.window.set_title("Weather")
        self.window.set_default_size(560, 250)
        self.window.set_resizable(False)

        self.install_css()
        self.build_ui()
        self.refresh()

        key = Gtk.EventControllerKey()
        key.connect("key-pressed", self.on_key_pressed)
        self.window.add_controller(key)

        GLib.timeout_add_seconds(900, self.refresh)
        dismiss_on_outside_click(self.window)
        self.window.present()
        keep_top_on_resize(self.window, APP_ID)

    def install_css(self) -> None:
        css = b"""
        window {
          background: rgba(24, 24, 36, 0.94);
          color: #cdd6f4;
        }

        .panel {
          padding: 18px;
        }

        .hero-icon {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 64px;
          color: #ffffff;
        }

        .hero-temp {
          font-size: 56px;
          font-weight: 800;
          color: #ffffff;
        }

        .hero-unit {
          font-size: 20px;
          color: #ffffff;
        }

        .alternate-temp {
          font-size: 12px;
          opacity: 0.72;
        }

        .location {
          font-size: 12px;
          font-weight: 800;
          letter-spacing: 1.1px;
          color: rgba(205, 214, 244, 0.72);
        }

        .location-icon {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 14px;
          color: rgba(205, 214, 244, 0.72);
        }

        .location-button {
          padding: 0;
          background: transparent;
          box-shadow: none;
          border: none;
        }

        window button.city-control {
          border-radius: 7px;
          border: none;
          box-shadow: none;
          background-image: none;
          background: rgba(205, 214, 244, 0.08);
          color: #cdd6f4;
        }

        window button.city-control:hover {
          background: rgba(205, 214, 244, 0.16);
        }

        window entry.city-search {
          border-radius: 7px;
          border: 1px solid rgba(205, 214, 244, 0.12);
          box-shadow: none;
          background-image: none;
          background: rgba(205, 214, 244, 0.08);
          color: #cdd6f4;
          caret-color: #cdd6f4;
        }

        window entry.city-search:focus-within {
          border-color: {{accent}};
          outline-color: {{accent}};
        }

        window entry.city-search image {
          color: rgba(205, 214, 244, 0.72);
        }

        .condition {
          font-size: 12px;
          font-weight: 700;
          color: rgba(205, 214, 244, 0.72);
        }

        .metric-label,
        .forecast-day {
          font-size: 10px;
          font-weight: 800;
          letter-spacing: 1px;
          color: rgba(205, 214, 244, 0.58);
        }

        .metric-value,
        .forecast-temp {
          font-size: 13px;
          font-weight: 800;
          color: #ffffff;
        }

        .forecast-icon {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 28px;
          color: #ffffff;
        }

        .divider {
          min-height: 1px;
          background: rgba(255, 255, 255, 0.12);
        }
        """
        install_panel_css(css.decode())

    def build_ui(self) -> None:
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        root.add_css_class("panel")
        self.window.set_content(root)

        hero = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        hero.set_size_request(-1, 116)
        root.append(hero)

        icon = Gtk.Label(label="󰖐")
        icon.add_css_class("hero-icon")
        icon.set_size_request(76, -1)
        icon.set_valign(Gtk.Align.CENTER)
        hero.append(icon)
        self.widgets["icon"] = icon

        temp_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        temp_row.set_valign(Gtk.Align.CENTER)
        hero.append(temp_row)

        temp = Gtk.Label(label="--")
        temp.add_css_class("hero-temp")
        temp_row.append(temp)
        self.widgets["temp"] = temp

        units = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        units.set_valign(Gtk.Align.CENTER)
        temp_row.append(units)

        unit = Gtk.Label(label="")
        unit.add_css_class("hero-unit")
        unit.set_halign(Gtk.Align.START)
        units.append(unit)
        self.widgets["unit"] = unit

        alternate = Gtk.Label(label="")
        alternate.add_css_class("alternate-temp")
        alternate.set_halign(Gtk.Align.START)
        units.append(alternate)
        self.widgets["alternate"] = alternate

        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        right.set_hexpand(True)
        right.set_halign(Gtk.Align.END)
        right.set_valign(Gtk.Align.CENTER)
        hero.append(right)

        location_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        location_row.set_halign(Gtk.Align.START)
        self.location_stack = Gtk.Stack()
        right.append(self.location_stack)
        location_button = Gtk.Button()
        location_button.add_css_class("location-button")
        location_button.set_child(location_row)
        location_button.set_cursor_from_name("pointer")
        location_button.connect("clicked", self.start_city_search)
        self.location_stack.add_named(location_button, "location")

        search_row = Gtk.Box(spacing=6)
        self.city_entry = Gtk.SearchEntry()
        self.city_entry.add_css_class("city-search")
        self.city_entry.set_placeholder_text("Search city")
        self.city_entry.set_hexpand(True)
        self.city_entry.connect("search-changed", self.queue_city_search)
        search_row.append(self.city_entry)
        cancel = Gtk.Button.new_from_icon_name("window-close-symbolic")
        cancel.add_css_class("city-control")
        cancel.set_cursor_from_name("pointer")
        cancel.set_tooltip_text("Cancel city search")
        cancel.connect("clicked", lambda *_: self.cancel_city_search())
        search_row.append(cancel)
        self.location_stack.add_named(search_row, "search")

        location_icon = Gtk.Label(label="󰍎")
        location_icon.add_css_class("location-icon")
        location_icon.set_valign(Gtk.Align.CENTER)
        location_row.append(location_icon)

        location = Gtk.Label(label="WEATHER")
        location.add_css_class("location")
        location.set_max_width_chars(28)
        location.set_ellipsize(3)
        location.set_halign(Gtk.Align.START)
        location_row.append(location)
        self.widgets["location"] = location

        condition = Gtk.Label(label="")
        condition.add_css_class("condition")
        condition.set_halign(Gtk.Align.START)
        right.append(condition)
        self.widgets["condition"] = condition

        metrics = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=36)
        right.append(metrics)
        for key, label in (("feels", "FEELS"), ("wind", "WIND"), ("humidity", "HUMID")):
            metrics.append(self.metric_box(key, label))

        self.city_results = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.city_results.set_visible(False)
        root.append(self.city_results)

        divider = Gtk.Box()
        divider.add_css_class("divider")
        root.append(divider)

        forecast = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=18)
        forecast.set_homogeneous(True)
        forecast.set_hexpand(True)
        root.append(forecast)
        for index in range(3):
            forecast.append(self.forecast_box(index))

    def metric_box(self, key: str, label: str) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        title = Gtk.Label(label=label)
        title.add_css_class("metric-label")
        title.set_halign(Gtk.Align.START)
        value = Gtk.Label(label="--")
        value.add_css_class("metric-value")
        value.set_halign(Gtk.Align.START)
        box.append(title)
        box.append(value)
        self.widgets[key] = value
        return box

    def forecast_box(self, index: int) -> Gtk.Widget:
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        row.set_halign(Gtk.Align.CENTER)
        icon = Gtk.Label(label="󰖐")
        icon.add_css_class("forecast-icon")
        icon.set_size_request(36, -1)
        icon.set_valign(Gtk.Align.CENTER)
        row.append(icon)
        self.widgets[f"forecast_icon_{index}"] = icon

        col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        col.set_valign(Gtk.Align.CENTER)
        row.append(col)

        day = Gtk.Label(label="")
        day.add_css_class("forecast-day")
        day.set_halign(Gtk.Align.START)
        col.append(day)
        self.widgets[f"forecast_day_{index}"] = day

        temp = Gtk.Label(label="")
        temp.add_css_class("forecast-temp")
        temp.set_halign(Gtk.Align.START)
        col.append(temp)
        self.widgets[f"forecast_temp_{index}"] = temp
        return row

    def start_city_search(self, *_args):
        self.location_stack.set_visible_child_name("search")
        self.city_entry.set_text("")
        self.city_entry.grab_focus()

    def clear_city_results(self):
        while child := self.city_results.get_first_child():
            self.city_results.remove(child)
        self.city_results.set_visible(False)

    def cancel_city_search(self):
        self.search_generation += 1
        if self.search_timer:
            GLib.source_remove(self.search_timer)
            self.search_timer = 0
        self.location_stack.set_visible_child_name("location")
        self.clear_city_results()

    def queue_city_search(self, *_args):
        self.search_generation += 1
        if self.search_timer:
            GLib.source_remove(self.search_timer)
            self.search_timer = 0
        self.clear_city_results()
        query = self.city_entry.get_text().strip()
        if len(query) >= 2:
            self.search_timer = GLib.timeout_add(300, self.search_cities, query, self.search_generation)

    def search_cities(self, query, generation):
        self.search_timer = 0
        def fetch():
            params = urllib.parse.urlencode({"name": query, "count": 5, "language": "en", "format": "json"})
            try:
                with urllib.request.urlopen("https://geocoding-api.open-meteo.com/v1/search?" + params, timeout=5) as response:
                    results = json.load(response).get("results", [])
                error = "No cities found"
            except Exception:
                results, error = [], "City search unavailable"
            GLib.idle_add(self.show_city_results, results, generation, error)
        threading.Thread(target=fetch, daemon=True).start()
        return False

    def show_city_results(self, results, generation, error):
        if generation != self.search_generation:
            return False
        self.clear_city_results()
        for city in results:
            if not all(key in city for key in ("name", "latitude", "longitude")):
                continue
            label = ", ".join(filter(None, [city["name"], city.get("admin1"), city.get("country")]))
            button = Gtk.Button(label=label)
            button.add_css_class("city-control")
            button.set_cursor_from_name("pointer")
            button.connect("clicked", self.pick_city, city)
            self.city_results.append(button)
        if not self.city_results.get_first_child():
            self.city_results.append(Gtk.Label(label=error))
        self.city_results.set_visible(True)
        return False

    def pick_city(self, _button, city):
        path = Path(self.session_directory.name) / "location.json"
        data = {key: city.get(key) for key in ("latitude", "longitude", "country_code")}
        data["name"] = ", ".join(filter(None, [city["name"], city.get("country")]))
        try:
            temporary = path.with_suffix(".tmp")
            temporary.write_text(json.dumps(data))
            temporary.replace(path)
        except OSError:
            self.clear_city_results()
            self.city_results.append(Gtk.Label(label="Could not save city"))
            self.city_results.set_visible(True)
            return
        self.cancel_city_search()
        self.session_location = path
        self.location_generation += 1
        self.widgets["location"].set_label(data["name"].upper())
        self.refresh()

    def refresh(self) -> bool:
        if not self.refresh_running:
            self.refresh_running = True
            environment = os.environ.copy()
            if self.session_location:
                environment["WEATHER_STATE_FILE"] = str(self.session_location)
                environment["WEATHER_CACHE_FILE"] = str(Path(self.session_directory.name) / "weather.json")
            threading.Thread(target=self.fetch_weather, args=(environment, self.location_generation), daemon=True).start()
        return True

    def fetch_weather(self, environment, generation):
        try:
            raw = subprocess.check_output([str(SCRIPT)], text=True, timeout=20, env=environment)
            data = json.loads(raw.splitlines()[-1])
        except Exception:
            data = {
                "text": "󰖐 --",
                "location": "Weather",
                "condition": "Unavailable",
                "temp": "--",
                "feels": "--",
                "wind": "--",
                "humidity": "--",
                "forecastDays": [],
            }

        GLib.idle_add(self.apply_weather, data, generation)

    def apply_weather(self, data, generation):
        self.refresh_running = False
        if generation != self.location_generation:
            self.refresh()
            return False
        icon = str(data.get("text", "󰖐")).split(" ")[0] or "󰖐"
        temp = str(data.get("temp", "--"))
        unit = ""
        number = temp
        if "°" in temp:
            number, unit_part = temp.split("°", 1)
            unit = "°" + unit_part

        self.widgets["icon"].set_label(icon)
        self.widgets["temp"].set_label(number)
        self.widgets["unit"].set_label(unit)
        alternate = ""
        try:
            value = float(number)
            if unit == "°F":
                alternate = f"{round((value - 32) * 5 / 9)}°C"
            elif unit == "°C":
                alternate = f"{round(value * 9 / 5 + 32)}°F"
        except ValueError:
            pass
        self.widgets["alternate"].set_label(alternate)
        self.widgets["alternate"].set_visible(bool(alternate))
        self.widgets["location"].set_label(str(data.get("location", "Weather")).upper())
        self.widgets["condition"].set_label(str(data.get("condition", "")))
        self.widgets["feels"].set_label(str(data.get("feels", "--")))
        self.widgets["wind"].set_label(str(data.get("wind", "--")))
        self.widgets["humidity"].set_label(str(data.get("humidity", "--")))

        days = data.get("forecastDays") or []
        for index in range(3):
            day = days[index] if index < len(days) else {}
            self.widgets[f"forecast_icon_{index}"].set_label(self.weather_icon(str(day.get("icon", ""))))
            self.widgets[f"forecast_day_{index}"].set_label(str(day.get("day", "")))
            high = str(day.get("high", "--"))
            low = str(day.get("low", "--"))
            self.widgets[f"forecast_temp_{index}"].set_label(f"{high}°  {low}°")

        return False

    def weather_icon(self, code: str) -> str:
        if code == "113":
            return "󰖙"
        if code == "116":
            return "󰖕"
        if code in {"119", "122"}:
            return "󰖐"
        if code in {"143", "248", "260"}:
            return "󰖑"
        if code in {"176", "263", "266", "293", "296", "353"}:
            return "󰖗"
        if code in {"179", "182", "185", "281", "284", "311", "314", "317", "320", "362", "365", "374", "377"}:
            return "󰖒"
        if code in {"200", "386", "389", "392", "395"}:
            return "󰙾"
        if code in {"227", "230", "323", "326", "329", "332", "335", "338", "350", "368", "371"}:
            return "󰖘"
        if code in {"299", "302", "305", "308", "356", "359"}:
            return "󰖖"
        return "󰖐"

    def on_key_pressed(self, _controller: Gtk.EventControllerKey, keyval: int, _keycode: int, _state: Gdk.ModifierType) -> bool:
        if keyval == Gdk.KEY_Escape:
            if self.location_stack.get_visible_child_name() == "search":
                self.cancel_city_search()
                return True
            self.window.close()
            return True
        return False


if __name__ == "__main__":
    raise SystemExit(WeatherPanel().run(sys.argv))
