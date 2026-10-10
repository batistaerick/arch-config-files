import QtQuick

// Looping, cropped background video for a lockscreen design. Pass the
// theme-relative file from theme.conf, e.g.
//   BackgroundVideo { anchors.fill: parent; source: Qt.resolvedUrl(config.background) }
// QtMultimedia loads in a nested Loader so a missing multimedia backend leaves
// the rest of the design usable.
Item {
    id: background

    property url source

    Loader {
        id: player
        anchors.fill: parent
        Component.onCompleted: {
            if (background.source.toString() !== "")
                player.setSource(Qt.resolvedUrl("VideoPlayer.qml"), { source: background.source });
        }
    }
}
