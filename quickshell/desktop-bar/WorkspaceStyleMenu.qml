import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: menu
    required property Item target
    required property string currentStyle
    required property color accent
    required property color foreground
    required property color background
    signal selected(string style)

    visible: false
    color: "transparent"
    implicitWidth: 240
    implicitHeight: 188
    anchor.item: target
    anchor.rect.y: target.height + 8
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide
    onVisibleChanged: {
        if (visible) grabDelay.restart();
        else {
            grabDelay.stop();
            grab.active = false;
        }
    }
    Timer {
        id: grabDelay
        interval: 100
        onTriggered: if (menu.visible) grab.active = true
    }
    FontLoader { id: kanjiFont; source: "fonts/NotoSansJP.ttf" }

    HyprlandFocusGrab {
        id: grab
        windows: [menu]
        onCleared: menu.visible = false
    }

    Rectangle {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: menu.visible = false
        radius: 6
        color: menu.background
        border.color: Qt.alpha(menu.foreground, 0.18)
        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            Repeater {
                model: ["Numbers", "Glyph", "Kanji", "Aurora", "Pacman"]
                Rectangle {
                    required property string modelData
                    width: 228
                    height: 33
                    radius: 4
                    color: mouse.containsMouse ? Qt.alpha(menu.accent, 0.18) : "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 32
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: menu.foreground
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 96
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData !== "Pacman"
                        text: {
                            if (modelData === "Numbers") return "1 2 3 4";
                            if (modelData === "Glyph") return "✦ ✧ · ·";
                            if (modelData === "Kanji") return "一 二 三 四";
                            return "━ · · ·";
                        }
                        color: menu.accent
                        font.family: modelData === "Kanji" ? kanjiFont.name : "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                    Canvas {
                        visible: parent.modelData === "Pacman"
                        anchors.left: parent.left
                        anchors.leftMargin: 96
                        anchors.verticalCenter: parent.verticalCenter
                        width: 80
                        height: 16
                        property color ink: menu.accent
                        onInkChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.fillStyle = ink;
                            ctx.beginPath();
                            ctx.moveTo(8, 8);
                            ctx.arc(8, 8, 7, Math.PI / 5, Math.PI * 9 / 5);
                            ctx.closePath();
                            ctx.fill();
                            for (var x = 29; x < 80; x += 20) {
                                ctx.beginPath();
                                ctx.arc(x, 8, 2, 0, Math.PI * 2);
                                ctx.fill();
                            }
                        }
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData === menu.currentStyle ? "" : ""
                        color: menu.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            menu.selected(parent.modelData);
                            menu.visible = false;
                        }
                    }
                }
            }
        }
    }
}
