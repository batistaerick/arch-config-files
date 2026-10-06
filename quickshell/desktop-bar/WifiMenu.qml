import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 440
    implicitHeight: 480
    property var devices: []
    property var selectedNetwork: null
    property string message: ""
    property string secret: ""
    property bool busy: operation ? operation.running : false
    property string helper: Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/wifi-popup.py"
    function refresh() { if (!query.running) query.running = true; }
    function act(kind, path, extra) {
        if (operation.running) return;
        message = "";
        operation.command = ["python3", helper, kind, path];
        if (extra !== undefined) operation.command = operation.command.concat([extra]);
        operation.running = true;
    }
    function choose(network) {
        if (network.connected) return;
        if (network.type === "open" || network.known) { secret = ""; act("connect", network.path); }
        else { selectedNetwork = network; password.text = ""; password.forceActiveFocus(); }
    }
    onVisibleChanged: {
        if (visible) { message = ""; refresh(); }
        else { selectedNetwork = null; secret = ""; password.text = ""; }
    }
    Timer { interval: 3000; running: menu.visible; repeat: true; onTriggered: menu.refresh() }
    Process {
        id: query
        command: ["python3", menu.helper, "status"]
        stdout: StdioCollector { id: snapshot }
        onExited: {
            try {
                var result = JSON.parse(snapshot.text);
                if (result.error) menu.message = result.error;
                else menu.devices = result.devices;
            } catch (e) { menu.message = "WiFi unavailable"; }
        }
    }
    Process {
        id: operation
        stdinEnabled: true
        onStarted: { write(JSON.stringify({password: menu.secret}) + "\n"); menu.secret = ""; }
        stdout: StdioCollector { id: actionOutput }
        onExited: {
            try { var result = JSON.parse(actionOutput.text); menu.message = result.error || ""; }
            catch (e) { menu.message = "Could not complete request"; }
            menu.refresh();
        }
    }
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12
        Text { text: "WiFi"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; font.bold: true }
        Text { visible: operation.running || menu.message !== "" || menu.devices.length === 0; width: parent.width; text: operation.running ? "Connecting / updating..." : menu.message || "No WiFi adapter"; wrapMode: Text.Wrap; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
        Column {
            visible: menu.selectedNetwork !== null
            width: parent.width
            spacing: 8
            Text { width: parent.width; elide: Text.ElideRight; text: menu.selectedNetwork ? menu.selectedNetwork.name : ""; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
            TextField {
                id: password
                width: parent.width
                placeholderText: "Password"
                echoMode: TextInput.Password
                color: menu.foreground
                placeholderTextColor: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.6)
                background: Rectangle { radius: 6; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08); border.color: password.activeFocus ? menu.accent : "transparent" }
                onAccepted: connectButton.clicked()
                HoverHandler { cursorShape: Qt.IBeamCursor }
            }
            Row {
                spacing: 8
                PanelButton { id: connectButton; text: "Connect"; width: 90; foreground: menu.foreground; available: !menu.busy && password.text.length > 0; onClicked: { if (!available) return; menu.secret = password.text; menu.act("connect", menu.selectedNetwork.path); menu.selectedNetwork = null; password.text = ""; } }
                PanelButton { text: "Cancel"; width: 80; foreground: menu.foreground; onClicked: { menu.selectedNetwork = null; password.text = ""; } }
            }
        }
        Flickable {
            width: parent.width
            height: Math.max(80, menu.height - y - 24)
            contentHeight: adapters.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: adapters
                width: parent.width
                spacing: 16
                Repeater {
                    model: menu.devices
                    Column {
                        id: adapter
                        required property var modelData
                        width: adapters.width
                        spacing: 8
                        Row {
                            width: parent.width
                            spacing: 8
                            Text { width: 120; height: 40; verticalAlignment: Text.AlignVCenter; text: adapter.modelData.name; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            PanelSwitch { checked: adapter.modelData.powered; enabled: !menu.busy; foreground: menu.foreground; accent: menu.accent; onClicked: menu.act("power", adapter.modelData.path, checked ? "true" : "false") }
                            PanelButton { text: adapter.modelData.scanning ? "..." : "Scan"; foreground: menu.foreground; available: adapter.modelData.powered && !adapter.modelData.scanning && !menu.busy; onClicked: menu.act("scan", adapter.modelData.path) }
                        }
                        Repeater {
                            model: adapter.modelData.networks
                            Column {
                                required property var modelData
                                width: adapter.width
                                spacing: 4
                                PanelButton { width: parent.width; height: 42; foreground: menu.foreground; available: !menu.busy; text: (parent.modelData.connected ? "✓  " : "") + parent.modelData.name + "  ·  " + Math.round(parent.modelData.strength) + "%" + (parent.modelData.type === "open" ? "" : "  󰌾"); onClicked: menu.choose(parent.modelData) }
                                PanelButton { visible: parent.modelData.connected; text: "Disconnect"; width: 120; height: 32; foreground: menu.foreground; available: !menu.busy; onClicked: menu.act("disconnect", adapter.modelData.path) }
                            }
                        }
                    }
                }
            }
        }
    }
}
