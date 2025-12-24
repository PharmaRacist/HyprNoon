import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.store
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    property int collapsedSize: progress.implicitSize  // Size for just the icon
    property int expandedSize: contentWidth + margins * 2  // Dynamic based on text
    property int margins: 10

    // Calculate content width dynamically
    property int contentWidth: progress.implicitSize + spacing + (collapsed ? 0 : Math.min(textMetrics.width, maxTextWidth))
    property int spacing: 15
    property int maxTextWidth: 170
    property bool collapsed: true

    height: collapsed ? collapsedSize : expandedSize
    width: BarData.currentBarExclusiveSize

    // Measure text width
    TextMetrics {
        id: textMetrics
        font: textItem.font
        text: `${BeatsService.cleanedTitle}${BeatsService?.artist ? ' • ' + BeatsService?.artist : ''}`
    }

    // Smooth height animation
    Behavior on height {
        Anim {}
    }

    // Container to handle the rotation properly
    Item {
        id: container
        anchors.centerIn: parent
        width: parent.height  // Swap dimensions for rotation
        height: parent.width
        rotation: -90
        transformOrigin: Item.Center

        RowLayout {
            id: rowLayout
            anchors.verticalCenter: parent.verticalCenter
            width: implicitWidth
            height: implicitHeight

            spacing: root.spacing

            ClippedFilledCircularProgress {
                id: progress
                implicitSize: Math.min(BarData.currentBarExclusiveSize, 35) * 0.75
                value: BeatsService.currentTrackProgressRatio
                colSecondary: Colors.colSecondaryContainer
                colPrimary: Colors.m3.m3onSecondaryContainer
                rotation: 90
                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    font.pixelSize: progress.implicitSize * BarData.barPadding
                    text: BeatsService?.isPlaying ? "pause" : "music_note"
                    color: Colors.m3.m3onSecondaryContainer
                }
            }

            Revealer {
                reveal: !root.collapsed
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.maximumWidth: root.maxTextWidth
                Layout.preferredWidth: textMetrics.width
                StyledText {
                    id: textItem
                    visible: parent.reveal
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: BarData.currentBarExclusiveSize * BarData.barPadding / 1.5
                    elide: Text.ElideRight
                    color: Colors.colOnLayer1
                    text: `${BeatsService.title}${BeatsService.artist ? ' • ' + BeatsService.artist : ''}`
                }
            }
        }
    }
    MediaPopup {
        hoverTarget: mouse
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: event => {
            if (event.button === Qt.MiddleButton) {
                BeatsService.activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                BeatsService.activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                BeatsService.activePlayer.next();
            } else if (event.button === Qt.LeftButton)
            {}
        }
    }
}
