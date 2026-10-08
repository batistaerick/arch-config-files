import QtQuick

PanelButton {
    id: button
    required property var controller
    required property string action
    required property string description
    foreground: controller.foreground
    icon: true
    height: 34
    available: controller.controlsReady
    onClicked: controller.run(action)
    HoverHandler { id: hover }
    BarTooltip {
        target: button
        hovered: hover.hovered
        text: button.description
        foreground: button.controller.foreground
        background: button.controller.background
    }
}
