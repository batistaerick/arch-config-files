import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "PanelStyle.js" as PanelStyle

// First-login guide. Each step closes this panel, then opens an existing
// workflow (the appearance carousel, a bar panel, or Walker's Learn menu)
// through the same scripts Walker and the keyboard shortcuts use.
ThemedPopup {
    id: menu
    property int maximumHeight: 900
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    readonly property var steps: [
        {kind: "theme", icon: "󰸌", label: "Choose a theme"},
        {kind: "wallpaper", icon: "󰋩", label: "Pick a wallpaper"},
        {kind: "display", icon: "󰍹", label: "Set the primary display"},
        {kind: "keyboard", icon: "󰌌", label: "Add keyboard layouts"},
        {kind: "wifi", icon: "", label: "Connect to WiFi"},
        {kind: "bluetooth", icon: "", label: "Pair Bluetooth devices"},
        {kind: "learn", icon: "󰧑", label: "Learn shortcuts and gestures"}
    ]
    property bool dontShowAgain: true
    property string pendingStep: ""
    property bool wasOpened: false
    signal autoShowRequested()

    implicitWidth: 440
    // The shared surface reserves PanelStyle.surfaceInset around its content frame.
    implicitHeight: Math.min(content.implicitHeight + PanelStyle.padding * 2 + PanelStyle.surfaceInset * 2, maximumHeight)

    function stepCommand(kind) {
        if (kind === "theme" || kind === "wallpaper")
            return ["bash", Quickshell.shellDir + "/scripts/appearance-picker.sh", kind];
        if (kind === "learn")
            return [menu.configHome + "/walker/bin/walker", "--provider", "menus:learn"];
        return ["bash", Quickshell.shellDir + "/scripts/show-panel.sh", kind];
    }

    function openStep(kind) {
        pendingStep = kind;
        opened = false;
    }

    function stateCommand(action) {
        return ["python3", Quickshell.shellDir + "/scripts/welcome-state.py", action];
    }

    // Auto-show at most once per Quickshell session; configuration reloads keep this flag.
    PersistentProperties {
        id: session
        reloadableId: "welcomeSession"
        property bool autoShowChecked: false
    }

    Timer {
        // Let the bar and the startup wallpaper reveal settle before unfolding.
        interval: 2000
        running: !session.autoShowChecked
        onTriggered: if (!statusQuery.running) statusQuery.running = true
    }

    Process {
        id: statusQuery
        command: menu.stateCommand("status")
        stdout: StdioCollector { id: statusOutput }
        onExited: function(code) {
            if (code === 0) {
                try {
                    var state = JSON.parse(statusOutput.text);
                    menu.dontShowAgain = !state.pending;
                    if (state.show && !session.autoShowChecked && !menu.opened) menu.autoShowRequested();
                } catch (e) {}
            }
            session.autoShowChecked = true;
        }
    }

    Process { id: saveChoice }

    onOpenedChanged: {
        if (!opened) return;
        wasOpened = true;
        if (!statusQuery.running) statusQuery.running = true;
    }
    onVisibleChanged: {
        // Only a real open/close cycle records a choice, not parent or window visibility changes.
        if (visible || !wasOpened) return;
        wasOpened = false;
        // Closing records the switch: dismissed for good, or shown again at the next login.
        saveChoice.command = menu.stateCommand(dontShowAgain ? "dismiss" : "remind");
        saveChoice.running = true;
        if (pendingStep !== "") {
            Quickshell.execDetached(menu.stepCommand(pendingStep));
            pendingStep = "";
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: PanelStyle.padding
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 12

            Item {
                width: parent.width
                height: 44
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - closeButton.width - 8
                    spacing: 12
                    Item {
                        id: logo
                        width: 40
                        height: 40
                        anchors.verticalCenter: parent.verticalCenter
                        visible: logoImage.status === Image.Ready
                        // The installed logo is a black silhouette; tint it with the theme accent.
                        Image {
                            id: logoImage
                            anchors.fill: parent
                            source: "file://" + menu.configHome + "/fastfetch/assets/eitr-logo.png"
                            sourceSize.width: 80
                            sourceSize.height: 80
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: false
                            layer.enabled: true
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: menu.accent
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: logoImage
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                            }
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - (logo.visible ? logo.width + parent.spacing : 0)
                        spacing: 2
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: "Welcome to Eitr"
                            color: menu.foreground
                            font.family: PanelStyle.fontFamily
                            font.pixelSize: PanelStyle.headingSize
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: "Set up the essentials to get started."
                            color: menu.foreground
                            opacity: 0.65
                            font.family: PanelStyle.fontFamily
                            font.pixelSize: PanelStyle.secondarySize
                        }
                    }
                }
                PanelButton {
                    id: closeButton
                    objectName: "welcomeCloseButton"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34
                    text: "󰅖"; icon: true
                    foreground: menu.foreground
                    onClicked: menu.opened = false
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.alpha(menu.foreground, PanelStyle.dividerAlpha) }

            Column {
                width: parent.width
                spacing: 6
                Repeater {
                    model: menu.steps
                    PanelButton {
                        required property var modelData
                        width: content.width
                        text: modelData.label
                        leadingIcon: modelData.icon
                        textAlignment: Text.AlignLeft
                        foreground: menu.foreground
                        onClicked: menu.openStep(modelData.kind)
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.alpha(menu.foreground, PanelStyle.dividerAlpha) }

            Row {
                width: parent.width
                Text {
                    width: parent.width - dontShowSwitch.width
                    height: dontShowSwitch.height
                    verticalAlignment: Text.AlignVCenter
                    text: "Don't show again"
                    color: menu.foreground
                    font.family: PanelStyle.fontFamily
                    font.pixelSize: PanelStyle.bodySize
                }
                PanelSwitch {
                    id: dontShowSwitch
                    objectName: "welcomeDontShowSwitch"
                    checked: menu.dontShowAgain
                    foreground: menu.foreground
                    accent: menu.accent
                    onToggled: menu.dontShowAgain = checked
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Reopen this guide anytime from Walker: Learn > Welcome."
                color: menu.foreground
                opacity: 0.65
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.captionSize
            }
        }
    }
}
