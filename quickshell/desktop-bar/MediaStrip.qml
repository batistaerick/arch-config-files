import QtQuick
import Quickshell.Services.Mpris
import "MediaModel.js" as MediaModel

Item {
    id: media
    required property color foreground
    required property color background
    property real availableWidth: 260
    property var players: Mpris.players.values
    readonly property var eligiblePlayers: players.filter(p => p && MediaModel.eligible(p))
    readonly property var player: eligiblePlayers.find(p => p.isPlaying) || eligiblePlayers[0] || null
    readonly property bool playing: !!player && player.isPlaying
    readonly property string title: player ? [player.trackArtist, player.trackTitle].filter(Boolean).join(" - ") || player.identity : ""
    property real pulse: 0

    visible: player !== null && availableWidth >= 140
    width: visible ? controls.width + 28 + Math.max(0, Math.min(260, availableWidth) - controls.width - 28) * 0.75 : 0
    height: 24

    Row {
        id: controls
        height: parent.height
        spacing: 1
        MediaControl {
            text: "󰒮"
            tooltip: "Previous"
            available: !!media.player && media.player.canControl && media.player.canGoPrevious
            onTriggered: media.player.previous()
        }
        MediaControl {
            text: media.playing ? "󰏤" : "󰐊"
            tooltip: media.playing ? "Pause" : "Play"
            available: !!media.player && media.player.canControl && media.player.canTogglePlaying
            onTriggered: media.player.togglePlaying()
        }
        MediaControl {
            text: "󰒭"
            tooltip: "Next"
            available: !!media.player && media.player.canControl && media.player.canGoNext
            onTriggered: media.player.next()
        }
    }
    Item {
        id: titleViewport
        anchors.left: controls.right
        anchors.leftMargin: 6
        anchors.right: playbackIndicator.left
        anchors.rightMargin: 8
        height: parent.height
        clip: true
        readonly property bool scrolling: trackLabel.implicitWidth > width
        Row {
            id: ticker
            height: parent.height
            spacing: 24
            Text {
                id: trackLabel
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: media.title
                textFormat: Text.PlainText
                color: media.foreground
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                onTextChanged: { ticker.x = 0; if (titleMouse.containsMouse && titleViewport.scrolling) marquee.restart(); }
            }
            Text {
                visible: titleViewport.scrolling
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: media.title
                textFormat: Text.PlainText
                color: media.foreground
                font: trackLabel.font
            }
        }
        SequentialAnimation {
            id: marquee
            running: media.visible && titleViewport.scrolling && titleMouse.containsMouse
            loops: Animation.Infinite
            PauseAnimation { duration: 1300 }
            NumberAnimation { target: ticker; property: "x"; from: 0; to: -(trackLabel.implicitWidth + ticker.spacing); duration: Math.max(1000, (trackLabel.implicitWidth + ticker.spacing) / 28 * 1000) }
            PropertyAction { target: ticker; property: "x"; value: 0 }
            onStopped: ticker.x = 0
        }
        MouseArea {
            id: titleMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: media.player && media.player.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (media.player && media.player.canRaise) media.player.raise()
        }
    }
    Item {
        id: playbackIndicator
        anchors.right: parent.right
        width: 14
        height: parent.height
        Row {
            anchors.centerIn: parent
            height: 14
            spacing: 2
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: media.playing ? 4 + (Math.sin(media.pulse + index * 1.7) + 1) * 4 : 3
                    radius: 1
                    color: media.foreground
                    opacity: media.playing ? 1 : 0.55
                }
            }
        }
    }
    NumberAnimation on pulse { from: 0; to: Math.PI * 2; duration: 1500; loops: Animation.Infinite; running: media.visible && media.playing }

    component MediaControl: Item {
        id: control
        required property string text
        required property string tooltip
        property bool available: true
        signal triggered()
        width: 18
        height: 24
        activeFocusOnTab: true
        enabled: available
        Keys.onReturnPressed: if (available) triggered()
        Keys.onSpacePressed: if (available) triggered()
        Text {
            anchors.fill: parent
            text: control.text
            color: media.foreground
            opacity: control.available ? 1 : 0.4
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        MouseArea { id: controlMouse; anchors.fill: parent; hoverEnabled: true; enabled: control.available; cursorShape: Qt.PointingHandCursor; onClicked: control.triggered() }
        BarTooltip { target: control; hovered: controlMouse.containsMouse; text: control.tooltip; foreground: media.foreground; background: media.background }
    }
}
