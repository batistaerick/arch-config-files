import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Bluetooth

ThemedPopup {
    id: menu
    implicitWidth: 440
    implicitHeight: 480
    property var scanningAdapter: null
    onVisibleChanged: if (!visible && scanningAdapter) {
        scanningAdapter.discovering = false;
        scanningAdapter = null;
    }
    Timer {
        interval: 20000
        running: menu.scanningAdapter !== null
        onTriggered: { menu.scanningAdapter.discovering = false; menu.scanningAdapter = null; }
    }
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12
        Text { text: "Bluetooth"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; font.bold: true }
        Text { visible: Bluetooth.adapters.values.length === 0; text: "No Bluetooth adapter"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
        Flickable {
            width: parent.width
            height: menu.height - y - 24
            contentHeight: adapters.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: adapters
                width: parent.width
                spacing: 16
                Repeater {
                    model: Bluetooth.adapters.values
                    Column {
                        id: adapter
                        required property var modelData
                        width: adapters.width
                        spacing: 8
                        Row {
                            spacing: 8
                            Text { width: 150; height: 40; verticalAlignment: Text.AlignVCenter; text: adapter.modelData.name; elide: Text.ElideRight; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            PanelSwitch { checked: adapter.modelData.enabled; foreground: menu.foreground; accent: menu.accent; onClicked: adapter.modelData.enabled = checked }
                            PanelButton {
                                text: adapter.modelData.discovering ? "Stop" : "Scan"
                                foreground: menu.foreground
                                available: adapter.modelData.enabled
                                onClicked: {
                                    if (adapter.modelData.discovering) {
                                        adapter.modelData.discovering = false;
                                        if (menu.scanningAdapter === adapter.modelData) menu.scanningAdapter = null;
                                    } else {
                                        if (menu.scanningAdapter) menu.scanningAdapter.discovering = false;
                                        menu.scanningAdapter = adapter.modelData;
                                        adapter.modelData.discovering = true;
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: adapter.modelData.devices.values
                            Column {
                                id: device
                                required property var modelData
                                property bool confirmingForget: false
                                width: adapter.width
                                spacing: 6
                                Text { width: parent.width; elide: Text.ElideRight; text: (device.modelData.connected ? "✓  " : "") + device.modelData.name; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: device.modelData.connected }
                                Text { width: parent.width; text: BluetoothDeviceState.toString(device.modelData.state) + (device.modelData.batteryAvailable ? " · " + Math.round(device.modelData.battery * 100) + "% battery" : ""); color: menu.foreground; opacity: 0.65; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                Row {
                                    spacing: 8
                                    PanelButton {
                                        width: 120
                                        text: device.modelData.pairing ? "Cancel" : device.modelData.connected ? "Disconnect" : device.modelData.paired ? "Connect" : "Pair"
                                        foreground: menu.foreground
                                        available: adapter.modelData.enabled
                                        onClicked: {
                                            if (device.modelData.pairing) device.modelData.cancelPair();
                                            else if (device.modelData.connected) device.modelData.disconnect();
                                            else if (device.modelData.paired) device.modelData.connect();
                                            else device.modelData.pair();
                                        }
                                    }
                                    PanelButton { visible: device.modelData.paired; width: 120; text: device.confirmingForget ? "Confirm" : "Forget"; foreground: menu.foreground; onClicked: { if (device.confirmingForget) device.modelData.forget(); else device.confirmingForget = true; } }
                                    PanelButton { visible: device.confirmingForget; text: "Cancel"; foreground: menu.foreground; onClicked: device.confirmingForget = false }
                                }
                                Rectangle { width: parent.width; height: 1; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.1) }
                            }
                        }
                    }
                }
            }
        }
    }
}
