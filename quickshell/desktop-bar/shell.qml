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
    FontLoader { id: kanjiFont; source: "fonts/NotoSansJP.ttf" }

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
        if (workspaceStyle === "Kanji") return ["一", "二", "三", "四"][index];
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
                                onSelected: function(style) {
                                    shell.workspaceStyle = style;
                                    saveWorkspaceStyle.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/workspace-style.py", style];
                                    saveWorkspaceStyle.running = true;
                                }
                            }

                        }

                        Row {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: 12
                            spacing: 6

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/gpu-usage.sh"
                                fixedWidth: 56
                                interval: 5000
                                open: true
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh system-monitor kitty --class system-monitor -e btop"
                            }

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/cpu-status.sh"
                                fixedWidth: 56
                                interval: 2000
                                open: true
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh system-monitor kitty --class system-monitor -e btop"
                            }

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/memory-status.sh"
                                fixedWidth: 56
                                interval: 5000
                                open: true
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh system-monitor kitty --class system-monitor -e btop"
                            }
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
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/wifi-status.sh"
                                hoverLabel: "WiFi"
                                fontSize: 16
                                interval: 3000
                                open: shell.statusOpen
                                slotWidth: 28
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh setup-wifi kitty --class setup-wifi -e impala"
                            }

                            StatusIcon {
                                icon: "󰂯"
                                tooltip: "Bluetooth"
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh blueman-manager blueman-manager"
                            }

                            StatusIcon {
                                icon: ""
                                tooltip: "Volume"
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh org.pulseaudio.pavucontrol pavucontrol"
                            }

                            StatusIcon {
                                icon: "󰍬"
                                iconSize: 18
                                tooltip: "Mic"
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh org.pulseaudio.pavucontrol pavucontrol"
                            }

                            StatusIcon {
                                icon: "󱜙"
                                iconSize: 18
                                tooltip: "AI Usage"
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh dev.local.AiUsagePanel python3 $HOME/.config/quickshell/desktop-bar/scripts/ai-usage-panel.py"
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
                        onClicked: shell.run("$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh dev.local.CalendarPanel $HOME/.config/quickshell/desktop-bar/scripts/calendar-panel.py")
                    }

                    WeatherWidget {
                        anchors.left: centerInfo.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
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
        color: active ? shell.activeBg : (mouse.containsMouse ? shell.hoverBg : "transparent")

        Text {
            visible: button.visualStyle !== "Pacman" && button.visualStyle !== "Aurora"
            anchors.fill: parent
            text: button.text
            color: button.active ? shell.activeFg : "#ffffff"
            font.family: button.visualStyle === "Kanji" ? kanjiFont.name : "JetBrainsMono Nerd Font"
            font.pixelSize: button.fontSize
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            y: button.textOffsetY
        }

        Rectangle {
            visible: button.visualStyle === "Aurora"
            anchors.centerIn: parent
            width: button.active ? 17 : 5
            height: button.active ? 3 : 5
            radius: 3
            color: button.active ? shell.activeFg : shell.activeBg
            opacity: button.active ? 1 : 0.5
            Behavior on width { NumberAnimation { duration: 140 } }
            Behavior on height { NumberAnimation { duration: 140 } }
        }

        Canvas {
            id: pacman
            visible: button.visualStyle === "Pacman"
            anchors.centerIn: parent
            width: 16
            height: 16
            onVisibleChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = button.active ? shell.activeFg : "#ffffff";
                ctx.beginPath();
                if (button.active) {
                    ctx.moveTo(8, 8);
                    ctx.arc(8, 8, 7, Math.PI / 5, Math.PI * 9 / 5);
                    ctx.closePath();
                } else ctx.arc(8, 8, 2.5, 0, Math.PI * 2);
                ctx.fill();
            }
            Connections {
                target: button
                function onActiveChanged() { pacman.requestPaint(); }
            }
            Connections {
                target: shell
                function onActiveFgChanged() { pacman.requestPaint(); }
            }
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
                color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: item.iconSize
                font.bold: true
            }

            Text {
                visible: item.detail !== ""
                text: item.detail
                color: "#ffffff"
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
            color: "#ffffff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: item.fontSize
            font.bold: true
        }

        MouseArea {
            id: commandMouse
            anchors.fill: parent
            enabled: item.open && item.command !== ""
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: shell.run(item.command)
        }

        BarTooltip {
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

        Text {
            id: label

            anchors.centerIn: parent
            text: weather.text
            color: "#ffffff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
        }

        MouseArea {
            id: weatherMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: shell.run("$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh dev.local.WeatherPanel $HOME/.config/quickshell/desktop-bar/scripts/weather-panel.py")
        }

        BarTooltip {
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
            if (process.running)
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

        width: 28
        height: 24
        radius: 7
        color: mouse.containsMouse ? shell.hoverBg : "transparent"
        Component.onCompleted: refresh()

        Text {
            anchors.fill: parent
            text: notifications.text
            color: "#ffffff"
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
            color: "#ffffff"
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
            target: clock
            hovered: mouse.containsMouse
            text: "Calendar"
        }

    }

}
