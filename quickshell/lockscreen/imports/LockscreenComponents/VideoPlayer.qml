import QtQuick
import QtMultimedia

// Internal to BackgroundVideo.qml, which loads it on demand.
Item {
    id: video

    property url source

    MediaPlayer {
        source: video.source
        autoPlay: true
        loops: MediaPlayer.Infinite
        videoOutput: output
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }
}
