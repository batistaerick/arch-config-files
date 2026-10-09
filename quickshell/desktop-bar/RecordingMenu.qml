import QtQuick
import "PanelStyle.js" as PanelStyle

ThemedPopup {
    id: menu
    required property var controller
    implicitWidth: 76 + PanelStyle.padding * 2 + 28
    implicitHeight: 34 + PanelStyle.padding * 2 + 28
    Connections {
        target: menu.controller
        function onObsStateChanged() {
            if (!menu.controller.obsState.recording && !menu.controller.busy)
                menu.opened = false;
        }
        function onBusyChanged() {
            if (!menu.controller.obsState.recording && !menu.controller.busy)
                menu.opened = false;
        }
    }
    Row {
        x: PanelStyle.padding
        y: PanelStyle.padding
        spacing: 8
        ObsActionButton {
            controller: menu.controller
            action: controller.obsState.paused ? "resume" : "pause"
            description: controller.obsState.paused ? "Resume recording" : "Pause recording"
            glyph: controller.obsState.paused ? "󰐊" : "󰏤"
        }
        ObsActionButton {
            controller: menu.controller
            action: "stop"
            description: "Stop recording"
            glyph: "󰓛"
        }
    }
}
