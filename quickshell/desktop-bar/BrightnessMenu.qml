import QtQuick
import QtQuick.Controls.Basic as Controls
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 400
    implicitHeight: 248 + (editingSchedule ? 70 : 0) + (nightlightError ? 24 : 0)
    keyTarget: content
    property var state: ({available: false, name: "Checking brightness", value: 0})
    property int requested: -1
    property int applied: -1
    property var nightlight: ({mode: "auto", enabled: false, available: false})
    property string nightlightError: ""
    property bool scheduleDirty: false
    property bool editingSchedule: false
    readonly property var timeLocale: Qt.locale()
    readonly property string helper: Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/brightness.py"
    readonly property string nightlightHelper: Quickshell.env("HOME") + "/.config/walker/scripts/actions/toggle/nightlight.py"

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
    function refreshNightlight() {
        if (!nightQuery.running && !nightOperation.running) nightQuery.running = true;
    }
    function setNightlight(mode) {
        if (nightOperation.running) return;
        nightlightError = "";
        nightOperation.command = ["python3", nightlightHelper, "set", mode];
        nightOperation.running = true;
    }
    function displayTime(value) {
        if (!value) return "";
        let parts = value.split(":");
        return new Date(2000, 0, 1, Number(parts[0]), Number(parts[1])).toLocaleTimeString(timeLocale, Locale.ShortFormat);
    }
    function parseTime(value) {
        let date = Date.fromLocaleTimeString(timeLocale, value.trim(), Locale.ShortFormat);
        if (!date || isNaN(date.getTime())) return "";
        return String(date.getHours()).padStart(2, "0") + ":" + String(date.getMinutes()).padStart(2, "0");
    }
    function syncSchedule() {
        if (scheduleDirty) return;
        startField.text = displayTime(nightlight.start || "18:00");
        endField.text = displayTime(nightlight.end || "09:00");
    }
    function saveSchedule() {
        let start = parseTime(startField.text);
        let end = parseTime(endField.text);
        if (!start || !end || start === end || nightOperation.running) return;
        nightlightError = "";
        nightOperation.command = ["python3", nightlightHelper, "schedule", start, end];
        nightOperation.running = true;
    }
    onVisibleChanged: {
        if (visible) { refresh(); refreshNightlight(); }
        else { editingSchedule = false; scheduleDirty = false; }
    }
    Timer { interval: 3000; repeat: true; running: menu.visible; onTriggered: { menu.refresh(); menu.refreshNightlight(); } }
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
    Process {
        id: nightQuery
        command: ["python3", menu.nightlightHelper, "status"]
        stdout: StdioCollector { id: nightQueryOutput }
        onExited: {
            try { menu.nightlight = JSON.parse(nightQueryOutput.text); menu.syncSchedule(); }
            catch (e) { menu.nightlightError = "Nightlight status unavailable"; }
        }
    }
    Process {
        id: nightOperation
        stdout: StdioCollector { id: nightOperationOutput }
        onExited: function(code) {
            if (code !== 0) menu.nightlightError = "Could not update nightlight";
            else {
                try {
                    menu.nightlight = JSON.parse(nightOperationOutput.text);
                    if (nightOperation.command[2] === "schedule") menu.editingSchedule = false;
                    menu.scheduleDirty = false;
                    menu.syncSchedule();
                }
                catch (e) { menu.nightlightError = "Nightlight status unavailable"; }
            }
            menu.refreshNightlight();
        }
    }
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
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12) }
            Row {
                width: parent.width
                height: 40
                Text { width: parent.width - 52; height: parent.height; verticalAlignment: Text.AlignVCenter; text: "Nightlight"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
                PanelSwitch {
                    checked: menu.nightlight.enabled
                    enabled: menu.nightlight.available && !nightOperation.running
                    foreground: menu.foreground
                    accent: menu.accent
                    onClicked: menu.setNightlight(checked ? "on" : "off")
                }
            }
            Row {
                width: parent.width
                height: 40
                Column {
                    width: parent.width - 94
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Automatic"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
                    Text { width: parent.width; elide: Text.ElideRight; text: menu.displayTime(menu.nightlight.start || "18:00") + " - " + menu.displayTime(menu.nightlight.end || "09:00"); color: menu.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                }
                PanelButton {
                    id: editButton
                    icon: true
                    width: 28
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰏫"
                    foreground: menu.foreground
                    available: menu.nightlight.available
                    selected: menu.editingSchedule
                    onClicked: { menu.scheduleDirty = false; menu.syncSchedule(); menu.editingSchedule = !menu.editingSchedule; }
                    HoverHandler { id: editHover }
                    BarTooltip { target: editButton; hovered: editHover.hovered; text: "Edit schedule"; background: menu.background; foreground: menu.foreground }
                }
                Item { width: 8; height: 1 }
                PanelSwitch {
                    checked: menu.nightlight.mode === "auto"
                    enabled: menu.nightlight.available && !nightOperation.running
                    foreground: menu.foreground
                    accent: menu.accent
                    onClicked: menu.setNightlight(checked ? "auto" : (menu.nightlight.enabled ? "on" : "off"))
                }
            }
            Column {
                visible: menu.editingSchedule
                width: parent.width
                height: visible ? 58 : 0
                spacing: 2
                Row {
                    width: parent.width
                    height: 16
                    spacing: 8
                    Text { width: (parent.width - 126) / 2; height: parent.height; text: "Start"; color: menu.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                    Text { width: (parent.width - 126) / 2; height: parent.height; text: "End"; color: menu.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                }
                Row {
                    width: parent.width
                    height: 40
                    spacing: 8
                    Controls.TextField {
                        id: startField
                        width: (parent.width - 126) / 2
                        height: parent.height
                        color: menu.foreground
                        font.family: PanelStyle.fontFamily
                        font.pixelSize: PanelStyle.bodySize
                        selectByMouse: true
                        onTextEdited: menu.scheduleDirty = true
                        HoverHandler { cursorShape: Qt.IBeamCursor }
                        background: Rectangle { radius: PanelStyle.controlRadius; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08); border.width: 1; border.color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.2) }
                    }
                    Controls.TextField {
                        id: endField
                        width: (parent.width - 126) / 2
                        height: parent.height
                        color: menu.foreground
                        font.family: PanelStyle.fontFamily
                        font.pixelSize: PanelStyle.bodySize
                        selectByMouse: true
                        onTextEdited: menu.scheduleDirty = true
                        HoverHandler { cursorShape: Qt.IBeamCursor }
                        background: Rectangle { radius: PanelStyle.controlRadius; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08); border.width: 1; border.color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.2) }
                    }
                    PanelButton {
                        text: "Save"
                        foreground: menu.foreground
                        available: menu.nightlight.available && menu.scheduleDirty && menu.parseTime(startField.text) !== "" && menu.parseTime(endField.text) !== "" && menu.parseTime(startField.text) !== menu.parseTime(endField.text) && !nightOperation.running
                        onClicked: menu.saveSchedule()
                    }
                    PanelButton {
                        id: cancelButton
                        icon: true
                        text: "󰅖"
                        foreground: menu.foreground
                        onClicked: { menu.editingSchedule = false; menu.scheduleDirty = false; menu.syncSchedule(); }
                        HoverHandler { id: cancelHover }
                        BarTooltip { target: cancelButton; hovered: cancelHover.hovered; text: "Cancel"; background: menu.background; foreground: menu.foreground }
                    }
                }
            }
            Text {
                visible: menu.nightlightError !== ""
                text: menu.nightlightError
                color: menu.foreground
                opacity: 0.7
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.captionSize
            }
        }
    }
}
