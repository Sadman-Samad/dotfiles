/*
    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
    SPDX-License-Identifier: GPL-2.0-or-later

    AnimeLock: stock Breeze lock screen with an animated anime backdrop
    layered under the UI. Auth flow (password box, media controls) unchanged.
*/

import QtQuick

Item {
    id: root
    property bool debug: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()

    // These are magical properties that kscreenlocker looks for
    property bool viewVisible: false

    LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: 800
    implicitHeight: 600

    AnimeBackdrop {
        anchors.fill: parent
    }

    LockScreenUi {
        anchors.fill: parent
    }
}
