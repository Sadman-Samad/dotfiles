import QtQuick
import QtMultimedia
import org.kde.plasma.plasmoid

// Video wallpaper: loops a muted video that fills the desktop.
// Configuration (Source/Fill mode/Mute/Volume/Running) is set in config.qml
// and persisted via the wallpaper configuration mechanism (config/main.xml).
// Root MUST be a WallpaperItem — Plasma 6 rejects plain Item roots.

WallpaperItem {
    id: root

    property string videoSource: root.configuration.VideoSource || ""
    property int fillMode: root.configuration.FillMode ?? VideoOutput.PreserveAspectCrop
    property bool muted: root.configuration.Muted ?? true
    property real volume: root.configuration.Volume ?? 0.0
    property bool running: root.configuration.Running ?? true

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: root.fillMode
    }

    AudioOutput {
        id: audioOutput
        muted: root.muted
        volume: root.volume
    }

    MediaPlayer {
        id: player
        videoOutput: videoOutput
        audioOutput: audioOutput
        source: root.videoSource !== "" ? root.videoSource : ""
        loops: MediaPlayer.Infinite

        onSourceChanged: {
            if (source.toString() !== "" && root.running) {
                play()
            } else {
                stop()
            }
        }

        onErrorOccurred: (error, errorString) => {
            console.warn("[videowallpaper] MediaPlayer error:", error, errorString)
        }
    }

    onRunningChanged: {
        if (running && player.source.toString() !== "") {
            player.play()
        } else {
            player.pause()
        }
    }

    onVideoSourceChanged: {
        if (player.source.toString() !== "" && running) {
            player.play()
        }
    }

    Component.onCompleted: {
        if (running && player.source.toString() !== "") {
            player.play()
        }
    }
}
