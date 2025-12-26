import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.store

StyledPopup {
    id: root

    Visualizer {
        id: visualizer

        z: 99
        mode: "filled"
        active: true
    }

    StyledRect {
        id: bg

        z: 0
        anchors.fill: parent
        implicitWidth: 420
        implicitHeight: 120
        enableBorders: true
        color: "transparent"
        clip: true
        radius: Rounding.verylarge

        BlurImage {
            z: 0
            anchors.fill: parent
            source: BeatsService.artUrl
            asynchronous: true
            blur: true
        }

        RowLayout {
            z: 2
            anchors.fill: parent
            anchors.margins: Padding.large
            anchors.leftMargin: Padding.huge
            anchors.rightMargin: Padding.huge
            spacing: Padding.large

            // Cover Art
            MusicCoverArt {
                radius: Rounding.verylarge - Padding.normal
                Layout.preferredWidth: parent.height * 0.86
                Layout.preferredHeight: parent.height * 0.86
            }

            // Track Info
            Column {
                z: 2
                spacing: Padding.normal

                StyledText {
                    font.pixelSize: Fonts.sizes.title
                    color: Colors.colOnLayer0
                    text: BeatsService.title
                    elide: Text.ElideRight

                    MouseArea {
                        anchors.fill: parent
                        onPressed: Noon.callIpc("global toggle_beats")
                    }

                }

                StyledText {
                    font.pixelSize: Fonts.sizes.large
                    color: Colors.colSubtext
                    text: BeatsService.artist
                    elide: Text.ElideRight
                }

            }

            Spacer {
            }

        }

    }

}
