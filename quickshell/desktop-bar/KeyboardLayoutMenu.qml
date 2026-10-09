import QtQuick
import "PanelStyle.js" as PanelStyle
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    property var layouts: []
    property var availableLayouts: []
    property int activeLayout: -1
    property bool adding: false
    property string error: ""
    readonly property string helper: Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/keyboard-layout.py"
    readonly property var filteredLayouts: availableLayouts.filter(entry =>
        (entry.label + " " + entry.layout + " " + entry.variant).toLowerCase().includes(search.text.toLowerCase()))
    implicitWidth: 388
    implicitHeight: adding ? 468 : Math.max(1, layouts.length) * 35 + 104 + (error ? 34 : 0)
    keyTarget: adding ? search : body

    function refresh() { if (!query.running && !operation.running) query.running = true; }
    function perform(command) {
        if (operation.running) return;
        error = "";
        operation.command = ["python3", helper].concat(command);
        operation.running = true;
    }
    onOpenedChanged: {
        if (opened) { error = ""; adding = false; search.text = ""; refresh(); }
    }
    onAddingChanged: {
        error = "";
        if (adding) {
            if (!catalog.running && !availableLayouts.length) catalog.running = true;
            Qt.callLater(function() { search.forceActiveFocus(); });
        }
    }
    Timer { interval: 1000; running: menu.opened && !menu.adding; repeat: true; onTriggered: menu.refresh() }
    Process {
        id: query
        command: ["python3", menu.helper]
        stdout: StdioCollector { id: output }
        onExited: function(code) {
            try {
                var result = JSON.parse(output.text);
                if (code !== 0) throw new Error(result.error || "Layouts unavailable");
                menu.layouts = result.layouts;
                menu.activeLayout = result.active;
            } catch (e) { menu.error = e.message; }
        }
    }
    Process {
        id: catalog
        command: ["python3", menu.helper, "catalog"]
        stdout: StdioCollector { id: catalogOutput }
        onExited: function(code) {
            try {
                var result = JSON.parse(catalogOutput.text);
                if (code !== 0) throw new Error(result.error || "Layouts unavailable");
                menu.availableLayouts = result.layouts;
            } catch (e) { menu.error = e.message; }
        }
    }
    Process {
        id: operation
        stdout: StdioCollector { id: operationOutput }
        onExited: function(code) {
            if (code === 0) {
                if (menu.adding) { menu.adding = false; menu.refresh(); }
                else menu.opened = false;
            } else {
                try { menu.error = JSON.parse(operationOutput.text).error || "Could not change layout"; }
                catch (e) { menu.error = "Could not change layout"; }
            }
        }
    }
    Item {
        id: body
        anchors.fill: parent
        anchors.margins: 12
        TextField {
            id: search
            visible: menu.adding
            width: parent.width
            height: 36
            placeholderText: "Search layouts..."
            color: menu.foreground
            placeholderTextColor: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.5)
            font.family: PanelStyle.fontFamily
            font.pixelSize: PanelStyle.bodySize
            background: Rectangle {
                radius: 4
                color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08)
                border.color: search.activeFocus ? menu.accent : "transparent"
            }
            HoverHandler { cursorShape: Qt.IBeamCursor }
            onTextChanged: choices.currentIndex = 0
            Keys.onDownPressed: choices.incrementCurrentIndex()
            Keys.onUpPressed: choices.decrementCurrentIndex()
            onAccepted: if (menu.filteredLayouts.length) {
                var entry = menu.filteredLayouts[Math.max(0, choices.currentIndex)];
                menu.perform(["add", entry.layout, entry.variant]);
            }
        }
        ListView {
            id: choices
            anchors.top: menu.adding ? search.bottom : parent.top
            anchors.topMargin: menu.adding ? 10 : 0
            anchors.bottom: errorLabel.top
            anchors.bottomMargin: 8
            width: parent.width
            clip: true
            model: menu.adding ? menu.filteredLayouts : menu.layouts
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: entryRow
                required property var modelData
                required property int index
                width: choices.width
                height: 33
                radius: 4
                color: mouse.containsMouse || (menu.adding && choices.currentIndex === index)
                    ? Qt.rgba(menu.accent.r, menu.accent.g, menu.accent.b, 0.18) : "transparent"
                Text {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: !menu.adding && entryRow.modelData.index === menu.activeLayout ? "" : ""
                    color: menu.accent
                    font.family: PanelStyle.fontFamily
                    font.pixelSize: PanelStyle.controlSize
                }
                Text {
                    x: menu.adding ? 8 : 30
                    width: parent.width - x - 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: entryRow.modelData.label
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: menu.foreground
                    font.family: PanelStyle.fontFamily
                    font.pixelSize: PanelStyle.controlSize
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !operation.running
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        var entry = entryRow.modelData;
                        menu.perform(menu.adding ? ["add", entry.layout, entry.variant] : ["select", String(entry.index)]);
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: choices.count === 0
                text: menu.adding ? (catalog.running ? "Loading..." : "No layouts found") : "Loading..."
                color: menu.foreground
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.bodySize
            }
        }
        Text {
            id: errorLabel
            anchors.bottom: footer.top
            anchors.bottomMargin: 8
            width: parent.width
            height: menu.error ? implicitHeight : 0
            text: menu.error
            wrapMode: Text.Wrap
            color: menu.foreground
            font.family: PanelStyle.fontFamily
            font.pixelSize: PanelStyle.secondarySize
        }
        PanelButton {
            id: footer
            anchors.bottom: parent.bottom
            width: parent.width
            height: 32
            text: menu.adding ? "Back" : "Add Layout"
            foreground: menu.foreground
            available: !operation.running
            onClicked: { if (available) menu.adding = !menu.adding; }
        }
    }
}
