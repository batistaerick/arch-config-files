import QtQuick
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Bluetooth

ThemedPopup {
    id: menu
    implicitWidth: 468
    implicitHeight: Math.min(508, Math.max(248, groups.height + 122))
    property var adapter: Bluetooth.defaultAdapter
    property var scanningAdapter: null
    readonly property var sections: [
        {title: "CONNECTED", devices: adapter ? adapter.devices.values.filter(d => d.connected) : []},
        {title: "KNOWN DEVICES", devices: adapter ? adapter.devices.values.filter(d => !d.connected && d.paired) : []},
        {title: "SCANNED DEVICES", devices: adapter ? adapter.devices.values.filter(d => !d.connected && !d.paired) : []}
    ]
    function scan() {
        if (!adapter) return;
        if (scanningAdapter) { scanningAdapter.discovering = false; scanningAdapter = null; }
        else { scanningAdapter = adapter; adapter.discovering = true; scanTimer.restart(); }
    }
    onOpenedChanged: if (!opened && scanningAdapter) {
        scanningAdapter.discovering = false;
        scanningAdapter = null;
    }
    Timer {
        id: scanTimer
        interval: 20000
        onTriggered: if (menu.scanningAdapter) { menu.scanningAdapter.discovering = false; menu.scanningAdapter = null; }
    }
    Item {
        anchors.fill: parent
        anchors.margins: PanelStyle.padding
        Item {
            id: header
            width: parent.width
            height: 40
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Bluetooth"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.headingSize; font.bold: true }
            Row {
                anchors.right: parent.right
                spacing: 8
                PanelButton {
                    id: scanButton
                    text: "󰑓"; icon: true; compactIconBackground: true
                    loading: !!menu.scanningAdapter
                    foreground: menu.foreground
                    available: !!menu.adapter && menu.adapter.enabled
                    onClicked: menu.scan()
                    HoverHandler { id: scanHover }
                    BarTooltip { target: scanButton; hovered: scanHover.hovered; text: scanButton.loading ? "Scanning" : "Scan"; foreground: menu.foreground; background: menu.background }
                }
                PanelButton {
                    id: stopScanButton
                    visible: !!menu.scanningAdapter
                    text: "󰓛"; icon: true; compactIconBackground: true
                    foreground: menu.foreground
                    onClicked: menu.scan()
                    HoverHandler { id: stopScanHover }
                    BarTooltip { target: stopScanButton; hovered: stopScanHover.hovered; text: "Stop scan"; foreground: menu.foreground; background: menu.background }
                }
                PanelSwitch { checked: !!menu.adapter && menu.adapter.enabled; enabled: !!menu.adapter; foreground: menu.foreground; accent: menu.accent; onClicked: menu.adapter.enabled = checked }
            }
        }
        Flickable {
            anchors.top: header.bottom
            anchors.topMargin: 18
            anchors.bottom: parent.bottom
            width: parent.width
            contentHeight: groups.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: groups
                width: parent.width
                spacing: 20
                Text { visible: !menu.adapter || !menu.adapter.enabled; text: menu.adapter ? "Bluetooth is off" : "No Bluetooth adapter"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
                Repeater {
                    model: menu.sections
                    Column {
                        required property var modelData
                        width: groups.width
                        spacing: 8
                        Rectangle { width: parent.width; height: 1; color: Qt.alpha(menu.foreground, PanelStyle.dividerAlpha) }
                        Text { text: parent.modelData.title; color: menu.foreground; opacity: 0.6; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                        Text { visible: parent.modelData.devices.length === 0; text: parent.modelData.title === "SCANNED DEVICES" && menu.scanningAdapter ? "Scanning..." : "No devices"; color: menu.foreground; opacity: 0.55; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.secondarySize }
                        Repeater {
                            model: parent.modelData.devices
                            Item {
                                id: device
                                required property var modelData
                                property bool confirmingForget: false
                                width: groups.width
                                height: 44
                                Rectangle { anchors.fill: parent; radius: PanelStyle.controlRadius; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, device.modelData.connected ? 0.18 : 0.04) }
                                Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: device.modelData.connected ? "󰂱" : "󰂯"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: 18 }
                                Column {
                                    x: 36
                                    width: Math.max(0, actions.x - x - 8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    Text { width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: device.modelData.name; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
                                    Text { width: parent.width; elide: Text.ElideRight; text: BluetoothDeviceState.toString(device.modelData.state) + (device.modelData.batteryAvailable ? " · " + Math.round(device.modelData.battery * 100) + "%" : ""); color: menu.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                                }
                                Row {
                                    id: actions
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    PanelButton {
                                        id: connectionButton
                                        readonly property string actionLabel: device.confirmingForget || device.modelData.pairing ? "Cancel" : device.modelData.connected ? "Disconnect" : device.modelData.paired ? "Connect" : "Pair"
                                        width: 32
                                        height: 30
                                        icon: true
                                        text: device.confirmingForget || device.modelData.pairing ? "" : device.modelData.connected ? "󰂲" : device.modelData.paired ? "󰂱" : "󰂯"
                                        Accessible.name: actionLabel
                                        foreground: menu.foreground
                                        available: !!menu.adapter && menu.adapter.enabled
                                        onClicked: {
                                            if (device.confirmingForget) device.confirmingForget = false;
                                            else if (device.modelData.pairing) device.modelData.cancelPair();
                                            else if (device.modelData.connected) device.modelData.disconnect();
                                            else if (device.modelData.paired) device.modelData.connect();
                                            else device.modelData.pair();
                                        }
                                        HoverHandler { id: connectionHover }
                                        BarTooltip { target: connectionButton; hovered: connectionHover.hovered; text: connectionButton.actionLabel; foreground: menu.foreground; background: menu.background }
                                    }
                                    PanelButton {
                                        id: forgetButton
                                        visible: device.modelData.paired
                                        width: 32; height: 30; icon: true
                                        text: device.confirmingForget ? "" : "󰆴"
                                        Accessible.name: device.confirmingForget ? "Confirm removal" : "Remove"
                                        foreground: menu.foreground
                                        onClicked: { if (device.confirmingForget) device.modelData.forget(); else device.confirmingForget = true; }
                                        HoverHandler { id: forgetHover }
                                        BarTooltip { target: forgetButton; hovered: forgetHover.hovered; text: device.confirmingForget ? "Confirm removal" : "Remove"; foreground: menu.foreground; background: menu.background }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
