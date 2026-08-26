import QtQuick

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// AnimeLock backdrop: crossfading character stills, slow zoom, scrim.
Item {
    id: backdrop

    readonly property string stillDir:
        "file:///home/sadman/.local/share/lockscreen-stills/"
    readonly property var stills: [
        { src: "gear-5-luffy-ultimate-one-piece-live-wallpaper.jpg", name: "LUFFY — GEAR 5" },
        { src: "gojo-blue-aura-desktophut.jpg",                      name: "GOJO" },
        { src: "gojo-vs-sukuna-desktophut.jpg",                      name: "GOJO × SUKUNA" },
        { src: "yuuji-itadori-x-megumi-fushiguro-jujustu-kaisen-live-wallpaper.jpg", name: "ITADORI" },
        { src: "ichigo-blazing-katana-kurosaki-bleach-live-wallpaper.jpg",           name: "ICHIGO" },
        { src: "kakashi-sharingan-live-wallpaper.jpg",               name: "KAKASHI" },
        { src: "sousuke-aizen-bleach-thousand-year-blood-war-live-wallpaper.jpg",    name: "AIZEN" },
    ]
    property int idx: 0
    readonly property string currentName: stills[idx].name

    Rectangle { anchors.fill: parent; color: "#05050a" }

    Image {
        id: imgBack
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: backdrop.stillDir + backdrop.stills[backdrop.idx].src
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
            imgFront.source = backdrop.stillDir + backdrop.stills[backdrop.idx].src;
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
    // character name tag, bottom-right above the clock zone
    Rectangle {
        id: nameTag
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: Kirigami.Units.gridUnit * 2.5
            bottomMargin: Kirigami.Units.gridUnit * 2.5
        }
        radius: height / 2
        color: "#cc0b0e14"
        border.color: "#66ffffff"
        border.width: 1
        visible: opacity > 0
        PlasmaComponents3.Label {
            id: tagLabel
            anchors.centerIn: parent
            anchors.margins: Kirigami.Units.largeSpacing
            text: backdrop.currentName
            color: "#e8ecf1"
            font.capitalization: Font.AllUppercase
            font.weight: Font.DemiBold
            font.letterSpacing: 2.5
            font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.25)
        }
        width: tagLabel.implicitWidth + Kirigami.Units.gridUnit * 1.5
        height: tagLabel.implicitHeight + Kirigami.Units.smallSpacing * 3
    }

}
