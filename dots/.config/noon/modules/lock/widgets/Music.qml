import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledRect {
    id: root

    Layout.preferredHeight: 160
    Layout.fillWidth: true
    Layout.margins: Padding.normal
    enableBorders: true
    enableShadows: true
    color: Colors.colLayer1
    radius: Rounding.verylarge
    visible: BeatsService.artist.length > 0

    Visualizer {
    }

    RowLayout {
        spacing: Padding.massive

        anchors {
            fill: parent
            margins: Padding.verylarge
        }

        CroppedImage {
            id: coverImage

            z: 99
            Layout.fillHeight: true
            Layout.preferredWidth: height
            source: BeatsService.artUrl
            mipmap: true
            radius: root.radius
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledText {
                Layout.maximumWidth: parent.width * 0.8
                Layout.fillWidth: true
                font.pixelSize: Fonts.sizes.huge
                font.family: Fonts.family.main
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                color: Colors.colOnLayer3
                text: {
                    if (BeatsService.player.trackTitle)
                        return BeatsService.player.trackTitle;
                    else
                        return "No players available";
                }
            }

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: 18
                color: Colors.colOnLayer3
                font.family: Fonts.family.main
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                text: {
                    if (BeatsService.player.trackArtist)
                        return BeatsService.player.trackArtist;
                    else
                        return "No players available";
                }
            }

        }

    }

}
