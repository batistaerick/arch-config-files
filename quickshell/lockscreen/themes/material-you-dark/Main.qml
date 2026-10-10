import QtQuick
import LockscreenComponents

// Layout and palettes live in LockscreenComponents/MaterialYouDesign.qml;
// theme.conf selects themeMode and the background image.
MaterialYouDesign {
    settings: config
    auth: typeof sddm !== "undefined" ? sddm : null
    users: typeof userModel !== "undefined" ? userModel : null
    sessions: typeof sessionModel !== "undefined" ? sessionModel : null
    keyboardState: typeof keyboard !== "undefined" ? keyboard : null
    background: Qt.resolvedUrl(config.background)
    fontSource: Qt.resolvedUrl("font/GoogleSans-VariableFont_GRAD,opsz,wght.ttf")
}
