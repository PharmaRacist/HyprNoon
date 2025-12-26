import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Rectangle {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || qsTr("No media")
    property bool bordered: Mem.options.bar.appearance.modulesBg
    property bool expand: false
    color: bordered ? Colors.colLayer1 : "transparent"
    radius: Rounding.small
    implicitHeight: BarData.currentBarExclusiveSize
    implicitWidth: Math.max(rowLayout.implicitWidth, 130)
    Layout.preferredWidth: implicitWidth

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }
    MediaPopup {
        hoverTarget: mouse
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        hoverEnabled: true

        onPressed: event => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                Noon.callIpc("sidebar reveal Beats");
            }
        }
    }

    RowLayout {
        id: rowLayout
        spacing: 16
        anchors.fill: parent

        CircularProgress {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: rowLayout.spacing
            lineWidth: 2
            value: activePlayer?.position / activePlayer?.length
            size: 26
            secondaryColor: Colors.colSecondaryContainer
            primaryColor: Colors.m3.m3onSecondaryContainer

            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: activePlayer?.isPlaying ? "pause" : "music_note"
                font.pixelSize: Fonts.sizes.normal
                color: Colors.m3.m3onSecondaryContainer
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.rightMargin: rowLayout.spacing
            Layout.maximumWidth: root.expand ? parent.width - 30 : 130
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: Colors.colOnLayer1
            text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
        }
    }
}
