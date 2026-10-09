import QtQuick
import QtTest
import ".."

TestCase {
    id: test
    name: "IdleLockControls"
    when: windowShown
    visible: true
    width: 400; height: 300
    property int toggles: 0
    property int locks: 0
    Component {
        id: controlsComponent
        IdleLockControls {
            width: 304
            idleEnabled: false
            busy: false
            foreground: "white"; accent: "cyan"
            onToggleRequested: test.toggles++
            onLockRequested: test.locks++
        }
    }
    function cleanup() { toggles = 0; locks = 0; }
    function test_toggle_and_manual_lock_are_independent() {
        var controls = createTemporaryObject(controlsComponent, test);
        var toggle = findChild(controls, "idleLockSwitch");
        compare(toggle.checked, false);
        mouseClick(toggle);
        compare(toggles, 1);
        compare(locks, 0);
        mouseClick(findChild(controls, "lockNowButton"));
        compare(locks, 1);
        compare(toggles, 1);
    }
    function test_backend_state_updates_do_not_toggle_idle() {
        var controls = createTemporaryObject(controlsComponent, test);
        var toggle = findChild(controls, "idleLockSwitch");
        controls.idleEnabled = true;
        compare(toggle.checked, true);
        controls.idleEnabled = false;
        compare(toggle.checked, false);
        compare(toggles, 0);
    }
    function test_busy_prevents_duplicate_requests() {
        var controls = createTemporaryObject(controlsComponent, test, {busy: true});
        mouseClick(findChild(controls, "idleLockSwitch"));
        mouseClick(findChild(controls, "lockNowButton"));
        compare(toggles, 0);
        compare(locks, 0);
    }
}
