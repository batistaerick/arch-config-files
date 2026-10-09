import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: shell
    NotificationService { id: notificationsService }

    property bool statusOpen: false
    property bool barVisible: true
    property int barHeight: 30
    property color bg: Qt.rgba(24 / 255, 24 / 255, 36 / 255, 0.38)
    property color fg: "#cdd6f4"
    property color activeFg: "#11111b"
    property color activeBg: "#cdd6f4"
    property color hoverBg: Qt.rgba(180 / 255, 190 / 255, 254 / 255, 0.15)
    property bool idleLockEnabled: false
    property string primaryDisplay: ""
    property bool portableDisplayMode: false
    property string workspaceStyle: "Numbers"
    property color workspaceMenuBg: "#181824"
    property color workspaceMenuFg: "#cdd6f4"
    property string barAppearance: "transparent"
    property string barLayout: "unified"
    property string barEdge: "top"
    property bool settingsDirty: false
    property string dragCandidate: ""
    readonly property bool verticalBar: barEdge === "left" || barEdge === "right"
    readonly property var desktopApplications: DesktopEntries.applications.values

    function barBackground() {
        return barAppearance === "solid" ? workspaceMenuBg : bg;
    }

    function barDoubleClick(button) {
        if (button === Qt.LeftButton) updateBarSetting("appearance", barAppearance === "solid" ? "transparent" : "solid");
        else if (button === Qt.RightButton) updateBarSetting("layout", barLayout === "split" ? "unified" : "split");
    }

    function updateBarSetting(key, value) {
        var choices = {appearance: ["transparent", "solid"], layout: ["unified", "split"], edge: ["top", "bottom", "left", "right"]};
        if (!choices[key] || choices[key].indexOf(value) === -1) return;
        if (key === "appearance") barAppearance = value;
        else if (key === "layout") barLayout = value;
        else barEdge = value;
        settingsDirty = true;
        settingsSaveDelay.restart();
    }

    IpcHandler {
        target: "bar"
        function visibility(): void { shell.barVisible = !shell.barVisible; }
        function update(key: string, value: string): void { shell.updateBarSetting(key, value) }
        function toggle(kind: string): void {
            if (kind === "appearance") shell.updateBarSetting(kind, shell.barAppearance === "solid" ? "transparent" : "solid");
            else if (kind === "layout") shell.updateBarSetting(kind, shell.barLayout === "split" ? "unified" : "split");
        }
    }

    Process {
        id: barSettingsQuery
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/bar-settings.py", "status"]
        running: true
        stdout: StdioCollector { id: barSettingsOutput }
        onExited: function(code) {
            if (code !== 0 || shell.settingsDirty || saveBarSettings.running) return;
            try {
                var settings = JSON.parse(barSettingsOutput.text);
                shell.barAppearance = settings.appearance;
                shell.barLayout = settings.layout;
                shell.barEdge = settings.edge;
            } catch (e) {}
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!barSettingsQuery.running && !saveBarSettings.running) barSettingsQuery.running = true
    }

    Timer {
        id: settingsSaveDelay
        interval: 100
        onTriggered: shell.persistBarSettings()
    }

    function persistBarSettings() {
        if (saveBarSettings.running) return;
        settingsDirty = false;
        saveBarSettings.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/bar-settings.py",
            "set-all", barAppearance, barLayout, barEdge];
        saveBarSettings.running = true;
    }

    Process {
        id: saveBarSettings
        onExited: {
            if (shell.settingsDirty) shell.persistBarSettings();
            else if (!barSettingsQuery.running) barSettingsQuery.running = true;
        }
    }

    Process {
        id: saveWorkspaceStyle
        onExited: if (!workspacePalette.running) workspacePalette.running = true
    }

    Process {
        id: workspacePalette
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/workspace-color.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var palette = JSON.parse(text);
                    shell.activeBg = palette.background;
                    shell.activeFg = palette.foreground;
                    if (!saveWorkspaceStyle.running) shell.workspaceStyle = palette.style;
                    shell.workspaceMenuBg = palette.menuBackground;
                    shell.workspaceMenuFg = palette.menuForeground;
                    shell.fg = palette.menuForeground;
                    var background = shell.workspaceMenuBg;
                    shell.bg = Qt.rgba(background.r, background.g, background.b, 0.38);
                    shell.hoverBg = Qt.rgba(shell.fg.r, shell.fg.g, shell.fg.b, 0.15);
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!workspacePalette.running) workspacePalette.running = true
    }

    Process {
        id: primaryDisplayQuery
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/display-primary.py", "status"]
        running: true
        stdout: StdioCollector { id: primaryDisplayOutput }
        onExited: function(code) {
            if (code !== 0) return;
            try {
                var result = JSON.parse(primaryDisplayOutput.text);
                shell.primaryDisplay = result.primary || "";
                shell.portableDisplayMode = !!result.portable;
            } catch (e) {}
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!primaryDisplayQuery.running) primaryDisplayQuery.running = true
    }

    Process {
        id: idleLockStatus
        command: ["pgrep", "-x", "hypridle"]
        running: true
        onExited: function(code) { shell.idleLockEnabled = code === 0; }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: if (!idleLockStatus.running && !toggleIdleLock.running) idleLockStatus.running = true
    }

    Process {
        id: toggleIdleLock
        command: ["bash", Quickshell.env("HOME") + "/.config/walker/scripts/actions/toggle/idle-lock.sh"]
        onExited: if (!idleLockStatus.running) idleLockStatus.running = true
    }

    AppearancePicker {}

    function run(command) {
        Quickshell.execDetached(["bash", "-lc", command]);
    }

    function workspaceActive(index) {
        return Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index;
    }

    function workspaceLabel(index) {
        if (workspaceStyle === "Glyph") return workspaceActive(index + 1) ? "✦" : "✧";
        return String(index + 1);
    }

    function workspaceApps(workspaceId) {
        var names = [];
        for (var window of Hyprland.toplevels.values) {
            if (!window.workspace || window.workspace.id !== workspaceId) continue;
            var info = window.lastIpcObject;
            if (info.mapped === false) continue;
            var appId = (window.wayland && window.wayland.appId) || info.class || info.initialClass || "";
            var entry = desktopApplications.find(app => app.id === appId || app.startupClass === appId)
                || DesktopEntries.heuristicLookup(appId);
            var name = entry ? entry.name : appId;
            if (name && names.indexOf(name) === -1) names.push(name);
        }
        return names.join("\n");
    }

    function targetScreens() {
        var screens = Quickshell.screens || [];
        var fallback = null;
        var largest = null;
        for (var i = 0; i < screens.length; i++) {
            if (!screens[i])
                continue;

            if (primaryDisplay && screens[i].name === primaryDisplay)
                return [screens[i]];

            if (!largest || screens[i].width * screens[i].height > largest.width * largest.height)
                largest = screens[i];

            if (screens[i].name === "HDMI-A-1")
                fallback = screens[i];
            else if (screens[i].name === "DP-3" && (!fallback || fallback.name !== "HDMI-A-1"))
                fallback = screens[i];
            else if (!fallback)
                fallback = screens[i];
        }
        if (portableDisplayMode && largest)
            return [largest];
        return fallback ? [fallback] : [];
    }

    Variants {
        model: shell.targetScreens()

        delegate: Component {
            PanelWindow {
                id: bar

                required property var modelData
                readonly property Item stripItem: barContents
                readonly property var dockPanels: [wifiMenu, bluetoothMenu, brightnessMenu, volumeMenu, micMenu,
                    keyboardMenu, calendarMenu, weatherMenu, hardwareMenu, aiMenu, obsMenu, recordingMenu, workspaceMenu, notificationCenter]
                readonly property bool panelOpen: dockPanels.some(panel => panel.visible)
                property var pendingPanel: null

                function closePanels() {
                    pendingPanel = null;
                    dockPanels.forEach(panel => panel.opened = false);
                }
                function showPanel(panel) {
                    pendingPanel = panel;
                    dockPanels.forEach(other => other.opened = false);
                    finishPanelSwitch();
                }
                function togglePanel(panel) {
                    if (panel.opened || pendingPanel === panel) closePanels();
                    else showPanel(panel);
                }
                function finishPanelSwitch() {
                    if (!pendingPanel || dockPanels.some(panel => panel.visible)) return;
                    var next = pendingPanel;
                    pendingPanel = null;
                    next.opened = true;
                }
                Timer {
                    interval: 16
                    repeat: true
                    running: bar.pendingPanel !== null
                    onTriggered: bar.finishPanelSwitch()
                }

                screen: modelData
                visible: shell.barVisible || panelOpen
                implicitWidth: modelData.width
                implicitHeight: modelData.height
                color: "transparent"
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: shell.barVisible ? (shell.verticalBar ? barContents.width : shell.barHeight) : 0
                WlrLayershell.namespace: "desktop-bar"
                WlrLayershell.layer: WlrLayer.Top
                mask: dockInput
                WlrLayershell.keyboardFocus: panelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                Region {
                    id: dockInput
                    width: 0; height: 0
                    Region { item: shell.barLayout === "unified" ? barContents : null }
                    Region { item: shell.barLayout === "split" && !shell.verticalBar ? leftBackground : null }
                    Region { item: shell.barLayout === "split" && !shell.verticalBar ? middleBackground : null }
                    Region { item: shell.barLayout === "split" && !shell.verticalBar ? rightBackground : null }
                    Region { item: shell.barLayout === "split" && shell.verticalBar ? verticalStartBackground : null }
                    Region { item: shell.barLayout === "split" && shell.verticalBar ? verticalMiddleBackground : null }
                    Region { item: shell.barLayout === "split" && shell.verticalBar ? verticalEndBackground : null }
                    Region { item: wifiMenu.opened ? wifiMenu : null }
                    Region { item: bluetoothMenu.opened ? bluetoothMenu : null }
                    Region { item: brightnessMenu.opened ? brightnessMenu : null }
                    Region { item: volumeMenu.opened ? volumeMenu : null }
                    Region { item: micMenu.opened ? micMenu : null }
                    Region { item: keyboardMenu.opened ? keyboardMenu : null }
                    Region { item: calendarMenu.opened ? calendarMenu : null }
                    Region { item: weatherMenu.opened ? weatherMenu : null }
                    Region { item: hardwareMenu.opened ? hardwareMenu : null }
                    Region { item: aiMenu.opened ? aiMenu : null }
                    Region { item: obsMenu.opened ? obsMenu : null }
                    Region { item: recordingMenu.opened ? recordingMenu : null }
                    Region { item: workspaceMenu.opened ? workspaceMenu : null }
                    Region { item: notificationCenter.opened ? notificationCenter : null }
                }

                Connections {
                    target: notificationsService
                    function onToggleRequested() {
                        bar.togglePanel(notificationCenter);
                    }
                }
                Connections {
                    target: shell
                    function onBarVisibleChanged() {
                        if (!shell.barVisible) bar.closePanels();
                    }
                }

                NotificationPopups {
                    screen: bar.screen
                    service: notificationsService
                    foreground: shell.fg
                    background: shell.barBackground()
                    accent: shell.activeBg
                    barEdge: shell.barEdge
                }

                NotificationCenter {
                    id: notificationCenter
                    service: notificationsService
                    maximumHeight: bar.screen.height - 70
                    target: shell.verticalBar ? verticalNotificationIcon : notificationIcon
                    barEdge: shell.barEdge
                    surfaceColor: shell.barBackground()
                    foreground: shell.fg
                    background: shell.workspaceMenuBg
                    accent: shell.activeBg
                }

                IpcHandler {
                    target: "panels"
                    function inspect(): string {
                        return JSON.stringify(bar.dockPanels.map(panel => ({name: panel.toString(), visible: panel.visible,
                            x: panel.x, y: panel.y, width: panel.width, height: panel.height,
                            progress: panel.revealProgress, opened: panel.opened,
                            parent: String(panel.parent), host: String(panel.hostWindow)})));
                    }
                    function close(): void {
                        bar.closePanels();
                    }
                    function show(kind: string): void {
                        var panels = {wifi: wifiMenu, bluetooth: bluetoothMenu, brightness: brightnessMenu, display: brightnessMenu, volume: volumeMenu,
                            mic: micMenu, keyboard: keyboardMenu, calendar: calendarMenu,
                            weather: weatherMenu, hardware: hardwareMenu, ai: aiMenu, obs: obsMenu,
                            workspace: workspaceMenu, recording: recordingMenu, notifications: notificationCenter};
                        if (!panels[kind]) return;
                        bar.showPanel(panels[kind]);
                    }
                }

                anchors {
                    top: shell.barEdge === "top" || shell.verticalBar
                    bottom: shell.barEdge === "bottom" || shell.verticalBar
                    left: shell.barEdge === "top" || shell.barEdge === "bottom" || shell.barEdge === "left"
                    right: shell.barEdge === "top" || shell.barEdge === "bottom" || shell.barEdge === "right"
                }

                Item {
                    id: barContents
                    width: shell.verticalBar ? Math.ceil(Math.max(60, barWeather.width + 8)) : bar.width
                    height: shell.verticalBar ? bar.height : shell.barHeight
                    x: shell.barEdge === "right" ? bar.width - width : 0
                    y: shell.barEdge === "bottom" ? bar.height - height : 0

                PanelWindow {
                    screen: bar.screen
                    visible: shell.dragCandidate !== ""
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.namespace: "desktop-bar-edge-preview"
                    WlrLayershell.layer: WlrLayer.Overlay
                    mask: Region {}
                    anchors { top: true; bottom: true; left: true; right: true }
                    Rectangle {
                        readonly property bool vertical: shell.dragCandidate === "left" || shell.dragCandidate === "right"
                        x: shell.dragCandidate === "right" ? parent.width - width : 0
                        y: shell.dragCandidate === "bottom" ? parent.height - height : 0
                        width: vertical ? 60 : parent.width
                        height: vertical ? parent.height : shell.barHeight
                        radius: 6
                        color: Qt.alpha(shell.workspaceMenuBg, 0.65)
                        border.width: 1
                        border.color: shell.activeBg
                    }
                }

                Rectangle {
                    id: verticalSurface
                    anchors.fill: parent
                    visible: shell.verticalBar
                    color: shell.barLayout === "unified" ? shell.barBackground() : "transparent"

                    BarSection {
                        id: verticalStartBackground
                        edge: shell.barEdge
                        background: shell.barBackground()
                        visible: shell.barLayout === "split"
                        x: 0; y: 0; width: parent.width
                        height: verticalStart.y + verticalStart.height + 6
                    }
                    BarSection {
                        id: verticalMiddleBackground
                        edge: shell.barEdge
                        background: shell.barBackground()
                        visible: shell.barLayout === "split"
                        x: 0; y: verticalMiddle.y - (mediaStrip.player ? 83 : 6); width: parent.width
                        height: verticalMiddle.height + 33 + (mediaStrip.player ? 83 : 6)
                    }
                    BarSection {
                        id: verticalEndBackground
                        edge: shell.barEdge
                        background: shell.barBackground()
                        visible: shell.barLayout === "split"
                        x: 0; y: verticalEnd.y - 6; width: parent.width
                        height: parent.height - y
                    }
                    BarGestureArea {
                        anchors.fill: parent
                        hostWindow: bar
                        edge: shell.barEdge
                        onCandidateChanged: shell.dragCandidate = candidate
                        onDoubleTapped: function(button) { shell.barDoubleClick(button) }
                        onDropped: function(edge) { shell.updateBarSetting("edge", edge) }
                    }

                    Column {
                        id: verticalStart
                        y: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 9
                        Column {
                            id: verticalWorkspaces
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3
                            Repeater {
                                model: 4
                                BarButton {
                                    text: shell.workspaceLabel(index)
                                    tooltip: active ? "" : shell.workspaceApps(index + 1)
                                    visualStyle: shell.workspaceStyle
                                    active: shell.workspaceActive(index + 1)
                                    width: 23; buttonHeight: 20; fontSize: 14; cornerRadius: 6; textOffsetY: -1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    onClicked: shell.run("hyprctl dispatch 'hl.dsp.focus({ workspace = " + (index + 1) + " })'")
                                    onRightClicked: bar.togglePanel(workspaceMenu)
                                }
                            }
                        }
                        Column {
                            id: verticalHardware
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2
                            VerticalBarIcon { id: verticalHardwareIcon; icon: "󰍛"; iconSize: 18; tooltip: "Hardware"; open: true; clickable: true; onClicked: bar.togglePanel(hardwareMenu) }
                            VerticalBarIcon { id: verticalAiIcon; icon: "󱜙"; iconSize: 18; tooltip: "AI Usage"; open: true; clickable: true; onClicked: bar.togglePanel(aiMenu) }
                        }
                    }

                    Item {
                        id: verticalMiddle
                        anchors.centerIn: parent
                        width: parent.width
                        height: 40
                        Column {
                            anchors.bottom: verticalCalendarIcon.top
                            anchors.bottomMargin: 3
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2
                            visible: mediaStrip.player !== null
                            VerticalBarIcon {
                                icon: "󰒮"; tooltip: "Previous"; open: true
                                clickable: !!mediaStrip.player && mediaStrip.player.canGoPrevious
                                onClicked: mediaStrip.player.previous()
                            }
                            VerticalBarIcon {
                                icon: mediaStrip.playing ? "󰏤" : "󰐊"; tooltip: mediaStrip.title; open: true
                                clickable: !!mediaStrip.player && mediaStrip.player.canTogglePlaying
                                onClicked: mediaStrip.player.togglePlaying()
                            }
                            VerticalBarIcon {
                                icon: "󰒭"; tooltip: "Next"; open: true
                                clickable: !!mediaStrip.player && mediaStrip.player.canGoNext
                                onClicked: mediaStrip.player.next()
                            }
                        }
                        ClockButton {
                            id: verticalCalendarIcon
                            anchors.centerIn: parent
                            compact: true
                            onClicked: bar.togglePanel(calendarMenu)
                        }
                        WeatherWidget {
                            id: verticalWeatherIcon
                            anchors.top: verticalCalendarIcon.bottom
                            anchors.topMargin: 3
                            anchors.horizontalCenter: parent.horizontalCenter
                            autoRefresh: false
                            compact: true
                            text: barWeather.text
                            temp: barWeather.temp
                            recording: obsMenu.obsState.recording
                            recordingPaused: obsMenu.obsState.paused
                            onRecordingClicked: bar.togglePanel(recordingMenu)
                            onClicked: bar.togglePanel(weatherMenu)
                        }
                    }

                    Column {
                        id: verticalEnd
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        VerticalBarIcon {
                            icon: shell.statusOpen ? "⌄" : "⌃"
                            tooltip: shell.statusOpen ? "Hide icons" : "Show icons"
                            open: true; clickable: true
                            onClicked: shell.statusOpen = !shell.statusOpen
                        }
                        StatusCommand {
                            id: verticalWifiIcon
                            script: "$HOME/.config/quickshell/desktop-bar/scripts/wifi-status.sh"
                            hoverLabel: "WiFi"; fontSize: 16; interval: 3000
                            open: shell.statusOpen; height: open ? 24 : 0; fixedWidth: 56; clickable: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            onClicked: bar.togglePanel(wifiMenu)
                        }
                        VerticalBarIcon { id: verticalBluetoothIcon; icon: "󰂯"; tooltip: "Bluetooth"; open: shell.statusOpen; clickable: true; onClicked: bar.togglePanel(bluetoothMenu) }
                        VerticalBarIcon { id: verticalDisplayIcon; icon: "󰍹"; tooltip: "Display"; open: shell.statusOpen; clickable: true; onClicked: bar.togglePanel(brightnessMenu) }
                        VerticalBarIcon { id: verticalVolumeIcon; icon: ""; tooltip: "Volume"; open: shell.statusOpen; clickable: true; onClicked: bar.togglePanel(volumeMenu) }
                        VerticalBarIcon { id: verticalMicIcon; icon: "󰍬"; tooltip: "Mic"; open: shell.statusOpen; clickable: true; onClicked: bar.togglePanel(micMenu) }
                        VerticalBarIcon { id: verticalKeyboardIcon; icon: "󰌌"; tooltip: "Keyboard"; open: shell.statusOpen; clickable: true; onClicked: bar.togglePanel(keyboardMenu) }
                        VerticalBarIcon { icon: shell.idleLockEnabled ? "󱫗" : "󱫖"; tooltip: "Idle Lock"; open: shell.statusOpen; clickable: true; onClicked: if (!toggleIdleLock.running) toggleIdleLock.running = true }
                        VerticalBarIcon { id: verticalObsIcon; icon: obsMenu.obsState.recording ? (obsMenu.obsState.paused ? "󰏤" : "󰑋") : "󰻂"; iconSize: obsMenu.obsState.recording && !obsMenu.obsState.paused ? 22 : 16; tooltip: obsMenu.obsState.recording ? (obsMenu.obsState.paused ? "Recording paused" : "Recording") : "OBS Studio"; open: shell.statusOpen; clickable: true; onClicked: bar.togglePanel(obsMenu) }
                        VerticalBarIcon {
                            id: verticalNotificationIcon
                            icon: notificationIcon.text; tooltip: "Notifications"; open: true; clickable: true
                            onClicked: notificationsService.toggleRequested()
                        }
                    }
                }

                Rectangle {
                    id: surface
                    anchors.fill: parent
                    visible: !shell.verticalBar
                    color: shell.barLayout === "unified" ? shell.barBackground() : "transparent"

                    BarSection {
                        id: leftBackground
                        edge: shell.barEdge
                        background: shell.barBackground()
                        visible: shell.barLayout === "split"
                        x: 0
                        y: 0
                        width: hardwareStatus.x + hardwareStatus.width + 11
                        height: parent.height
                    }
                    BarSection {
                        id: middleBackground
                        edge: shell.barEdge
                        background: shell.barBackground()
                        visible: shell.barLayout === "split"
                        x: mediaStrip.visible ? mediaStrip.x - 18 : centerInfo.x - 18
                        y: 0
                        width: barWeather.x + barWeather.width + 18 - x
                        height: parent.height
                    }
                    BarSection {
                        id: rightBackground
                        edge: shell.barEdge
                        background: shell.barBackground()
                        visible: shell.barLayout === "split"
                        x: rightSide.x - 9
                        y: 0
                        width: parent.width - x
                        height: parent.height
                    }

                    BarGestureArea {
                        id: barGestures
                        anchors.fill: parent
                        hostWindow: bar
                        edge: shell.barEdge
                        onCandidateChanged: shell.dragCandidate = candidate
                        onDoubleTapped: function(button) { shell.barDoubleClick(button) }
                        onDropped: function(edge) { shell.updateBarSetting("edge", edge) }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 9
                        spacing: 0

                        Row {
                            id: workspaces

                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: 4

                                BarButton {
                                    text: shell.workspaceLabel(index)
                                    tooltip: active ? "" : shell.workspaceApps(index + 1)
                                    visualStyle: shell.workspaceStyle
                                    active: shell.workspaceActive(index + 1)
                                    width: 23
                                    buttonHeight: 20
                                    fontSize: 14
                                    cornerRadius: 6
                                    textOffsetY: -1
                                    onClicked: shell.run("hyprctl dispatch 'hl.dsp.focus({ workspace = " + (index + 1) + " })'")
                                    onRightClicked: bar.togglePanel(workspaceMenu)
                                }

                            }

                            WorkspaceStyleMenu {
                                id: workspaceMenu
                                surfaceColor: shell.barBackground()
                                target: shell.verticalBar ? verticalWorkspaces : workspaces
                                barEdge: shell.barEdge
                                currentStyle: shell.workspaceStyle
                                accent: shell.activeBg
                                foreground: shell.workspaceMenuFg
                                background: shell.workspaceMenuBg
                                selectedForeground: shell.activeFg
                                onSelected: function(style) {
                                    shell.workspaceStyle = style;
                                    saveWorkspaceStyle.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/workspace-style.py", style];
                                    saveWorkspaceStyle.running = true;
                                }
                            }

                        }

                        Row {
                            id: hardwareStatus
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: 12
                            spacing: 6

                            StatusIcon {
                                id: hardwareIcon
                                icon: "󰍛"
                                iconSize: 18
                                tooltip: "Hardware"
                                open: true
                                clickable: true
                                onClicked: bar.togglePanel(hardwareMenu)
                            }

                            StatusIcon {
                                id: aiIcon
                                icon: "󱜙"
                                iconSize: 18
                                tooltip: "AI Usage"
                                open: true
                                clickable: true
                                onClicked: bar.togglePanel(aiMenu)
                            }
                        }

                        SystemMonitorMenu {
                            id: hardwareMenu
                            surfaceColor: shell.barBackground()
                            maximumHeight: bar.screen.height - 70
                            target: shell.verticalBar ? verticalHardwareIcon : hardwareIcon
                            barEdge: shell.barEdge
                            accent: shell.activeBg
                            foreground: shell.fg
                            background: shell.workspaceMenuBg
                        }

                        AiUsageMenu {
                            id: aiMenu
                            surfaceColor: shell.barBackground()
                            maximumHeight: bar.screen.height - 70
                            leftAligned: true
                            target: shell.verticalBar ? verticalAiIcon : aiIcon
                            barEdge: shell.barEdge
                            accent: shell.activeBg
                            foreground: shell.fg
                            background: shell.workspaceMenuBg
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                    }

                        Row {
                            id: rightSide

                            spacing: 6
                            anchors.right: notificationIcon.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter

                            StatusIcon {
                                id: statusToggle
                                tooltip: shell.statusOpen ? "Hide icons" : "Show icons"

                                icon: shell.statusOpen ? "›" : "‹"
                                open: true
                                clickable: true
                                iconSize: 21
                                glyphOffsetY: -1
                                onClicked: shell.statusOpen = !shell.statusOpen
                            }

                            StatusCommand {
                                id: wifiIcon
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/wifi-status.sh"
                                hoverLabel: "WiFi"
                                fontSize: 16
                                interval: 3000
                                open: shell.statusOpen
                                slotWidth: 28
                                clickable: true
                                onClicked: bar.togglePanel(wifiMenu)
                                onOpenChanged: if (!open) wifiMenu.opened = false
                            }

                            WifiMenu {
                                id: wifiMenu
                                surfaceColor: shell.barBackground()
                                target: shell.verticalBar ? verticalWifiIcon : (shell.statusOpen ? wifiIcon : notificationIcon)
                                barEdge: shell.barEdge
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                            StatusIcon {
                                id: bluetoothIcon
                                icon: "󰂯"
                                tooltip: "Bluetooth"
                                open: shell.statusOpen
                                clickable: true
                                onClicked: bar.togglePanel(bluetoothMenu)
                                onOpenChanged: if (!open) bluetoothMenu.opened = false
                            }

                            BluetoothMenu {
                                id: bluetoothMenu
                                surfaceColor: shell.barBackground()
                                target: shell.verticalBar ? verticalBluetoothIcon : (shell.statusOpen ? bluetoothIcon : notificationIcon)
                                barEdge: shell.barEdge
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                            StatusIcon {
                                id: brightnessIcon
                                icon: "󰍹"
                                tooltip: "Display"
                                open: shell.statusOpen
                                clickable: true
                                onClicked: bar.togglePanel(brightnessMenu)
                                onOpenChanged: if (!open) brightnessMenu.opened = false
                            }

                            BrightnessMenu {
                                id: brightnessMenu
                                surfaceColor: shell.barBackground()
                                target: shell.verticalBar ? verticalDisplayIcon : (shell.statusOpen ? brightnessIcon : notificationIcon)
                                barEdge: shell.barEdge
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                                onPrimarySelected: function(name) { shell.primaryDisplay = name }
                            }

                            StatusIcon {
                                id: volumeIcon
                                icon: ""
                                tooltip: "Volume"
                                open: shell.statusOpen
                                clickable: true
                                onClicked: bar.togglePanel(volumeMenu)
                                onOpenChanged: if (!open) volumeMenu.opened = false
                            }

                            AudioMenu {
                                id: volumeMenu
                                surfaceColor: shell.barBackground()
                                maximumHeight: bar.screen.height - 70
                                target: shell.verticalBar ? verticalVolumeIcon : (shell.statusOpen ? volumeIcon : notificationIcon)
                                barEdge: shell.barEdge
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                            StatusIcon {
                                id: micIcon
                                icon: "󰍬"
                                iconSize: 18
                                tooltip: "Mic"
                                open: shell.statusOpen
                                clickable: true
                                onClicked: bar.togglePanel(micMenu)
                                onOpenChanged: if (!open) micMenu.opened = false
                            }

                            AudioMenu {
                                id: micMenu
                                surfaceColor: shell.barBackground()
                                maximumHeight: bar.screen.height - 70
                                target: shell.verticalBar ? verticalMicIcon : (shell.statusOpen ? micIcon : notificationIcon)
                                barEdge: shell.barEdge
                                microphone: true
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                            StatusIcon {
                                id: keyboardIcon
                                icon: "󰌌"
                                iconSize: 18
                                tooltip: "Keyboard"
                                open: shell.statusOpen
                                clickable: true
                                onClicked: bar.togglePanel(keyboardMenu)
                                onOpenChanged: if (!open) keyboardMenu.opened = false
                            }

                            KeyboardLayoutMenu {
                                id: keyboardMenu
                                surfaceColor: shell.barBackground()
                                target: shell.verticalBar ? verticalKeyboardIcon : (shell.statusOpen ? keyboardIcon : notificationIcon)
                                barEdge: shell.barEdge
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                            StatusIcon {
                                id: idleLockIcon
                                icon: shell.idleLockEnabled ? "󱫗" : "󱫖"
                                iconSize: 17
                                tooltip: shell.idleLockEnabled ? "Idle Lock: On" : "Idle Lock: Off"
                                open: shell.statusOpen
                                clickable: true
                                onClicked: if (!toggleIdleLock.running) toggleIdleLock.running = true
                            }

                            StatusIcon {
                                id: obsIcon
                                icon: obsMenu.obsState.recording ? (obsMenu.obsState.paused ? "󰏤" : "󰑋") : "󰻂"
                                iconSize: obsMenu.obsState.recording && !obsMenu.obsState.paused ? 22 : 16
                                tooltip: obsMenu.obsState.recording ? (obsMenu.obsState.paused ? "Recording paused" : "Recording") : "OBS Studio"
                                open: shell.statusOpen
                                clickable: true
                                rightClickable: true
                                onClicked: bar.togglePanel(obsMenu)
                                onOpenChanged: if (!open) obsMenu.opened = false
                            }

                            ObsMenu {
                                id: obsMenu
                                surfaceColor: shell.barBackground()
                                onCaptureStarting: recordingMenu.opened = false
                                target: shell.verticalBar ? verticalObsIcon : obsIcon
                                barEdge: shell.barEdge
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                            RecordingMenu {
                                id: recordingMenu
                                surfaceColor: shell.barBackground()
                                controller: obsMenu
                                target: shell.verticalBar ? verticalWeatherIcon.recordingTarget : barWeather.recordingTarget
                                barEdge: shell.barEdge
                                centered: true
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                        }

                    NotificationWidget {
                        id: notificationIcon
                        visible: !shell.verticalBar
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ClockButton {
                        id: centerInfo
                        anchors.centerIn: parent
                        onClicked: bar.togglePanel(calendarMenu)
                    }

                    MediaStrip {
                        id: mediaStrip
                        anchors.right: centerInfo.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        availableWidth: Math.max(0, centerInfo.x - hardwareStatus.mapToItem(centerInfo.parent, hardwareStatus.width, 0).x - 24)
                        foreground: shell.fg
                        background: shell.workspaceMenuBg
                    }

                    WeatherWidget {
                        id: barWeather
                        recording: obsMenu.obsState.recording
                        recordingPaused: obsMenu.obsState.paused
                        onRecordingClicked: bar.togglePanel(recordingMenu)
                        anchors.left: centerInfo.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: bar.togglePanel(weatherMenu)
                    }

                    CalendarMenu {
                        id: calendarMenu
                        surfaceColor: shell.barBackground()
                        target: shell.verticalBar ? verticalCalendarIcon : centerInfo
                        barEdge: shell.barEdge
                        centered: true
                        accent: shell.activeBg
                        foreground: shell.fg
                        background: shell.workspaceMenuBg
                    }

                    WeatherMenu {
                        id: weatherMenu
                        surfaceColor: shell.barBackground()
                        defaultWeatherData: barWeather.latestData
                        target: shell.verticalBar ? verticalWeatherIcon : centerInfo
                        barEdge: shell.barEdge
                        centered: true
                        accent: shell.activeBg
                        foreground: shell.fg
                        background: shell.workspaceMenuBg
                        onDefaultWeatherUpdated: function(data) { barWeather.updateData(data); }
                    }

                }

                }

            }

        }

    }

    component BarButton: Rectangle {
        id: button

        property string text: ""
        property string tooltip: ""
        property bool active: false
        property int fontSize: 15
        property int buttonHeight: 24
        property int cornerRadius: 7
        property int textOffsetY: 0
        property string visualStyle: "Numbers"

        signal clicked()
        signal rightClicked()

        width: 24
        height: buttonHeight
        radius: cornerRadius
        color: visualStyle === "Numbers" ? (active ? shell.activeBg : (mouse.containsMouse ? shell.hoverBg : "transparent")) : "transparent"

        WorkspaceMarker {
            anchors.fill: parent
            style: button.visualStyle
            label: button.text
            active: button.active
            accent: shell.activeBg
            foreground: shell.fg
            selectedForeground: shell.activeFg
            fontSize: button.fontSize
            textOffsetY: button.textOffsetY
        }


        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onEntered: Hyprland.refreshToplevels()
            onClicked: function(event) {
                if (event.button === Qt.RightButton) button.rightClicked();
                else button.clicked();
            }
        }

        BarTooltip {
            target: button
            hovered: mouse.containsMouse && !button.active
            text: button.tooltip
            foreground: shell.fg
            background: shell.workspaceMenuBg
        }

        Behavior on color {
            ColorAnimation {
                duration: 120
            }

        }

    }

    component StatusIcon: Item {
        id: item

        property string icon: ""
        property string imageIcon: ""
        property string tooltip: ""
        property string detail: ""
        property string command: ""
        property bool open: true
        property bool clickable: false
        property bool rightClickable: false
        property int iconSize: 15
        property int glyphOffsetY: 0
        property int slotWidth: 28

        signal clicked()

        width: open ? slotWidth : 0
        height: 24
        opacity: open ? 1 : 0
        clip: true

        Row {
            id: content

            anchors.centerIn: parent
            spacing: 3
            leftPadding: 4
            rightPadding: 4

            Text {
                text: item.icon
                visible: item.imageIcon === ""
                y: item.glyphOffsetY
                color: shell.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: item.iconSize
                font.bold: true
            }

            Image {
                visible: item.imageIcon !== ""
                source: item.imageIcon
                width: item.iconSize
                height: item.iconSize
                sourceSize.width: item.iconSize
                sourceSize.height: item.iconSize
            }

            Text {
                visible: item.detail !== ""
                text: item.detail
                color: shell.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.bold: true
            }

        }

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            enabled: item.open && (item.clickable || item.command !== "")
            acceptedButtons: item.rightClickable ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (item.command !== "")
                    shell.run(item.command);

                item.clicked();
            }
        }

        BarTooltip {
            background: shell.workspaceMenuBg
            foreground: shell.fg
            target: item
            hovered: iconMouse.containsMouse && item.open
            text: item.tooltip
        }

        Behavior on width {
            NumberAnimation {
                duration: 180
                easing.type: Easing.InOutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.InOutCubic
            }

        }

    }

    component VerticalBarIcon: StatusIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        height: open ? 24 : 0
    }

    component StatusCommand: Item {
        id: item

        property string script: ""
        property string hoverLabel: script.indexOf("gpu-") !== -1 ? "GPU" : script.indexOf("cpu-") !== -1 ? "CPU" : "RAM"
        property string command: ""
        property bool clickable: false
        signal clicked()
        property bool open: true
        property int interval: 5000
        property string text: ""
        property string tooltip: ""
        property int slotWidth: 44
        property int fixedWidth: 0
        property int fontSize: 13

        function refresh() {
            if (process.running)
                return ;

            process.command = ["bash", "-lc", item.script];
            process.running = true;
        }

        function parse(raw) {
            var value = String(raw || "").trim();
            if (value === "")
                return ;

            try {
                var parsed = JSON.parse(value.split("\n").pop());
                item.text = String(parsed.text || "");
                item.tooltip = String(parsed.tooltip || "");
            } catch (e) {
                item.text = value;
                item.tooltip = "";
            }
        }

        width: open ? (fixedWidth > 0 ? fixedWidth : Math.max(slotWidth, label.implicitWidth + 8)) : 0
        height: 24
        opacity: open ? 1 : 0
        clip: true
        Component.onCompleted: refresh()

        Text {
            id: label

            anchors.centerIn: parent
            text: item.text
            textFormat: Text.RichText
            color: shell.fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: item.fontSize
            font.bold: true
        }

        MouseArea {
            id: commandMouse
            anchors.fill: parent
            enabled: item.open && (item.clickable || item.command !== "")
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                item.clicked();
                if (item.command !== "") shell.run(item.command);
            }
        }

        BarTooltip {
            background: shell.workspaceMenuBg
            foreground: shell.fg
            target: item
            hovered: commandMouse.containsMouse && item.open
            text: item.hoverLabel
        }

        Timer {
            interval: item.interval
            running: true
            repeat: true
            onTriggered: item.refresh()
        }

        Process {
            id: process

            running: false
            command: []
            onExited: item.parse(output.text)

            stdout: StdioCollector {
                id: output

                waitForEnd: true
            }

        }

        Behavior on width {
            NumberAnimation {
                duration: 180
                easing.type: Easing.InOutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.InOutCubic
            }

        }

    }

    component WeatherWidget: Item {
        id: weather
        signal clicked()
        signal recordingClicked()
        property alias recordingTarget: recordingDot
        property bool autoRefresh: true
        property bool compact: false
        property bool recording: false
        property bool recordingPaused: false

        property string text: "󰖐"
        property string location: ""
        property string condition: ""
        property string temp: ""
        property string feels: ""
        property string wind: ""
        property string humidity: ""
        property string forecast: ""
        property var latestData: ({})
        property int dataRevision: 0
        property int requestedRevision: 0

        function refresh() {
            if (process.running)
                return ;

            process.command = ["bash", "-lc", "$HOME/.config/quickshell/desktop-bar/scripts/weather-status.sh"];
            requestedRevision = dataRevision;
            process.running = true;
        }

        function updateData(data) {
            dataRevision++;
            latestData = data;
            weather.text = String(data.text || weather.text);
            weather.location = String(data.location || "");
            weather.condition = String(data.condition || "");
            weather.temp = String(data.temp || "");
            weather.feels = String(data.feels || "");
            weather.wind = String(data.wind || "");
            weather.humidity = String(data.humidity || "");
            weather.forecast = String(data.forecast || "");
        }

        function parse(raw) {
            // A panel refresh may have supplied newer data during this request.
            if (requestedRevision !== dataRevision) return;
            var value = String(raw || "").trim();
            if (value === "")
                return ;

            try {
                var data = JSON.parse(value.split("\n").pop());
                weather.updateData(data);
            } catch (e) {
                weather.text = "󰖐";
                weather.condition = "Weather unavailable";
            }
        }

        width: Math.max(26, label.implicitWidth + 8)
        height: 24
        Component.onCompleted: if (autoRefresh) refresh()

        Row {
            id: label
            anchors.centerIn: parent
            spacing: 3
            Text {
                text: weather.text.split(" ")[0]
                color: shell.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: weather.compact ? 12 : 14
                font.bold: true
            }
            Text {
                text: weather.temp || (weather.text.indexOf(" ") >= 0 ? weather.text.slice(weather.text.indexOf(" ") + 1).trim() : "")
                color: shell.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: weather.compact ? 12 : 14
                font.bold: true
            }
            Item {
                id: recordingDot
                visible: weather.recording
                width: 22
                height: label.height
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    radius: 3
                    color: weather.recordingPaused ? shell.fg : "#e05c68"
                }
                MouseArea {
                    id: recordingMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: weather.recordingClicked()
                }
                BarTooltip {
                    target: recordingDot
                    hovered: recordingMouse.containsMouse
                    text: weather.recordingPaused ? "Recording paused" : "Recording"
                    foreground: shell.fg
                    background: shell.workspaceMenuBg
                }
            }
        }

        MouseArea {
            id: weatherMouse
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: weather.recording ? label.x + recordingDot.x - label.spacing : parent.width
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: weather.clicked()
        }

        BarTooltip {
            background: shell.workspaceMenuBg
            foreground: shell.fg
            target: weather
            hovered: weatherMouse.containsMouse
            text: "Weather"
        }

        Timer {
            interval: 900000
            running: weather.autoRefresh
            repeat: true
            onTriggered: weather.refresh()
        }

        Process {
            id: process

            running: false
            command: []
            onExited: weather.parse(weatherOutput.text)

            stdout: StdioCollector {
                id: weatherOutput

                waitForEnd: true
            }

        }

    }

    component NotificationWidget: Rectangle {
        id: notifications

        readonly property bool hasNotifications: notificationsService.count > 0
        readonly property string text: notificationsService.doNotDisturb ? (hasNotifications ? "󰂠" : "󰪓") : (hasNotifications ? "󱅫" : "󰂜")
        readonly property string tooltip: notificationsService.doNotDisturb ? "Do Not Disturb" : (hasNotifications ? notificationsService.count + " notifications" : "No notifications")

        width: 28
        height: 24
        radius: 7
        color: "transparent"

        Text {
            anchors.fill: parent
            text: notifications.text
            color: shell.fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(event) {
                if (event.button === Qt.RightButton)
                    notificationsService.toggleDnd();
                else
                    notificationsService.toggleRequested();
            }
        }

        BarTooltip {
            background: shell.workspaceMenuBg
            foreground: shell.fg
            target: notifications
            hovered: mouse.containsMouse
            text: notifications.tooltip
        }

        Behavior on color {
            ColorAnimation {
                duration: 120
            }

        }

    }

    component ClockButton: Rectangle {
        id: clock

        property date now: new Date()
        property bool compact: false

        signal clicked()

        width: compact ? 54 : label.implicitWidth + 17
        height: compact ? 40 : 24
        radius: 7
        color: "transparent"

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.now = new Date()
        }

        Text {
            id: label

            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.now, clock.compact ? "hh:mm\nMMM dd" : "ddd MMM dd hh:mm AP")
            horizontalAlignment: Text.AlignHCenter
            color: shell.fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: clock.compact ? 12 : 14
            font.bold: true
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: clock.clicked()
        }

        BarTooltip {
            background: shell.workspaceMenuBg
            foreground: shell.fg
            target: clock
            hovered: mouse.containsMouse
            text: "Calendar"
        }

    }

}
