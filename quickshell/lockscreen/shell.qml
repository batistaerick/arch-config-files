import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: shell
    readonly property bool preview: Quickshell.env("DESKTOP_LOCK_PREVIEW") === "1"
    readonly property string themePath: Quickshell.env("DESKTOP_LOCK_THEME")
    readonly property var config: JSON.parse(Quickshell.env("DESKTOP_LOCK_CONFIG") || "{}")
    readonly property var sddm: auth.sddm
    readonly property var userModel: auth.userModel
    readonly property var sessionModel: auth.sessionModel
    readonly property var keyboard: keyboardState
    property bool unlocked: false

    QtObject { id: keyboardState; property bool numLock: false }
    AuthAdapter {
        id: auth
        preview: shell.preview
        onAuthenticated: {
            shell.unlocked = true;
            Quickshell.execDetached(["loginctl", "unlock-session"]);
            quitTimer.start();
        }
    }

    Timer { id: quitTimer; interval: 200; onTriggered: Qt.quit() }

    Component {
        id: themeSurface
        Item {
            Loader {
                id: theme
                anchors.fill: parent
                asynchronous: true
                // Create the lock surface before loading the theme and video decoder.
                Component.onCompleted: Qt.callLater(function() {
                    theme.source = "file://" + shell.themePath + "/Main.qml";
                })
                onLoaded: item.forceActiveFocus()
            }
            Rectangle {
                anchors.fill: parent
                visible: theme.status === Loader.Error
                color: "#181824"
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    Text { text: "Unlock"; color: "white"; font.pixelSize: 24 }
                    TextInput {
                        id: fallbackPassword
                        width: 280
                        height: 36
                        color: "white"
                        echoMode: TextInput.Password
                        focus: parent.parent.visible
                        onAccepted: {
                            auth.sddm.login(Quickshell.env("USER"), text, 0);
                            text = "";
                        }
                    }
                }
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: !shell.preview && !shell.unlocked
        surface: WlSessionLockSurface {
            color: "black"
            Loader { anchors.fill: parent; sourceComponent: themeSurface }
        }
    }

    Loader {
        active: shell.preview
        sourceComponent: Component {
            PanelWindow {
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                color: "black"
                Loader { anchors.fill: parent; sourceComponent: themeSurface }
                Item {
                    anchors.fill: parent
                    focus: true
                    Keys.onEscapePressed: Qt.quit()
                    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
                }
            }
        }
    }
}
