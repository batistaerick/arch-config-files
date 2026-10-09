import QtQuick
import QtQuick.Controls.Basic
import "PanelStyle.js" as PanelStyle

Rectangle {
    id: card
    required property var notification
    required property color foreground
    required property color accent
    property bool compact: false
    property bool filled: true
    signal activated(int notificationId)
    function invokeAction(action) {
        var id = notification.id;
        activated(id);
        action.invoke();
    }
    implicitHeight: content.implicitHeight + 28
    radius: PanelStyle.cornerRadius
    color: filled ? Qt.alpha(foreground, 0.055) : "transparent"
    border.width: filled && notification && notification.urgency === 2 ? 1 : 0
    border.color: accent

    Column {
        id: content
        x: 14; y: 14
        width: parent.width - 28
        spacing: 10
        Row {
            width: parent.width
            spacing: 10
            Image {
                id: applicationIcon
                width: 28; height: 28
                source: card.notification && card.notification.appIcon ? (card.notification.appIcon.indexOf("/") !== -1 || card.notification.appIcon.indexOf(":") !== -1 ? card.notification.appIcon : "image://icon/" + card.notification.appIcon) : ""
                fillMode: Image.PreserveAspectFit
                Text {
                    anchors.centerIn: parent
                    visible: !card.notification || !card.notification.appIcon || applicationIcon.status === Image.Error
                    text: "󰂚"; color: card.foreground
                    font.family: PanelStyle.fontFamily; font.pixelSize: 22
                }
            }
            Column {
                width: parent.width - 28 - 30 - 20
                spacing: 3
                Text {
                    width: parent.width
                    text: card.notification ? card.notification.appName || "Application" : ""
                    textFormat: Text.PlainText
                    color: card.foreground; opacity: 0.65
                    font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: card.notification ? card.notification.summary : ""
                    textFormat: Text.PlainText
                    color: card.foreground
                    font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: card.compact ? 2 : 4
                    elide: Text.ElideRight
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var action = card.notification.actions.find(a => a.identifier === "default");
                            if (action) card.invokeAction(action);
                        }
                    }
                }
            }
            PanelButton {
                objectName: "dismissNotification"
                width: 30; height: 30
                text: "󰅖"; icon: true; compactIconBackground: true
                foreground: card.foreground
                onClicked: if (card.notification) card.notification.dismiss()
            }
        }
        Text {
            visible: text !== ""
            width: parent.width
            text: card.notification ? card.notification.body : ""
            textFormat: Text.PlainText
            color: card.foreground; opacity: 0.85
            font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize
            wrapMode: Text.Wrap
            maximumLineCount: card.compact ? 3 : 12
            elide: Text.ElideRight
        }
        Image {
            visible: source !== "" && status === Image.Ready
            width: parent.width; height: visible ? (card.compact ? 100 : 160) : 0
            source: card.notification ? card.notification.image : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: card.notification ? card.notification.actions.filter(a => a.identifier !== "default" && a.identifier !== "inline-reply") : []
                PanelButton {
                    required property var modelData
                    objectName: "notificationAction_" + modelData.identifier
                    text: modelData.text
                    width: Math.min(content.width, Math.max(90, text.length * 9 + 24))
                    height: 32
                    foreground: card.foreground
                    onClicked: card.invokeAction(modelData)
                }
            }
        }
        Row {
            visible: card.notification && card.notification.hasInlineReply
            width: parent.width; spacing: 8
            TextField {
                id: reply
                objectName: "notificationReply"
                width: parent.width - 76; height: 34
                placeholderText: card.notification ? card.notification.inlineReplyPlaceholder || "Reply…" : ""
                color: card.foreground
                font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize
                background: Rectangle { color: Qt.alpha(card.foreground, 0.08); radius: PanelStyle.controlRadius }
                onAccepted: if (text.trim()) { card.notification.sendInlineReply(text); text = ""; }
            }
            PanelButton {
                text: "Send"; height: 34; foreground: card.foreground
                available: reply.text.trim().length > 0
                onClicked: { card.notification.sendInlineReply(reply.text); reply.text = ""; }
            }
        }
    }
}
