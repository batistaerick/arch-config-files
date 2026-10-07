import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 440
    implicitHeight: 500
    property var devices: []
    readonly property var device: devices.length ? devices[0] : null
    readonly property var details: device ? device.details : ({})
    readonly property var connected: device ? device.networks.find(n => n.connected) : null
    readonly property var groups: [
        {title: "CONNECTED", networks: device ? device.networks.filter(n => n.connected) : []},
        {title: "KNOWN NETWORKS", networks: device ? device.networks.filter(n => n.known && !n.connected) : []},
        {title: "OTHER NETWORKS", networks: device ? device.networks.filter(n => !n.known && !n.connected) : []}
    ]
    property var selectedNetwork: null
    property string message: ""
    property string secret: ""
    property bool sharing: false
    property var shareNetwork: null
    property string qrImage: ""
    property string qrError: ""
    property string qrSecret: ""
    function closeShare() { sharing = false; qrImage = ""; qrSecret = ""; qrPassword.text = ""; shareNetwork = null; }
    function generateQr() { if (!qrQuery.running && shareNetwork) { qrSecret = qrPassword.text; qrQuery.running = true; } }
    function openShare() {
        shareNetwork = connected;
        qrImage = ""; qrError = ""; qrPassword.text = "";
        sharing = true;
        if (shareNetwork.type === "open") generateQr();
        else qrPassword.forceActiveFocus();
    }
    property bool busy: operation ? operation.running : false
    property real downloadRate: 0
    property real uploadRate: 0
    property var previous: null
    property var latency: ({})
    property string helper: Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/wifi-popup.py"
    function bytes(value) {
        if (value === undefined) return "--";
        var units = ["B", "KB", "MB", "GB", "TB"], index = 0;
        while (value >= 1000 && index < units.length - 1) { value /= 1000; index++; }
        return value.toFixed(index ? 1 : 0) + " " + units[index];
    }
    function refresh() { if (!query.running) query.running = true; }
    function act(kind, path, extra) {
        if (busy) return;
        message = "";
        operation.command = ["python3", helper, kind, path];
        if (extra !== undefined) operation.command = operation.command.concat([extra]);
        operation.running = true;
    }
    function choose(network) {
        if (network.connected || network.available === false) return;
        if (network.type === "8021x") { message = "Enterprise credentials require impala or your network configuration."; return; }
        if (network.type === "open" || network.known) { secret = ""; act("connect", network.path); }
        else { selectedNetwork = network; password.text = ""; password.forceActiveFocus(); }
    }
    function probe() { if (visible && device && device.state === "connected" && !pingQuery.running) { pingQuery.command = ["python3", helper, "probe", device.name]; pingQuery.running = true; } }
    onVisibleChanged: {
        if (visible) { message = ""; previous = null; latency = ({}); refresh(); }
        else { selectedNetwork = null; secret = ""; password.text = ""; closeShare(); }
    }
    Timer { interval: 2000; running: menu.visible; repeat: true; onTriggered: menu.refresh() }
    Timer { interval: 15000; running: menu.visible; repeat: true; onTriggered: menu.probe() }
    Process {
        id: query
        command: ["python3", menu.helper, "status"]
        stdout: StdioCollector { id: snapshot }
        onExited: {
            try {
                var result = JSON.parse(snapshot.text);
                if (result.error) menu.message = result.error;
                else {
                    menu.devices = result.devices;
                    if (menu.device) {
                        var next = menu.device.details;
                        if (menu.previous && next.sampled > menu.previous.sampled) {
                            menu.downloadRate = Math.max(0, (next.rx - menu.previous.rx) / (next.sampled - menu.previous.sampled));
                            menu.uploadRate = Math.max(0, (next.tx - menu.previous.tx) / (next.sampled - menu.previous.sampled));
                        }
                        menu.previous = next;
                        if (menu.latency.ping === undefined) menu.probe();
                    }
                }
            } catch (e) { menu.message = "WiFi unavailable"; }
        }
    }
    Process {
        id: operation
        stdinEnabled: true
        onStarted: { write(JSON.stringify({password: menu.secret}) + "\n"); menu.secret = ""; }
        stdout: StdioCollector { id: operationOutput }
        onExited: {
            try { var result = JSON.parse(operationOutput.text); menu.message = result.error || ""; }
            catch (e) { menu.message = "Could not complete request"; }
            menu.refresh();
        }
    }
    Process {
        id: qrQuery
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/wifi-qr.py"]
        stdinEnabled: true
        onStarted: { write(JSON.stringify({network: menu.shareNetwork, password: menu.qrSecret}) + "\n"); menu.qrSecret = ""; qrPassword.text = ""; }
        stdout: StdioCollector { id: qrOutput }
        onExited: {
            if (!menu.sharing) return;
            try { var result = JSON.parse(qrOutput.text); menu.qrImage = result.image || ""; menu.qrError = result.error || ""; }
            catch (e) { menu.qrError = "Could not generate QR code"; }
        }
    }
    Process {
        id: pingQuery
        stdout: StdioCollector { id: pingOutput }
        onExited: { try { menu.latency = JSON.parse(pingOutput.text); } catch (e) {} }
    }
    Item {
        anchors.fill: parent
        anchors.margins: 18
        Column {
            id: wifiHeaderContent
            visible: !menu.sharing
            width: parent.width
            spacing: 14
            Item {
                width: parent.width
                height: 42
                Text { anchors.verticalCenter: parent.verticalCenter; text: menu.connected ? "󰤨" : "󰤮"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24 }
                Column {
                    x: 36
                    width: parent.width - 202
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text { width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: menu.connected ? menu.connected.name : "WiFi"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                    Text { text: menu.busy ? "UPDATING..." : menu.device ? String(menu.device.state).toUpperCase() : "NO ADAPTER"; color: menu.foreground; opacity: 0.6; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    PanelButton {
                        id: qrButton
                        text: "󰐲"; icon: true; height: 32; foreground: menu.foreground
                        available: !!menu.connected && ["open", "psk"].indexOf(menu.connected.type) >= 0 && !qrQuery.running
                        onClicked: menu.openShare()
                        HoverHandler { id: qrHover }
                        BarTooltip { target: qrButton; hovered: qrHover.hovered; text: "Share WiFi"; foreground: menu.foreground; background: menu.background }
                    }
                    PanelButton {
                        id: scanButton
                        text: "󰑓"; icon: true; height: 32; foreground: menu.foreground
                        available: !!menu.device && menu.device.powered && !menu.busy && !menu.device.scanning
                        onClicked: menu.act("scan", menu.device.path)
                        HoverHandler { id: scanHover }
                        BarTooltip { target: scanButton; hovered: scanHover.hovered; text: "Scan"; foreground: menu.foreground; background: menu.background }
                    }
                    PanelSwitch { checked: !!menu.device && menu.device.powered; enabled: !!menu.device && !menu.busy; foreground: menu.foreground; accent: menu.accent; onClicked: menu.act("power", menu.device.path, checked ? "true" : "false") }
                }
            }
            Column {
                width: parent.width
                spacing: 6
                Repeater {
                    model: [
                        ["Ping", menu.latency.ping != null ? Math.round(menu.latency.ping) + " ms" : "--", "Packet Loss", menu.latency.loss != null ? menu.latency.loss + "%" : "--"],
                        ["Receiving", menu.bytes(menu.downloadRate) + "/s", "Sending", menu.bytes(menu.uploadRate) + "/s"],
                        ["Downloaded", menu.bytes(menu.details.rx), "Uploaded", menu.bytes(menu.details.tx)],
                        ["IP Address", menu.details.ip || "--", "Gateway", menu.details.gateway || "--"]
                    ]
                    Item {
                        required property var modelData
                        width: wifiHeaderContent.width; height: 16
                        Text { text: parent.modelData[0]; color: menu.foreground; opacity: 0.6; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                        Text { x: 70; width: 125; horizontalAlignment: Text.AlignRight; text: parent.modelData[1]; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                        Text { x: 210; text: parent.modelData[2]; color: menu.foreground; opacity: 0.6; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                        Text { anchors.right: parent.right; text: parent.modelData[3]; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                    }
                }
            }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12) }
            Item {
                width: parent.width; height: 16
                Text { text: "WI-FI BAND: " + (menu.details.band || "--"); color: menu.foreground; opacity: 0.65; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                Text { anchors.right: parent.right; text: menu.details.automatic === false ? "PINNED" : "AUTOMATIC"; color: menu.foreground; opacity: 0.65; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
            }
            Column {
                visible: menu.selectedNetwork !== null; width: parent.width; spacing: 6
                Text { width: parent.width; elide: Text.ElideRight; text: menu.selectedNetwork ? menu.selectedNetwork.name : ""; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                TextField {
                    id: password; width: parent.width; placeholderText: "Password"; echoMode: TextInput.Password; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                    placeholderTextColor: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.5)
                    background: Rectangle { radius: 4; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08); border.color: password.activeFocus ? menu.accent : "transparent" }
                    HoverHandler { cursorShape: Qt.IBeamCursor }
                    onAccepted: connectButton.clicked()
                }
                Row {
                    spacing: 6
                    PanelButton { id: connectButton; text: "Connect"; width: 90; foreground: menu.foreground; available: !menu.busy && password.text.length > 0; onClicked: { if (!available) return; menu.secret = password.text; menu.act("connect", menu.selectedNetwork.path); menu.selectedNetwork = null; password.text = ""; } }
                    PanelButton { text: "Cancel"; foreground: menu.foreground; onClicked: { menu.selectedNetwork = null; password.text = ""; } }
                }
            }
            Text { visible: menu.message !== ""; width: parent.width; text: menu.message; wrapMode: Text.Wrap; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12) }
        }
        Flickable {
            visible: !menu.sharing
            anchors.top: wifiHeaderContent.bottom
            anchors.topMargin: 14
            anchors.bottom: parent.bottom
            width: parent.width
            contentHeight: networks.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: networks
                width: parent.width
                spacing: 14
                Repeater {
                    model: menu.groups
                    Column {
                        required property var modelData
                        width: networks.width; spacing: 6
                        Text { text: parent.modelData.title; color: menu.foreground; opacity: 0.6; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                        Text { visible: parent.modelData.networks.length === 0; text: menu.device && menu.device.scanning ? "Scanning..." : "No networks"; color: menu.foreground; opacity: 0.5; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                        Repeater {
                            model: parent.modelData.networks
                            Rectangle {
                                id: network
                                required property var modelData
                                width: networks.width; height: 44; radius: 4
                                color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, modelData.connected ? 0.18 : networkMouse.containsMouse ? 0.1 : 0.04)
                                border.width: modelData.connected ? 0 : 1
                                border.color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.15)
                                activeFocusOnTab: true
                                Keys.onReturnPressed: if (!menu.busy) menu.choose(modelData)
                                Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "󰤨"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                                Column {
                                    x: 36; width: parent.width - networkActions.width - 52; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                    Text { width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: network.modelData.name; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                    Text { visible: network.modelData.connected || network.modelData.available === false; text: network.modelData.connected ? "Connected" : "Offline"; color: menu.foreground; opacity: 0.6; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                                }
                                MouseArea { id: networkMouse; anchors.fill: parent; hoverEnabled: true; enabled: !menu.busy && !network.modelData.connected && network.modelData.available !== false; cursorShape: Qt.PointingHandCursor; onClicked: menu.choose(network.modelData) }
                                Row {
                                    id: networkActions
                                    anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Text { visible: network.modelData.available !== false; anchors.verticalCenter: parent.verticalCenter; text: Math.round(network.modelData.strength) + "%"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                    Text { visible: network.modelData.type !== "open"; anchors.verticalCenter: parent.verticalCenter; text: "󰌾"; color: menu.foreground; opacity: 0.65; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                                    PanelButton { visible: network.modelData.connected; text: "Disconnect"; width: 98; height: 30; foreground: menu.foreground; available: !menu.busy; onClicked: menu.act("disconnect", menu.device.path) }
                                }
                                BarTooltip { target: network; hovered: networkMouse.containsMouse; text: network.modelData.connected || network.modelData.available === false ? "" : "Connect"; foreground: menu.foreground; background: menu.background }
                            }
                        }
                    }
                }
            }
        }
        Column {
            visible: menu.sharing
            width: parent.width
            spacing: 14
            Row {
                width: parent.width; spacing: 8
                Text { width: parent.width - 42; anchors.verticalCenter: parent.verticalCenter; text: menu.shareNetwork ? menu.shareNetwork.name : ""; elide: Text.ElideRight; textFormat: Text.PlainText; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                PanelButton { text: "×"; width: 34; height: 34; foreground: menu.foreground; onClicked: menu.closeShare() }
            }
            TextField {
                id: qrPassword
                visible: menu.qrImage === "" && menu.shareNetwork && menu.shareNetwork.type !== "open"
                width: parent.width; placeholderText: "WiFi password"; echoMode: TextInput.Password
                color: menu.foreground; placeholderTextColor: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.5)
                background: Rectangle { radius: 4; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08); border.color: qrPassword.activeFocus ? menu.accent : "transparent" }
                HoverHandler { cursorShape: Qt.IBeamCursor }
                onAccepted: if (text.length > 0) menu.generateQr()
            }
            PanelButton { visible: qrPassword.visible; text: "Show QR"; width: 100; foreground: menu.foreground; available: qrPassword.text.length > 0 && !qrQuery.running; onClicked: menu.generateQr() }
            Image { visible: menu.qrImage !== ""; anchors.horizontalCenter: parent.horizontalCenter; width: 300; height: 300; source: menu.qrImage; fillMode: Image.PreserveAspectFit; smooth: false }
            Text { width: parent.width; text: menu.qrError; visible: text !== ""; color: menu.foreground; wrapMode: Text.Wrap; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
        }
    }
}
