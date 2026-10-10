import QtQuick
import QtQuick.Controls.Basic as Controls
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 428
    implicitHeight: contentColumn.implicitHeight + PanelStyle.padding * 2 + PanelStyle.surfaceInset * 2
    keyTarget: content
    property var state: ({available: false, name: "Checking brightness", value: 0})
    property int requested: -1
    property int applied: -1
    property var nightlight: ({mode: "auto", enabled: false, available: false})
    property var monitors: []
    property string primaryDisplay: ""
    property string displayError: ""
    signal primarySelected(string name)
    property string nightlightError: ""
    // Status-read failures clear on the next successful read; action and
    // validation errors stay until the user acts again.
    readonly property string displayStatusError: "Display status unavailable"
    readonly property string nightlightStatusError: "Nightlight status unavailable"
    property bool scheduleDirty: false
    property bool editingSchedule: false
    readonly property var timeLocale: Qt.locale()
    readonly property string helper: Quickshell.shellDir + "/scripts/brightness.py"
    readonly property string nightlightHelper: Quickshell.env("HOME") + "/.config/walker/scripts/actions/toggle/nightlight.py"
    readonly property string displayHelper: Quickshell.shellDir + "/scripts/display-primary.py"

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
    function refreshDisplays() {
        if (!displayQuery.running && !setPrimary.running) displayQuery.running = true;
    }
    function selectPrimary(name) {
        if (setPrimary.running || name === primaryDisplay) return;
        displayError = "";
        setPrimary.command = ["python3", displayHelper, "set", name];
        setPrimary.running = true;
    }
    function setNightlight(mode) {
        if (nightOperation.running) return;
        if (scheduleDirty) { configureNightlight(mode); return; }
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
    function configureNightlight(mode) {
        let start = parseTime(startField.text);
        let end = parseTime(endField.text);
        if (!start || !end || start === end) {
            nightlightError = "Enter two different valid times";
            return;
        }
        if (nightOperation.running) return;
        nightlightError = "";
        nightOperation.command = ["python3", nightlightHelper, "configure", start, end, mode];
        nightOperation.running = true;
    }
    onOpenedChanged: {
        if (opened) { refresh(); refreshNightlight(); refreshDisplays(); }
        else {
            editingSchedule = false;
            if (scheduleDirty) scheduleSettle.restart();
        }
    }
    Timer { interval: 3000; repeat: true; running: menu.opened; onTriggered: { menu.refresh(); menu.refreshNightlight(); } }
    Timer { interval: 6000; repeat: true; running: menu.opened; onTriggered: menu.refreshDisplays() }
    Timer { id: scheduleSettle; interval: 650; onTriggered: if (menu.scheduleDirty && !nightOperation.running) menu.configureNightlight(menu.nightlight.mode) }
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
        id: displayQuery
        command: ["python3", menu.displayHelper, "status"]
        stdout: StdioCollector { id: displayOutput }
        onExited: {
            try {
                let result = JSON.parse(displayOutput.text);
                menu.monitors = result.monitors || [];
                menu.primaryDisplay = result.primary || "";
                if (menu.displayError === menu.displayStatusError) menu.displayError = "";
            } catch (e) { menu.displayError = menu.displayStatusError; }
        }
    }
    Process {
        id: setPrimary
        stdout: StdioCollector { id: setPrimaryOutput }
        onExited: function(code) {
            if (code !== 0) {
                menu.displayError = "Could not set primary display";
                menu.refreshDisplays();
                return;
            }
            try {
                let result = JSON.parse(setPrimaryOutput.text);
                menu.monitors = result.monitors || [];
                menu.primaryDisplay = result.primary || "";
                menu.primarySelected(menu.primaryDisplay);
            } catch (e) { menu.displayError = menu.displayStatusError; }
        }
    }
    Process {
        id: nightQuery
        command: ["python3", menu.nightlightHelper, "status"]
        stdout: StdioCollector { id: nightQueryOutput }
        onExited: {
            try {
                menu.nightlight = JSON.parse(nightQueryOutput.text);
                menu.syncSchedule();
                if (menu.nightlightError === menu.nightlightStatusError) menu.nightlightError = "";
            }
            catch (e) { menu.nightlightError = menu.nightlightStatusError; }
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
                    let command = nightOperation.command;
                    let changedDuringRequest = command[2] === "configure" &&
                        (menu.parseTime(startField.text) !== command[3] || menu.parseTime(endField.text) !== command[4]);
                    if (changedDuringRequest) scheduleSettle.restart();
                    else { menu.scheduleDirty = false; menu.syncSchedule(); }
                }
                catch (e) { menu.nightlightError = menu.nightlightStatusError; }
            }
            menu.refreshNightlight();
        }
    }
    Item {
        id: content
        anchors.fill: parent
        anchors.margins: PanelStyle.padding
        focus: true
        Keys.onEscapePressed: menu.opened = false
        Column {
            id: contentColumn
            width: parent.width
            spacing: 12
            Row {
                spacing: 8
                Text { text: "󰍹"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.headingSize }
                Text { text: "Display"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.headingSize; font.bold: true }
            }
            Text { width: parent.width; text: menu.state.available ? "Brightness" : (menu.state.name || "Brightness unavailable"); elide: Text.ElideRight; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
            Row {
                width: parent.width
                spacing: 10
                Text { width: 30; height: 30; text: "󰃟"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: 18 }
                PanelSlider {
                    id: slider
                    accent: menu.accent
                    foreground: menu.foreground
                    width: parent.width - 100
                    from: 1
                    to: 100
                    stepSize: 1
                    enabled: menu.state.available
                    Binding { target: slider; property: "value"; value: menu.state.value || 1; when: !slider.pressed && !operation.running && !settle.running }
                    onMoved: {
                        if (menu.state.kind === "backlight") menu.applyValue(Math.round(value));
                        else settle.restart();
                    }
                }
                Text { width: 50; height: 30; text: Math.round(slider.value) + "%"; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
            }
            Rectangle { width: parent.width; height: 1; color: Qt.alpha(menu.foreground, PanelStyle.dividerAlpha) }
            Row {
                width: parent.width
                height: 40
                Column {
                    width: parent.width - 88
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Nightlight"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
                    Text { width: parent.width; elide: Text.ElideRight; text: menu.nightlight.mode === "auto" ? "Automatic · " + menu.displayTime(menu.nightlight.start || "18:00") + " - " + menu.displayTime(menu.nightlight.end || "09:00") : "Manual"; color: menu.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
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
                    onClicked: {
                        if (menu.editingSchedule && menu.scheduleDirty) scheduleSettle.restart();
                        if (!menu.editingSchedule) menu.syncSchedule();
                        menu.editingSchedule = !menu.editingSchedule;
                    }
                    HoverHandler { id: editHover }
                    BarTooltip { target: editButton; hovered: editHover.hovered; text: "Edit schedule"; background: menu.background; foreground: menu.foreground }
                }
                Item { width: 8; height: 1 }
                PanelSwitch {
                    checked: menu.nightlight.enabled
                    enabled: menu.nightlight.available && !nightOperation.running
                    foreground: menu.foreground
                    accent: menu.accent
                    onClicked: menu.setNightlight(checked ? "on" : "off")
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
                    Text { width: (parent.width - 68) / 2; height: parent.height; text: "Start"; color: menu.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                    Text { width: (parent.width - 68) / 2; height: parent.height; text: "End"; color: menu.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                    Text { width: 52; height: parent.height; text: "Auto"; color: menu.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                }
                Row {
                    width: parent.width
                    height: 40
                    spacing: 8
                    Controls.TextField {
                        id: startField
                        width: (parent.width - 68) / 2
                        height: parent.height
                        color: menu.foreground
                        font.family: PanelStyle.fontFamily
                        font.pixelSize: PanelStyle.bodySize
                        selectByMouse: true
                        onTextEdited: { menu.scheduleDirty = true; scheduleSettle.restart(); }
                        HoverHandler { cursorShape: Qt.IBeamCursor }
                        background: Rectangle { radius: PanelStyle.controlRadius; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08); border.width: 1; border.color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.2) }
                    }
                    Controls.TextField {
                        id: endField
                        width: (parent.width - 68) / 2
                        height: parent.height
                        color: menu.foreground
                        font.family: PanelStyle.fontFamily
                        font.pixelSize: PanelStyle.bodySize
                        selectByMouse: true
                        onTextEdited: { menu.scheduleDirty = true; scheduleSettle.restart(); }
                        HoverHandler { cursorShape: Qt.IBeamCursor }
                        background: Rectangle { radius: PanelStyle.controlRadius; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08); border.width: 1; border.color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.2) }
                    }
                    PanelSwitch {
                        checked: menu.nightlight.mode === "auto"
                        enabled: menu.nightlight.available && !nightOperation.running
                        foreground: menu.foreground
                        accent: menu.accent
                        onClicked: {
                            scheduleSettle.stop();
                            menu.configureNightlight(checked ? "auto" : (menu.nightlight.enabled ? "on" : "off"));
                        }
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
            Rectangle { width: parent.width; height: 1; color: Qt.alpha(menu.foreground, PanelStyle.dividerAlpha) }
            Text { text: "Displays"; color: menu.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
            Text { visible: menu.displayError !== ""; text: menu.displayError; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
            Text {
                visible: menu.monitors.length === 0
                height: visible ? 36 : 0
                text: "No active displays"
                color: menu.foreground
                opacity: 0.65
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.bodySize
            }
            Repeater {
                model: menu.monitors
                Rectangle {
                    required property var modelData
                    width: content.width
                    height: 36
                    radius: PanelStyle.controlRadius
                    color: modelData.name === menu.primaryDisplay ? Qt.rgba(menu.accent.r, menu.accent.g, menu.accent.b, 0.16) : (displayHover.hovered ? Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08) : "transparent")
                    border.width: modelData.name === menu.primaryDisplay ? 1 : 0
                    border.color: Qt.rgba(menu.accent.r, menu.accent.g, menu.accent.b, 0.35)
                    HoverHandler { id: displayHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: menu.selectPrimary(modelData.name) }
                    BarTooltip { target: parent; hovered: displayHover.hovered; text: modelData.name === menu.primaryDisplay ? "Primary display" : "Make primary"; background: menu.background; foreground: menu.foreground }
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        Text { width: 22; height: parent.height; text: "󰍹"; verticalAlignment: Text.AlignVCenter; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: 16 }
                        Text { width: parent.width - 224; height: parent.height; text: modelData.name + (modelData.model ? " · " + modelData.model : ""); elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
                        Text { width: 146; height: parent.height; text: modelData.width + "×" + modelData.height + " · " + Math.round(modelData.refreshRate) + " Hz"; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                        Text { width: 16; height: parent.height; text: modelData.name === menu.primaryDisplay ? "󰄬" : ""; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; color: menu.accent; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
                    }
                }
            }
        }
    }
}
