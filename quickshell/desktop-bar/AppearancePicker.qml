import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: picker
    property bool opened: false
    property string mode: "wallpaper"
    property var targetScreen: null
    property var items: []
    property int selectedIndex: 0
    property color accent: "#cdd6f4"
    property color foreground: "#ffffff"
    property string error: ""

    function open(kind, screen) {
        if (loader.running)
            return;
        mode = kind === "theme" ? "theme-category" : kind;
        targetScreen = screen;
        items = [];
        error = "";
        opened = true;
        loader.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/appearance-items.py", mode];
        loader.running = true;
    }

    function navigate(delta) {
        if (items.length)
            selectedIndex = (selectedIndex + delta + items.length) % items.length;
    }

    function apply() {
        if (!items.length || applyProcess.running)
            return;
        if (mode === "theme-category") {
            open("theme-" + items[selectedIndex].value, targetScreen);
            return;
        }
        var script = mode.startsWith("theme-") ? "style/apply.sh" : "wallpaper/apply.sh";
        applyProcess.command = [Quickshell.env("HOME") + "/.config/walker/scripts/actions/" + script, items[selectedIndex].value];
        opened = false;
        applyProcess.running = true;
    }

    function back() {
        if (mode === "theme-dark" || mode === "theme-light")
            open("theme", targetScreen);
        else
            opened = false;
    }

    Process {
        id: loader
        stdout: StdioCollector { id: output }
        onExited: function(code) {
            try {
                if (code !== 0)
                    throw new Error("load failed");
                var data = JSON.parse(output.text);
                picker.items = data.items;
                picker.accent = data.accent;
                picker.foreground = data.foreground;
                picker.selectedIndex = 0;
                for (var i = 0; i < data.items.length; i++) {
                    if (data.items[i].current)
                        picker.selectedIndex = i;
                }
                if (!data.items.length)
                    picker.error = "No images found";
            } catch (e) {
                picker.error = "Images unavailable";
            }
            Qt.callLater(function() { content.forceActiveFocus(); });
        }
    }

    Process { id: applyProcess }

    IpcHandler {
        target: "appearance"
        function show(kind: string): void {
            picker.open(kind.startsWith("theme") ? kind : "wallpaper", Quickshell.screens[0]);
        }
        function close(): void { picker.opened = false; }
        function next(): void { picker.navigate(1); }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "desktop-appearance-clicks"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onDoubleClicked: function(mouse) {
                    picker.open(mouse.button === Qt.RightButton ? "theme" : "wallpaper", modelData);
                }
            }
        }
    }

    PanelWindow {
        id: overlay
        visible: picker.opened
        screen: picker.targetScreen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "desktop-appearance-picker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle { anchors.fill: parent; color: "#b3000000" }
        MouseArea {
            anchors.fill: parent
            onClicked: picker.opened = false
            onWheel: function(event) { picker.navigate(event.angleDelta.y > 0 ? -1 : 1); }
        }

        Item {
            id: content
            anchors.fill: parent
            focus: true
            readonly property real themeAspect: Math.max(1.3, Math.min(3, width / Math.max(1, height)))
            readonly property real previewWidth: picker.mode !== "wallpaper" ? previewHeight * themeAspect : Math.min(768, width * 0.55)
            readonly property real previewHeight: picker.mode !== "wallpaper" ? Math.min(560, height * 0.58, width * 0.68 / themeAspect) : Math.min(475, height * 0.58)
            readonly property real sliceWidth: Math.min(108, width * 0.08)
            readonly property real step: sliceWidth * 0.74
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Backspace) picker.back();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) picker.apply();
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) picker.navigate(-1);
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Tab) picker.navigate(1);
                else return;
                event.accepted = true;
            }

            Row {
                id: categoryRow
                visible: picker.mode === "theme-category"
                anchors.centerIn: parent
                width: Math.min(content.width * 0.86, 1680)
                spacing: Math.min(36, content.width * 0.03)
                readonly property real cardWidth: (width - spacing) / 2
                readonly property real cardHeight: Math.min(content.height * 0.55, cardWidth / 2.15)
                height: cardHeight + 42

                Repeater {
                    model: picker.mode === "theme-category" ? picker.items : []
                    delegate: Item {
                        id: categoryTile
                        required property int index
                        required property var modelData
                        width: categoryRow.cardWidth
                        height: categoryRow.height

                        Rectangle {
                            width: parent.width
                            height: categoryRow.cardHeight
                            radius: 4
                            color: "#202024"
                            border.color: categoryTile.index === picker.selectedIndex ? picker.accent : "#66ffffff"
                            border.width: categoryTile.index === picker.selectedIndex ? 3 : 1

                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: categoryTile.modelData.image
                                sourceSize.width: Math.ceil(categoryRow.cardWidth)
                                sourceSize.height: Math.ceil(categoryRow.cardHeight)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    picker.selectedIndex = categoryTile.index;
                                    picker.apply();
                                }
                            }
                        }

                        Text {
                            anchors.top: parent.top
                            anchors.topMargin: categoryRow.cardHeight + 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: categoryTile.modelData.name
                            color: picker.foreground
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }
                }
            }

            Repeater {
                model: picker.mode === "theme-category" ? [] : picker.items
                delegate: Item {
                    id: tile
                    required property int index
                    required property var modelData
                    readonly property int offset: index - picker.selectedIndex
                    readonly property bool selected: offset === 0
                    visible: Math.abs(offset) <= Math.ceil((content.width - content.previewWidth) / (2 * content.step)) + 1
                    width: selected ? content.previewWidth : content.sliceWidth
                    height: selected ? content.previewHeight : content.previewHeight * 0.91
                    x: selected ? (content.width - content.previewWidth) / 2 : (offset < 0 ? (content.width - content.previewWidth) / 2 + offset * content.step : (content.width + content.previewWidth) / 2 - content.sliceWidth * 0.26 + (offset - 1) * content.step)
                    y: (content.height - height) / 2 - 24
                    z: selected ? 100 : 50 - Math.abs(offset)
                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    Rectangle {
                        id: roundedMask
                        anchors.fill: parent
                        radius: 4
                        color: "white"
                        visible: false
                        layer.enabled: true
                    }

                    Item {
                        anchors.fill: parent
                        clip: true
                        layer.enabled: true
                        layer.effect: MultiEffect { maskEnabled: true; maskSource: roundedMask }
                        Rectangle { anchors.fill: parent; color: "#202024" }
                        Image {
                            anchors.fill: parent
                            source: tile.visible ? tile.modelData.image : ""
                            sourceSize.width: Math.ceil(content.previewWidth)
                            sourceSize.height: Math.ceil(content.previewHeight)
                            asynchronous: true
                            cache: false
                            fillMode: picker.mode !== "wallpaper" && tile.selected ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                        }
                        Rectangle { anchors.fill: parent; color: tile.selected ? "transparent" : "#70000000" }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: 4
                        border.color: tile.selected ? picker.accent : "#66ffffff"
                        border.width: tile.selected ? 3 : 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tile.selected ? picker.apply() : picker.selectedIndex = tile.index
                        onWheel: function(event) { picker.navigate(event.angleDelta.y > 0 ? -1 : 1); }
                    }
                }
            }

            Text {
                visible: (picker.mode !== "wallpaper" && picker.mode !== "theme-category") || !picker.items[picker.selectedIndex]
                anchors.horizontalCenter: parent.horizontalCenter
                y: (content.height + content.previewHeight) / 2 - 4
                width: content.previewWidth
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                text: picker.items[picker.selectedIndex] ? picker.items[picker.selectedIndex].name : (picker.error || "Loading...")
                color: picker.foreground
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                font.bold: true
            }
        }
    }
}
