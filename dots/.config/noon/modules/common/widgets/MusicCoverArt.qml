import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledRect {
    id: root

    radius: Rounding.large
    color: TrackColorsService.colors.colSecondaryContainer
    clip: true
    enableShadows: true

    CroppedImage {
        id: coverImage

        z: 99
        tint: true
        tintLevel: 0.8
        tintColor: TrackColorsService.colors.colSecondaryContainer
        visible: true
        anchors.fill: parent
        source: BeatsService.artUrl
        mipmap: true
        radius: root.radius
    }

    MaterialSymbol {
        z: 99
        visible: coverImage.status === Image.Null || coverImage.status === Image.Error
        anchors.centerIn: parent
        text: "music_note"
        font.pixelSize: (parent.height + parent.width) / 2 - Padding.verylarge
        color: TrackColorsService.colors.colSecondary
    }

}
