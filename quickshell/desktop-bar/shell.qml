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

    function run(command) {
        Quickshell.execDetached(["bash", "-lc", command]);
    }

    function workspaceActive(index) {
        return Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index;
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

    onStatusOpenChanged: {
        if (statusOpen)
            statusAutoClose.restart();
        else
            statusAutoClose.stop();
    }

    Timer {
        id: statusAutoClose

        interval: 30000
        repeat: false
        onTriggered: shell.statusOpen = false
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
                                    text: String(index + 1)
                                    active: shell.workspaceActive(index + 1)
                                    width: 23
                                    buttonHeight: 20
                                    fontSize: 14
                                    cornerRadius: 6
                                    textOffsetY: -1
                                    onClicked: shell.run("hyprctl dispatch 'hl.dsp.focus({ workspace = " + (index + 1) + " })'")
                                }

                            }

                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Row {
                            id: rightSide

                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            StatusIcon {
                                id: statusToggle

                                icon: shell.statusOpen ? "›" : "‹"
                                open: true
                                clickable: true
                                iconSize: 21
                                glyphOffsetY: -1
                                onClicked: shell.statusOpen = !shell.statusOpen
                            }

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/gpu-usage.sh"
                                interval: 5000
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh system-monitor kitty --class system-monitor -e btop"
                            }

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/cpu-status.sh"
                                interval: 2000
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh system-monitor kitty --class system-monitor -e btop"
                            }

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/memory-status.sh"
                                interval: 5000
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh system-monitor kitty --class system-monitor -e btop"
                            }

                            StatusCommand {
                                script: "$HOME/.config/quickshell/desktop-bar/scripts/wifi-status.sh"
                                interval: 3000
                                open: shell.statusOpen
                                slotWidth: 28
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh setup-wifi kitty --class setup-wifi -e impala"
                            }

                            StatusIcon {
                                icon: "󰂯"
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh blueman-manager blueman-manager"
                            }

                            StatusIcon {
                                icon: ""
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh org.pulseaudio.pavucontrol pavucontrol"
                            }

                            StatusIcon {
                                icon: "󰍬"
                                open: shell.statusOpen
                                command: "$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh org.pulseaudio.pavucontrol pavucontrol"
                            }

                            NotificationWidget {
                            }

                            WeatherWidget {
                            }

                            ClockButton {
                                onClicked: shell.run("$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh dev.local.CalendarPanel $HOME/.config/quickshell/desktop-bar/scripts/calendar-panel.py")
                            }

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

        signal clicked()

        width: 24
        height: buttonHeight
        radius: cornerRadius
        color: active ? shell.activeBg : (mouse.containsMouse ? shell.hoverBg : "transparent")

        Text {
            anchors.fill: parent
            text: button.text
            color: button.active ? shell.activeFg : "#ffffff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: button.fontSize
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            y: button.textOffsetY
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
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
        property string command: ""
        property bool open: true
        property int interval: 5000
        property string text: ""
        property string tooltip: ""
        property int slotWidth: 44

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

        width: open ? Math.max(slotWidth, label.implicitWidth + 8) : 0
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
            font.pixelSize: 13
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            enabled: item.open && item.command !== ""
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: shell.run(item.command)
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
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: shell.run("$HOME/.config/quickshell/desktop-bar/scripts/open-panel.sh dev.local.WeatherPanel $HOME/.config/quickshell/desktop-bar/scripts/weather-panel.py")
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
            font.pixelSize: 15
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
        color: mouse.containsMouse ? shell.hoverBg : "transparent"

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

    }

}
