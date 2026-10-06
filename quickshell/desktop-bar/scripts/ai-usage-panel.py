#!/usr/bin/env python3

import datetime as dt
import json
from pathlib import Path
import subprocess
import threading
import time

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk
from panel_position import keep_top_on_resize
from panel_theme import install_panel_css

APP_ID = "dev.local.AiUsagePanel"
CACHE = Path.home() / ".cache/desktop-ai-usage.json"


class UsagePanel(Adw.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.NON_UNIQUE)
        GLib.set_prgname(APP_ID)
        self.busy = False
        self.closed = False
        self.timer = None

    def do_activate(self):
        self.window = Adw.ApplicationWindow(application=self, title="AI usage")
        self.window.set_default_size(560, 520)
        self.window.set_resizable(False)
        install_panel_css("""
          window { background: rgba(24, 24, 36, 0.94); color: #cdd6f4; }
          .heading { font-size: 22px; font-weight: bold; }
          .provider { font-size: 17px; font-weight: bold; }
          .provider-icon { font-family: "JetBrainsMono Nerd Font"; font-size: 19px; }
          window button.refresh-button {
            min-width: 32px;
            min-height: 32px;
            border-radius: 7px;
            border: none;
            box-shadow: none;
            background-image: none;
            background: rgba(205, 214, 244, 0.08);
            color: #cdd6f4;
          }
          window button.refresh-button:hover { background: rgba(205, 214, 244, 0.16); }
          window button.refresh-button:disabled { opacity: 0.45; }
          window progressbar.usage-meter trough,
          window progressbar.usage-meter trough progress {
            min-height: 6px;
            min-width: 0;
            margin: 0;
            padding: 0;
            border-radius: 999px;
            border: none;
            box-shadow: none;
            background-image: none;
          }
          window progressbar.usage-meter trough { background: rgba(205, 214, 244, 0.12); }
          window progressbar.usage-meter trough progress { background: #cdd6f4; }
          .provider-divider { min-height: 1px; background: rgba(205, 214, 244, 0.08); }
          .muted { color: rgba(205, 214, 244, 0.72); font-size: 12px; }
        """)
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        for setter in (root.set_margin_start, root.set_margin_end, root.set_margin_top, root.set_margin_bottom):
            setter(24)
        header = Gtk.Box(spacing=12)
        title = Gtk.Label(label="AI usage", xalign=0, hexpand=True)
        title.add_css_class("heading")
        header.append(title)
        self.refresh_button = Gtk.Button(icon_name="view-refresh-symbolic", tooltip_text="Refresh usage")
        self.refresh_button.add_css_class("refresh-button")
        self.refresh_button.set_valign(Gtk.Align.CENTER)
        self.refresh_button.set_cursor_from_name("pointer")
        self.refresh_button.connect("clicked", lambda _: self.refresh())
        header.append(self.refresh_button)
        root.append(header)
        scroll = Gtk.ScrolledWindow(vexpand=True, hscrollbar_policy=Gtk.PolicyType.NEVER)
        self.content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        scroll.set_child(self.content)
        root.append(scroll)
        self.status = Gtk.Label(label="Checking usage...", xalign=0)
        self.status.add_css_class("muted")
        root.append(self.status)
        self.window.set_content(root)
        keys = Gtk.EventControllerKey()
        keys.connect("key-pressed", self.on_key)
        self.window.add_controller(keys)
        self.window.connect("close-request", self.on_close)
        try:
            data = json.loads(CACHE.read_text())
            self.render(data)
        except (OSError, ValueError, KeyError):
            pass
        self.window.present()
        keep_top_on_resize(self.window, APP_ID)
        self.refresh()
        self.timer = GLib.timeout_add_seconds(300, self.refresh)

    def on_key(self, _controller, key, _code, _state):
        if key == Gdk.KEY_Escape:
            self.window.close()
            return True
        return False

    def on_close(self, _window):
        self.closed = True
        if self.timer:
            GLib.source_remove(self.timer)
        return False

    def refresh(self):
        if self.busy or self.closed:
            return not self.closed
        self.busy = True
        self.refresh_button.set_sensitive(False)
        self.status.set_label("Updating...")

        def worker():
            try:
                result = subprocess.run(["python3", str(Path(__file__).with_name("ai-usage.py"))],
                                        capture_output=True, text=True, timeout=30, check=True)
                data = json.loads(result.stdout)
                CACHE.parent.mkdir(parents=True, exist_ok=True)
                temporary = CACHE.with_suffix(".tmp")
                temporary.write_text(json.dumps(data))
                temporary.replace(CACHE)
                GLib.idle_add(self.finished, data)
            except (OSError, ValueError, subprocess.SubprocessError):
                GLib.idle_add(self.finished, None)
        threading.Thread(target=worker, daemon=True).start()
        return True

    def finished(self, data):
        self.busy = False
        if not self.closed:
            self.refresh_button.set_sensitive(True)
            if data:
                self.render(data)
            else:
                self.status.set_label("Could not update usage. Try refreshing.")
        return False

    def render(self, data):
        while child := self.content.get_first_child():
            self.content.remove(child)
        for index, provider in enumerate(data["providers"]):
            if index:
                divider = Gtk.Box()
                divider.add_css_class("provider-divider")
                divider.set_margin_top(24)
                divider.set_margin_bottom(24)
                self.content.append(divider)
            section = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
            heading = Gtk.Box(spacing=10)
            icon = Gtk.Label(label={"Codex": "", "Claude": "󰚩"}.get(provider["name"], "󰚩"))
            icon.add_css_class("provider-icon")
            icon.set_valign(Gtk.Align.CENTER)
            icon.set_margin_bottom(4)
            heading.append(icon)
            name = Gtk.Label(label=provider["name"], xalign=0)
            name.add_css_class("provider")
            name.set_valign(Gtk.Align.CENTER)
            heading.append(name)
            section.append(heading)
            if provider.get("error"):
                error = Gtk.Label(label=provider["error"], xalign=0, wrap=True)
                error.add_css_class("muted")
                section.append(error)
            for window in provider["windows"]:
                used = max(0, min(100, float(window["used"])))
                labels = Gtk.Box()
                labels.append(Gtk.Label(label=window["label"], xalign=0, hexpand=True))
                labels.append(Gtk.Label(label=f"{100-used:.0f}% left", xalign=1))
                section.append(labels)
                bar = Gtk.ProgressBar(fraction=used / 100)
                bar.add_css_class("usage-meter")
                bar.set_tooltip_text(f"{used:g}% used")
                section.append(bar)
                if window.get("reset"):
                    reset = dt.datetime.fromtimestamp(window["reset"])
                    delta = max(0, int(window["reset"] - time.time()))
                    text = f"Resets {reset:%a %b %d, %H:%M} · {delta//3600}h {(delta%3600)//60}m"
                    label = Gtk.Label(label=text, xalign=0)
                    label.add_css_class("muted")
                    section.append(label)
            self.content.append(section)
        checked = dt.datetime.fromtimestamp(data["updated"])
        self.status.set_label(f"Last checked {checked:%H:%M}")


if __name__ == "__main__":
    UsagePanel().run(None)
