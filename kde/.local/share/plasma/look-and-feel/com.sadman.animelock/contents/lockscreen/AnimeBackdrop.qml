import QtQuick

// AnimeLock backdrop: crossfading character stills, slow zoom, scrim.
Item {
    id: backdrop

    readonly property string stillDir:
        "file:///home/sadman/.local/share/lockscreen-stills/"
    readonly property var stills: [
        "gear-5-luffy-ultimate-one-piece-live-wallpaper.jpg",
        "gojo-blue-aura-desktophut.jpg",
        "gojo-vs-sukuna-desktophut.jpg",
        "yuuji-itadori-x-megumi-fushiguro-jujustu-kaisen-live-wallpaper.jpg",
        "ichigo-blazing-katana-kurosaki-bleach-live-wallpaper.jpg",
        "kakashi-sharingan-live-wallpaper.jpg",
        "sousuke-aizen-bleach-thousand-year-blood-war-live-wallpaper.jpg",
    ]
    property int idx: 0

    Rectangle { anchors.fill: parent; color: "#05050a" }

    Image {
        id: imgBack
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: backdrop.stillDir + backdrop.stills[backdrop.idx]
        asynchronous: true
        cache: false
        SequentialAnimation on scale {
            running: true; loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.08; duration: 9000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.08; to: 1.0; duration: 9000; easing.type: Easing.InOutSine }
        }
    }

    Image {
        id: imgFront
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        opacity: 0
        asynchronous: true
        cache: false
        SequentialAnimation on scale {
            running: true; loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.08; duration: 9000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.08; to: 1.0; duration: 9000; easing.type: Easing.InOutSine }
        }
        Behavior on opacity { NumberAnimation { duration: 1400; easing.type: Easing.InOutQuad } }
    }

    Timer {
        interval: 9000
        repeat: true
        running: true
        onTriggered: {
            backdrop.idx = (backdrop.idx + 1) % backdrop.stills.length;
            imgFront.source = backdrop.stillDir + backdrop.stills[backdrop.idx];
            imgFront.opacity = 1;
            imgBack.opacity = 0;
        }
    }

    // scrim: darken bottom where the clock lives, plus subtle top band
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.5
        gradient: Gradient {
            GradientStop { position: 0; color: "#00000000" }
            GradientStop { position: 1; color: "#b3070b14" }
        }
    }
}
