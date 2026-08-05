import QtQuick
import QtQuick.Controls as QQControls
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

// Configuration page for the video wallpaper plugin.
// Shown under: Desktop → Right-click → Configure Desktop… → Wallpaper → Video Wallpaper.
KCM.SimpleKCM {
    id: configPage

    property string cfg_VideoSource: wallpaper.configuration.VideoSource
    property int cfg_FillMode: wallpaper.configuration.FillMode
    property bool cfg_Muted: wallpaper.configuration.Muted
    property real cfg_Volume: wallpaper.configuration.Volume
    property bool cfg_Running: wallpaper.configuration.Running

    QtDialogs.FileDialog {
        id: fileDialog
        title: i18n("Choose a video wallpaper")
        nameFilters: [ "Video files (*.mp4 *.webm *.mkv *.mov)", "All files (*)" ]
        onAccepted: {
            cfg_VideoSource = selectedFile.toString().replace("file://", "")
            cfg_Running = true
        }
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        RowLayout {
            Kirigami.FormData.label: i18n("Video:")

            QQControls.TextField {
                id: pathField
                text: cfg_VideoSource
                readOnly: true
                placeholderText: i18n("No video selected")
                Layout.fillWidth: true
            }
            QQControls.Button {
                icon.name: "document-open"
                text: i18n("Browse…")
                onClicked: fileDialog.open()
            }
            QQControls.Button {
                icon.name: "edit-clear"
                text: i18n("Clear")
                onClicked: cfg_VideoSource = ""
            }
        }

        QQControls.ComboBox {
            Kirigami.FormData.label: i18n("Mode:")
            model: [
                { text: i18n("Scale & Crop (fill)"),    value: VideoOutput.Stretch },
                { text: i18n("Scale & Keep (fit)"),     value: VideoOutput.PreserveAspectFit },
                { text: i18n("Keep aspect (centered)"), value: VideoOutput.PreserveAspectCrop }
            ]
            textRole: "text"
            valueRole: "value"
            onActivated: cfg_FillMode = currentValue
            Component.onCompleted: currentIndex = indexOfValue(cfg_FillMode)
        }

        QQControls.CheckBox {
            Kirigami.FormData.label: i18n("Playback:")
            text: i18n("Playing")
            checked: cfg_Running
            onToggled: cfg_Running = checked
        }

        QQControls.CheckBox {
            Kirigami.FormData.label: i18n("Audio:")
            text: i18n("Muted")
            checked: cfg_Muted
            onToggled: cfg_Muted = checked
        }

        QQControls.Slider {
            Kirigami.FormData.label: i18n("Volume:")
            from: 0.0
            to: 1.0
            value: cfg_Volume
            enabled: !cfg_Muted
            onMoved: cfg_Volume = value
        }
    }
}
