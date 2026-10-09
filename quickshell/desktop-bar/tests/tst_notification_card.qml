import QtQuick
import QtTest
import ".."

TestCase {
    id: test
    name: "NotificationCard"
    when: windowShown
    width: 440; height: 420
    visible: true
    property int actionCalls: 0
    property int dismissCalls: 0
    property string replyText: ""
    property int activatedId: 0
    Component {
        id: cardComponent
        NotificationCard {
            width: 400
            foreground: "white"
            accent: "cyan"
            onActivated: function(notificationId) { test.activatedId = notificationId; }
        }
    }
    function notice() {
        return {id: 17, appName: "Test", appIcon: "", summary: "Message",
            body: "A notification body", image: "", urgency: 1,
            hasInlineReply: true, inlineReplyPlaceholder: "Reply",
            actions: [{identifier: "open", text: "Open", invoke: function() { test.actionCalls++; }}],
            dismiss: function() { test.dismissCalls++; },
            sendInlineReply: function(text) { test.replyText = text; }};
    }
    function cleanup() {
        actionCalls = 0; dismissCalls = 0; replyText = ""; activatedId = 0;
    }
    function test_action_and_dismiss() {
        var card = createTemporaryObject(cardComponent, test, {notification: notice()});
        verify(card);
        wait(20);
        mouseClick(findChild(card, "notificationAction_open"));
        compare(actionCalls, 1);
        compare(activatedId, 17);
        mouseClick(findChild(card, "dismissNotification"));
        compare(dismissCalls, 1);
    }
    function test_inline_reply() {
        var card = createTemporaryObject(cardComponent, test, {notification: notice()});
        var reply = findChild(card, "notificationReply");
        reply.forceActiveFocus();
        reply.text = "hello";
        keyClick(Qt.Key_Return);
        compare(replyText, "hello");
        compare(reply.text, "");
    }
    function test_image_sizes_data() {
        return [
            {tag: "small image stays native", sourceWidth: 64, sourceHeight: 48, compact: false, expectedWidth: 64, expectedHeight: 48},
            {tag: "4K image is capped", sourceWidth: 3840, sourceHeight: 2160, compact: false, expectedWidth: 160, expectedHeight: 90},
            {tag: "popup image is capped", sourceWidth: 3840, sourceHeight: 2160, compact: true, expectedWidth: 128, expectedHeight: 72},
            {tag: "portrait is capped proportionally", sourceWidth: 600, sourceHeight: 1200, compact: false, expectedWidth: 60, expectedHeight: 120},
        ];
    }
    function test_image_sizes(data) {
        var notification = notice();
        notification.image = "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="' + data.sourceWidth + '" height="' + data.sourceHeight + '"><rect width="100%" height="100%" fill="cyan"/></svg>');
        var card = createTemporaryObject(cardComponent, test, {notification: notification, compact: data.compact});
        var image = findChild(card, "notificationImage");
        tryCompare(image, "status", Image.Ready);
        compare(image.width, data.expectedWidth);
        compare(image.height, data.expectedHeight);
    }
}
