#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk


APP_ID = "dev.local.WeatherPanel"
SCRIPT = Path(__file__).with_name("weather-status.sh")


class WeatherPanel(Adw.Application):
    def __init__(self) -> None:
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.NON_UNIQUE)
        GLib.set_prgname(APP_ID)
        GLib.set_application_name("Weather")
        self.widgets: dict[str, Gtk.Label] = {}

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
        self.window.present()

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

        .location {
          font-size: 12px;
          font-weight: 800;
          letter-spacing: 1.1px;
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
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    def build_ui(self) -> None:
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        root.add_css_class("panel")
        self.window.set_content(root)

        hero = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        hero.set_size_request(-1, 116)
        root.append(hero)

        icon = Gtk.Label(label="󰖐")
        icon.add_css_class("hero-icon")
        icon.set_valign(Gtk.Align.CENTER)
        hero.append(icon)
        self.widgets["icon"] = icon

        temp_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=2)
        temp_row.set_valign(Gtk.Align.CENTER)
        hero.append(temp_row)

        temp = Gtk.Label(label="--")
        temp.add_css_class("hero-temp")
        temp_row.append(temp)
        self.widgets["temp"] = temp

        unit = Gtk.Label(label="")
        unit.add_css_class("hero-unit")
        unit.set_valign(Gtk.Align.START)
        unit.set_margin_top(10)
        temp_row.append(unit)
        self.widgets["unit"] = unit

        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        right.set_hexpand(True)
        right.set_halign(Gtk.Align.END)
        right.set_valign(Gtk.Align.CENTER)
        hero.append(right)

        location = Gtk.Label(label="WEATHER")
        location.add_css_class("location")
        location.set_max_width_chars(28)
        location.set_ellipsize(3)
        location.set_halign(Gtk.Align.START)
        right.append(location)
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

        divider = Gtk.Box()
        divider.add_css_class("divider")
        root.append(divider)

        forecast = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=44)
        forecast.set_halign(Gtk.Align.CENTER)
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
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        icon = Gtk.Label(label="󰖐")
        icon.add_css_class("forecast-icon")
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

    def refresh(self) -> bool:
        try:
            raw = subprocess.check_output([str(SCRIPT)], text=True, timeout=8)
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

        return True

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
            self.window.close()
            return True
        return False


if __name__ == "__main__":
    raise SystemExit(WeatherPanel().run(sys.argv))
