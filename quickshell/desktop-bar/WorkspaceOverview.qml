import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "PanelStyle.js" as PanelStyle
import "WorkspaceModel.js" as WorkspaceModel

PanelWindow {
    id: overview
    required property color foreground
    required property color background
    required property color accent
    property bool opened: false
    property real revealProgress: opened ? 1 : 0
    readonly property var workspaces: WorkspaceModel.occupied(Hyprland.toplevels.values)
    visible: opened || revealProgress > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "desktop-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    Behavior on revealProgress { NumberAnimation { duration: 320; easing.type: overview.opened ? Easing.OutCubic : Easing.InCubic } }
    onOpenedChanged: if (opened) Hyprland.refreshToplevels()
    Timer { interval: 1000; repeat: true; running: overview.opened; onTriggered: Hyprland.refreshToplevels() }
    function choose(id) {
        if (id < 1 || id > 10) return;
        opened = false;
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }
    IpcHandler {
        target: "overview"
        function close(): void { overview.opened = false; }
        function status(): string { return JSON.stringify({opened: overview.opened, workspaces: overview.workspaces.map(w => ({id: w.id, windows: w.windows.length}))}); }
    }
    Loader {
        anchors.fill: parent
        active: overview.visible
        sourceComponent: Component {
            Rectangle {
                color: overview.background
                opacity: overview.revealProgress
                focus: overview.opened
                Keys.onEscapePressed: overview.opened = false
                Keys.onPressed: event => {
                    if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) { overview.choose(event.key - Qt.Key_0); event.accepted = true; }
                    else if (event.key === Qt.Key_0) { overview.choose(10); event.accepted = true; }
                }
                MouseArea { anchors.fill: parent; onClicked: overview.opened = false }
                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 96, 1440)
                    spacing: 18
                    scale: 0.96 + overview.revealProgress * 0.04
                    Row {
                        width: parent.width; spacing: 12
                        Text { width: parent.width - 46; height: 34; text: "󰕮  Overview"; color: overview.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.headingSize; font.bold: true; verticalAlignment: Text.AlignVCenter }
                        PanelButton { width: 34; height: 34; icon: true; text: "󰅖"; foreground: overview.foreground; onClicked: overview.opened = false }
                    }
                    Grid {
                        id: grid
                        width: parent.width
                        columns: overview.workspaces.length <= 1 ? 1 : overview.workspaces.length <= 4 ? 2 : 3
                        spacing: 18
                        readonly property int rows: Math.max(1, Math.ceil(overview.workspaces.length / columns))
                        Repeater {
                            model: overview.workspaces
                            WorkspaceOverviewTile {
                                required property var modelData
                                width: (grid.width - (grid.columns - 1) * grid.spacing) / grid.columns
                                height: Math.max(100, Math.min(width * 0.55 + 40, (overview.height - 180 - (grid.rows - 1) * grid.spacing) / grid.rows))
                                workspace: modelData
                                foreground: overview.foreground; background: overview.background; accent: overview.accent
                                capturing: overview.visible
                                selected: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData.id
                                onChosen: id => overview.choose(id)
                            }
                        }
                    }
                    Text {
                        visible: overview.workspaces.length === 0
                        width: parent.width; height: 100
                        text: "No occupied workspaces"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        color: overview.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize
                    }
                    Text { text: "Click a workspace to switch  ·  1–9 / 0 to jump  ·  Esc to close"; color: overview.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                }
            }
        }
    }
}
