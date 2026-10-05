import json
import subprocess
import threading


def keep_top_on_resize(window, app_id):
    """Preserve the mapped top edge when GTK changes the panel's height."""
    state = {"height": 0, "top": None, "busy": False}

    def reposition():
        try:
            result = subprocess.run(
                ["hyprctl", "clients", "-j"], capture_output=True,
                text=True, check=True, timeout=2,
            )
            client = next((item for item in json.loads(result.stdout)
                           if item.get("class") == app_id), None)
            if client is None:
                state["height"] = 0
                return
            if state["top"] is None:
                state["top"] = client["at"][1]
            elif client["at"][1] != state["top"]:
                subprocess.run(
                    ["hyprctl", "eval",
                     "return hl.dispatch(hl.dsp.window.move({"
                     f'x = {client["at"][0]}, y = {state["top"]}, '
                     f'window = "address:{client["address"]}", relative = false'
                     "}))"],
                    capture_output=True, check=True, timeout=2,
                )
        except (OSError, subprocess.SubprocessError, ValueError, KeyError):
            state["height"] = 0
        finally:
            state["busy"] = False

    def on_frame(widget, _clock):
        height = widget.get_height()
        if height > 0 and height != state["height"] and not state["busy"]:
            state["height"] = height
            state["busy"] = True
            threading.Thread(target=reposition, daemon=True).start()
        return True

    window.add_tick_callback(on_frame)
