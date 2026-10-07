import QtQuick
import QtQuick.Controls.Basic as Controls
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 400
    implicitHeight: 152
    keyTarget: content
    property var state: ({available: false, name: "Checking brightness", value: 0})
    property int requested: -1
    property int applied: -1
    readonly property string helper: Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/brightness.py"

    function refresh() {
        if (!query.running && !operation.running && !slider.pressed && !settle.running) query.running = true;
    }
    function applyValue(value) {
        requested = value;
        if (!operation.running) startSet();
    }
    function startSet() {
        if (requested < 0) return;
        applied = requested;
        operation.command = ["python3", helper, "set", String(applied), String(state.maximum || 100)];
        operation.running = true;
    }
    onVisibleChanged: if (visible) refresh()
    Timer { interval: 3000; repeat: true; running: menu.visible; onTriggered: menu.refresh() }
    Timer { id: settle; interval: 80; onTriggered: menu.applyValue(Math.round(slider.value)) }
    Process {
        id: query
        command: ["python3", menu.helper, "status"]
        stdout: StdioCollector { id: queryOutput }
        onExited: {
            try { menu.state = JSON.parse(queryOutput.text); }
            catch (e) { menu.state = {available: false, name: "Brightness unavailable", value: 0}; }
        }
    }
    Process {
        id: operation
        stdout: StdioCollector { id: operationOutput }
        onExited: {
            try { menu.state = JSON.parse(operationOutput.text); }
            catch (e) { menu.state = {available: false, name: "Brightness unavailable", value: 0}; }
            if (menu.state.available) {
                brightnessOsd.command = ["swayosd-client", "--custom-icon", "display-brightness-symbolic", "--custom-progress", String(menu.state.value / 100)];
                if (!brightnessOsd.running) brightnessOsd.running = true;
            }
            if (menu.requested !== menu.applied) menu.startSet();
        }
    }
    Process { id: brightnessOsd; command: ["swayosd-client", "--custom-icon", "display-brightness-symbolic", "--custom-progress", "0"] }
    Item {
        id: content
        anchors.fill: parent
        anchors.margins: PanelStyle.padding
        focus: true
        Keys.onEscapePressed: menu.visible = false
        Column {
            width: parent.width
            spacing: 12
            Text { text: "Brightness"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.headingSize; font.bold: true }
            Text { width: parent.width; text: menu.state.name || "Display brightness"; elide: Text.ElideRight; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
            Row {
                width: parent.width
                spacing: 10
                Text { width: 30; height: 30; text: "󰃟"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: 18 }
                Controls.Slider {
                    id: slider
                    width: parent.width - 100
                    height: 30
                    from: 1
                    to: 100
                    stepSize: 1
                    enabled: menu.state.available
                    Binding { target: slider; property: "value"; value: menu.state.value || 1; when: !slider.pressed && !operation.running && !settle.running }
                    onMoved: {
                        if (menu.state.kind === "backlight") menu.applyValue(Math.round(value));
                        else settle.restart();
                    }
                    background: Rectangle {
                        x: slider.leftPadding
                        y: (slider.height - height) / 2
                        width: slider.availableWidth
                        height: 5
                        radius: 3
                        color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.16)
                        Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 3; color: menu.accent }
                    }
                    handle: Rectangle {
                        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                        y: (slider.height - height) / 2
                        width: 12
                        height: 12
                        radius: 6
                        color: menu.foreground
                    }
                }
                Text { width: 50; height: 30; text: Math.round(slider.value) + "%"; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
            }
        }
    }
}
