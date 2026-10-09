import QtQuick
import "PanelStyle.js" as PanelStyle

ThemedPopup {
    id: menu
    required property bool idleEnabled
    required property bool busy
    signal toggleRequested()
    signal lockRequested()
    property bool pendingLock: false
    implicitWidth: 340
    implicitHeight: controls.implicitHeight + PanelStyle.padding * 2
    onVisibleChanged: {
        if (!visible && pendingLock) {
            pendingLock = false;
            lockRequested();
        }
    }
    IdleLockControls {
        id: controls
        x: PanelStyle.padding; y: PanelStyle.padding
        width: parent.width - PanelStyle.padding * 2
        idleEnabled: menu.idleEnabled
        busy: menu.busy
        foreground: menu.foreground
        accent: menu.accent
        onToggleRequested: menu.toggleRequested()
        onLockRequested: {
            menu.pendingLock = true;
            menu.opened = false;
        }
    }
    BarTooltip {
        target: controls.lockTarget
        hovered: controls.lockHovered
        text: "Lock now"
        foreground: menu.foreground
        background: menu.background
    }
}
