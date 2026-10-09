import QtQuick
import QtTest
import ".."

TestCase {
    id: test
    name: "NotificationGroup"
    width: 440; height: 900
    visible: true
    when: windowShown
    property int clears: 0
    Component {
        id: groupComponent
        NotificationGroup {
            width: 400
            foreground: "#ddccaa"; accent: "#88aa99"
            onToggleRequested: expanded = !expanded
            onClearRequested: test.clears++
        }
    }
    function notice(id) {
        return {id: id, appName: "Test", appIcon: "", summary: "Message " + id,
            body: "Body", image: "", urgency: 1, hasInlineReply: false,
            actions: [], dismiss: function() {}};
    }
    function test_expand_and_collapse() {
        var group = createTemporaryObject(groupComponent, test, {notifications: [notice(3), notice(2), notice(1)]});
        compare(group.displayedNotifications.length, 1);
        compare(group.displayedNotifications[0].id, 3);
        var toggle = findChild(group, "toggleNotificationGroup");
        verify(toggle.visible);
        mouseClick(toggle);
        compare(group.displayedNotifications.length, 3);
        verify(group.expanded);
        group.notifications = [notice(4), notice(3), notice(2), notice(1)];
        compare(group.displayedNotifications.length, 4);
        wait(400);
        mouseClick(toggle);
        compare(group.displayedNotifications.length, 1);
        compare(group.displayedNotifications[0].id, 4);
        mouseClick(findChild(group, "clearNotificationGroup"));
        compare(clears, 1);
    }
    function test_single_notification() {
        var group = createTemporaryObject(groupComponent, test, {notifications: [notice(1)]});
        compare(group.displayedNotifications.length, 1);
        verify(!findChild(group, "toggleNotificationGroup").visible);
    }
}
