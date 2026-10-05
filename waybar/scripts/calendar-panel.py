#!/usr/bin/env python3

import calendar
import datetime as dt
import sys

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk


APP_ID = "dev.local.CalendarPanel"


class CalendarPanel(Adw.Application):
    def __init__(self) -> None:
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.NON_UNIQUE)
        GLib.set_prgname(APP_ID)
        GLib.set_application_name("Calendar Panel")
        self.today = dt.date.today()
        self.view_year = self.today.year
        self.view_month = self.today.month
        self.day_buttons: list[Gtk.Widget] = []

    def do_activate(self) -> None:
        self.window = Adw.ApplicationWindow(application=self)
        self.window.set_title("Calendar")
        self.window.set_default_size(560, 520)
        self.window.set_resizable(False)

        self.install_css()
        self.build_ui()
        self.refresh()

        key = Gtk.EventControllerKey()
        key.connect("key-pressed", self.on_key_pressed)
        self.window.add_controller(key)

        self.window.present()

    def pointer_cursor(self, widget: Gtk.Widget) -> Gtk.Widget:
        widget.set_cursor(Gdk.Cursor.new_from_name("pointer"))
        return widget

    def install_css(self) -> None:
        css = b"""
        window {
          background: rgba(24, 24, 36, 0.94);
          color: #cdd6f4;
        }

        .panel {
          padding: 22px;
        }

        .hero-icon {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 42px;
          color: #cdd6f4;
        }

        .hero-date {
          font-size: 34px;
          font-weight: 800;
          color: #ffffff;
        }

        .hero-meta {
          font-size: 12px;
          font-weight: 700;
          letter-spacing: 1.4px;
          color: rgba(205, 214, 244, 0.72);
        }

        .month-label {
          font-size: 18px;
          font-weight: 800;
          color: #ffffff;
        }

        .nav-button {
          min-width: 34px;
          min-height: 32px;
          border-radius: 7px;
          background: rgba(205, 214, 244, 0.08);
          color: #cdd6f4;
        }

        .nav-button:hover {
          background: rgba(205, 214, 244, 0.16);
        }

        .weekday,
        .week-number {
          min-width: 56px;
          min-height: 24px;
          font-size: 11px;
          font-weight: 800;
          letter-spacing: 1.1px;
          color: rgba(205, 214, 244, 0.52);
        }

        .week-number {
          min-width: 34px;
        }

        .day {
          min-width: 56px;
          min-height: 38px;
          border-radius: 7px;
          background: transparent;
          color: #cdd6f4;
          font-weight: 700;
        }

        .day.outside {
          color: rgba(205, 214, 244, 0.32);
        }

        .day.today {
          background: #cdd6f4;
          color: #11111b;
        }

        .progress-track {
          min-height: 6px;
          border-radius: 999px;
          background: rgba(205, 214, 244, 0.12);
        }

        .progress-fill {
          min-height: 6px;
          border-radius: 999px;
          background: #cdd6f4;
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
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        root.add_css_class("panel")
        self.window.set_content(root)

        hero = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=18)
        root.append(hero)

        icon = Gtk.Label(label="󰃭")
        icon.add_css_class("hero-icon")
        hero.append(icon)

        hero_text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        hero_text.set_hexpand(True)
        hero.append(hero_text)

        self.hero_date = Gtk.Label(xalign=0)
        self.hero_date.add_css_class("hero-date")
        hero_text.append(self.hero_date)

        self.hero_meta = Gtk.Label(xalign=0)
        self.hero_meta.add_css_class("hero-meta")
        hero_text.append(self.hero_meta)

        nav = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        root.append(nav)

        prev_button = Gtk.Button(label="‹")
        prev_button.add_css_class("nav-button")
        prev_button.connect("clicked", lambda *_: self.move_month(-1))
        self.pointer_cursor(prev_button)
        nav.append(prev_button)

        self.month_label = Gtk.Label()
        self.month_label.add_css_class("month-label")
        self.month_label.set_hexpand(True)
        nav.append(self.month_label)

        today_button = Gtk.Button(label="Today")
        today_button.add_css_class("nav-button")
        today_button.connect("clicked", lambda *_: self.go_today())
        self.pointer_cursor(today_button)
        nav.append(today_button)

        next_button = Gtk.Button(label="›")
        next_button.add_css_class("nav-button")
        next_button.connect("clicked", lambda *_: self.move_month(1))
        self.pointer_cursor(next_button)
        nav.append(next_button)

        self.grid = Gtk.Grid(column_spacing=6, row_spacing=8)
        root.append(self.grid)

        progress_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=7)
        root.append(progress_box)

        progress_header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        progress_box.append(progress_header)

        year_label = Gtk.Label(label="YEAR")
        year_label.add_css_class("hero-meta")
        progress_header.append(year_label)

        self.year_percent = Gtk.Label(xalign=1)
        self.year_percent.add_css_class("hero-meta")
        self.year_percent.set_hexpand(True)
        progress_header.append(self.year_percent)

        self.progress_track = Gtk.Box()
        self.progress_track.add_css_class("progress-track")
        progress_box.append(self.progress_track)

        self.progress_fill = Gtk.Box()
        self.progress_fill.add_css_class("progress-fill")
        self.progress_track.append(self.progress_fill)

    def refresh(self) -> None:
        self.today = dt.date.today()
        view_date = dt.date(self.view_year, self.view_month, 1)

        self.hero_date.set_label(self.today.strftime("%B %-d"))
        self.hero_meta.set_label(self.today.strftime("%A · Week %V · %Y").upper())
        self.month_label.set_label(view_date.strftime("%B %Y"))

        self.populate_grid()
        self.update_progress()

    def populate_grid(self) -> None:
        child = self.grid.get_first_child()
        while child:
            next_child = child.get_next_sibling()
            self.grid.remove(child)
            child = next_child

        cal = calendar.Calendar(firstweekday=calendar.MONDAY)
        weeks = cal.monthdatescalendar(self.view_year, self.view_month)

        week_header = Gtk.Label(label="W")
        week_header.add_css_class("week-number")
        self.grid.attach(week_header, 0, 0, 1, 1)

        for column, weekday_name in enumerate(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"], start=1):
            weekday = Gtk.Label(label=weekday_name)
            weekday.add_css_class("weekday")
            self.grid.attach(weekday, column, 0, 1, 1)

        for row, week in enumerate(weeks, start=1):
            week_number = Gtk.Label(label=f"{week[0].isocalendar().week:02d}")
            week_number.add_css_class("week-number")
            self.grid.attach(week_number, 0, row, 1, 1)

            for column, day in enumerate(week, start=1):
                label = Gtk.Label(label=str(day.day))
                label.add_css_class("day")
                if day.month != self.view_month:
                    label.add_css_class("outside")
                if day == self.today:
                    label.add_css_class("today")
                self.grid.attach(label, column, row, 1, 1)

    def update_progress(self) -> None:
        start = dt.date(self.today.year, 1, 1)
        end = dt.date(self.today.year + 1, 1, 1)
        progress = (self.today - start).days / max(1, (end - start).days)
        self.year_percent.set_label(f"{round(progress * 100)}%")

        width = max(1, int(516 * progress))
        self.progress_fill.set_size_request(width, 6)

    def move_month(self, delta: int) -> None:
        month = self.view_month + delta
        year = self.view_year
        while month < 1:
            month += 12
            year -= 1
        while month > 12:
            month -= 12
            year += 1
        self.view_year = year
        self.view_month = month
        self.refresh()

    def go_today(self) -> None:
        self.today = dt.date.today()
        self.view_year = self.today.year
        self.view_month = self.today.month
        self.refresh()

    def on_key_pressed(self, _controller, keyval, _keycode, state) -> bool:
        if keyval == Gdk.KEY_Escape:
            self.window.close()
            return True
        if keyval in (Gdk.KEY_Left, Gdk.KEY_bracketleft):
            self.move_month(-1)
            return True
        if keyval in (Gdk.KEY_Right, Gdk.KEY_bracketright):
            self.move_month(1)
            return True
        if keyval == Gdk.KEY_t:
            self.go_today()
            return True
        if keyval == Gdk.KEY_Up:
            self.move_month(-12)
            return True
        if keyval == Gdk.KEY_Down:
            self.move_month(12)
            return True
        return False


if __name__ == "__main__":
    raise SystemExit(CalendarPanel().run(sys.argv))
