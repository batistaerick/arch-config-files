import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: shell

    property bool statusOpen: false
    property int barHeight: 30
    property color bg: Qt.rgba(24 / 255, 24 / 255, 36 / 255, 0.38)
    property color fg: "#cdd6f4"
    property color activeFg: "#11111b"
    property color activeBg: "#cdd6f4"
    property color hoverBg: Qt.rgba(180 / 255, 190 / 255, 254 / 255, 0.15)
    property string workspaceStyle: "Numbers"
    property color workspaceMenuBg: "#181824"
    property color workspaceMenuFg: "#cdd6f4"

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

    function targetScreens() {
        var screens = Quickshell.screens || [];
        var fallback = null;
        for (var i = 0; i < screens.length; i++) {
            if (!screens[i])
                continue;

            if (screens[i].name === "HDMI-A-1")
                return [screens[i]];

            if (screens[i].name === "DP-3")
                fallback = screens[i];
            else if (!fallback)
                fallback = screens[i];
        }
        return fallback ? [fallback] : [];
    }

    Variants {
        model: shell.targetScreens()

        delegate: Component {
            PanelWindow {
                id: bar

                required property var modelData

                screen: modelData
                implicitHeight: shell.barHeight
                color: "transparent"
                exclusionMode: ExclusionMode.Auto
                WlrLayershell.namespace: "desktop-bar"
                WlrLayershell.layer: WlrLayer.Top

                anchors {
                    top: true
                    left: true
                    right: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: shell.bg

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
                                    visualStyle: shell.workspaceStyle
                                    active: shell.workspaceActive(index + 1)
                                    width: 23
                                    buttonHeight: 20
                                    fontSize: 14
                                    cornerRadius: 6
                                    textOffsetY: -1
                                    onClicked: shell.run("hyprctl dispatch 'hl.dsp.focus({ workspace = " + (index + 1) + " })'")
                                    onRightClicked: workspaceMenu.visible = !workspaceMenu.visible
                                }

                            }

                            WorkspaceStyleMenu {
                                id: workspaceMenu
                                target: workspaces
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
                            spacing: 2

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/gpu-usage.sh"
                                fixedWidth: 56
                                interval: 5000
                                open: true
                                clickable: true
                                onClicked: hardwareMenu.visible = !hardwareMenu.visible
                            }

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/cpu-status.sh"
                                fixedWidth: 56
                                interval: 2000
                                open: true
                                clickable: true
                                onClicked: hardwareMenu.visible = !hardwareMenu.visible
                            }

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/memory-status.sh"
                                fixedWidth: 56
                                interval: 5000
                                open: true
                                clickable: true
                                onClicked: hardwareMenu.visible = !hardwareMenu.visible
                            }
                        }

                        SystemMonitorMenu {
                            id: hardwareMenu
                            target: hardwareStatus
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
                                onClicked: wifiMenu.visible = !wifiMenu.visible
                                onOpenChanged: if (!open) wifiMenu.visible = false
                            }

                            WifiMenu {
                                id: wifiMenu
                                target: wifiIcon
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
                                onClicked: bluetoothMenu.visible = !bluetoothMenu.visible
                                onOpenChanged: if (!open) bluetoothMenu.visible = false
                            }

                            BluetoothMenu {
                                id: bluetoothMenu
                                target: bluetoothIcon
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                            StatusIcon {
                                id: volumeIcon
                                icon: ""
                                tooltip: "Volume"
                                open: shell.statusOpen
                                clickable: true
                                onClicked: volumeMenu.visible = !volumeMenu.visible
                                onOpenChanged: if (!open) volumeMenu.visible = false
                            }

                            AudioMenu {
                                id: volumeMenu
                                maximumHeight: bar.screen.height - 70
                                target: volumeIcon
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
                                onClicked: micMenu.visible = !micMenu.visible
                                onOpenChanged: if (!open) micMenu.visible = false
                            }

                            AudioMenu {
                                id: micMenu
                                maximumHeight: bar.screen.height - 70
                                target: micIcon
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
                                onClicked: keyboardMenu.visible = !keyboardMenu.visible
                                onOpenChanged: if (!open) keyboardMenu.visible = false
                            }

                            KeyboardLayoutMenu {
                                id: keyboardMenu
                                target: keyboardIcon
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                            StatusIcon {
                                id: aiIcon
                                icon: "󱜙"
                                iconSize: 18
                                tooltip: "AI Usage"
                                open: shell.statusOpen
                                clickable: true
                                onClicked: aiMenu.visible = !aiMenu.visible
                                onOpenChanged: if (!open) aiMenu.visible = false
                            }

                            AiUsageMenu {
                                id: aiMenu
                                maximumHeight: bar.screen.height - 70
                                target: aiIcon
                                accent: shell.activeBg
                                foreground: shell.fg
                                background: shell.workspaceMenuBg
                            }

                        }

                    NotificationWidget {
                        id: notificationIcon
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ClockButton {
                        id: centerInfo
                        anchors.centerIn: parent
                        onClicked: calendarMenu.visible = !calendarMenu.visible
                    }

                    WeatherWidget {
                        anchors.left: centerInfo.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: weatherMenu.visible = !weatherMenu.visible
                    }

                    CalendarMenu {
                        id: calendarMenu
                        target: centerInfo
                        centered: true
                        accent: shell.activeBg
                        foreground: shell.fg
                        background: shell.workspaceMenuBg
                    }

                    WeatherMenu {
                        id: weatherMenu
                        target: centerInfo
                        centered: true
                        accent: shell.activeBg
                        foreground: shell.fg
                        background: shell.workspaceMenuBg
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
            onClicked: function(event) {
                if (event.button === Qt.RightButton) button.rightClicked();
                else button.clicked();
            }
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
        property string tooltip: ""
        property string detail: ""
        property string command: ""
        property bool open: true
        property bool clickable: false
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
                y: item.glyphOffsetY
                color: shell.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: item.iconSize
                font.bold: true
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

        property string text: "󰖐"
        property string location: ""
        property string condition: ""
        property string temp: ""
        property string feels: ""
        property string wind: ""
        property string humidity: ""
        property string forecast: ""

        function refresh() {
            if (process.running)
                return ;

            process.command = ["bash", "-lc", "$HOME/.config/quickshell/desktop-bar/scripts/weather-status.sh"];
            process.running = true;
        }

        function parse(raw) {
            var value = String(raw || "").trim();
            if (value === "")
                return ;

            try {
                var data = JSON.parse(value.split("\n").pop());
                weather.text = String(data.text || weather.text);
                weather.location = String(data.location || "");
                weather.condition = String(data.condition || "");
                weather.temp = String(data.temp || "");
                weather.feels = String(data.feels || "");
                weather.wind = String(data.wind || "");
                weather.humidity = String(data.humidity || "");
                weather.forecast = String(data.forecast || "");
            } catch (e) {
                weather.text = "󰖐";
                weather.condition = "Weather unavailable";
            }
        }

        width: Math.max(26, label.implicitWidth + 8)
        height: 24
        Component.onCompleted: refresh()

        Row {
            id: label
            anchors.centerIn: parent
            spacing: 3
            Text {
                text: weather.text.split(" ")[0]
                color: shell.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                text: weather.temp || (weather.text.indexOf(" ") >= 0 ? weather.text.slice(weather.text.indexOf(" ") + 1).trim() : "")
                color: shell.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.bold: true
            }
        }

        MouseArea {
            id: weatherMouse
            anchors.fill: parent
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
            running: true
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

        property string text: "󰂜"
        property string tooltip: "No notifications"
        property bool hasNotifications: false

        function refresh() {
            if (notificationEvents.running || process.running)
                return ;

            process.command = ["bash", "-lc", "$HOME/.config/quickshell/desktop-bar/scripts/notifications-status.sh"];
            process.running = true;
        }

        function parse(raw) {
            var value = String(raw || "").trim();
            if (value === "")
                return ;

            try {
                var data = JSON.parse(value.split("\n").pop());
                notifications.text = String(data.text || "󰂜");
                notifications.tooltip = String(data.tooltip || "");
                notifications.hasNotifications = data.active === true;
            } catch (e) {
                notifications.text = "󰂜";
                notifications.tooltip = "Notifications unavailable";
                notifications.hasNotifications = false;
            }
        }

        function subscription(raw) {
            try {
                var data = JSON.parse(raw);
                var count = Number(data.text || 0);
                var icons = {none: "󰂜", notification: "󱅫", "dnd-none": "󰪓", "dnd-notification": "󰂠", "inhibited-none": "󰪑", "inhibited-notification": "󰂛", "dnd-inhibited-none": "󰪑", "dnd-inhibited-notification": "󰂛"};
                notifications.text = icons[data.alt] || (count > 0 ? "󱅫" : "󰂜");
                notifications.hasNotifications = count > 0;
                notifications.tooltip = count > 0 ? count + " notifications" : "No notifications";
            } catch (e) {}
        }

        width: 28
        height: 24
        radius: 7
        color: mouse.containsMouse ? shell.hoverBg : "transparent"
        Component.onCompleted: refresh()

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
                    shell.run("swaync-client -d -sw");
                else
                    shell.run("swaync-client -t -sw");
                refreshAfterClick.restart();
            }
        }

        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: notifications.refresh()
        }

        Timer {
            id: refreshAfterClick

            interval: 350
            repeat: false
            onTriggered: notifications.refresh()
        }

        BarTooltip {
            background: shell.workspaceMenuBg
            foreground: shell.fg
            target: notifications
            hovered: mouse.containsMouse
            text: "Notifications"
        }

        Process {
            id: process

            running: false
            command: []
            onExited: notifications.parse(notificationOutput.text)

            stdout: StdioCollector {
                id: notificationOutput

                waitForEnd: true
            }

        }

        Process {
            id: notificationEvents
            command: ["swaync-client", "-swb"]
            running: true
            stdout: SplitParser { onRead: data => notifications.subscription(data) }
            onExited: reconnectEvents.restart()
        }
        Timer { id: reconnectEvents; interval: 2000; onTriggered: notificationEvents.running = true }

        Behavior on color {
            ColorAnimation {
                duration: 120
            }

        }

    }

    component ClockButton: Rectangle {
        id: clock

        property date now: new Date()

        signal clicked()

        width: label.implicitWidth + 17
        height: 24
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
            text: Qt.formatDateTime(clock.now, "ddd MMM dd hh:mm AP")
            color: shell.fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
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
