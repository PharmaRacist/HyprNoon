import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.modules.bar.components
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.store

StyledRect {
    id: root
    readonly property var meaningfulPlayers: BeatsService.meaningfulPlayers
    property int selectedPlayerIndex: Mem.states.services.mediaPlayer.selectedPlayerIndex
    readonly property MprisPlayer player: meaningfulPlayers[selectedPlayerIndex]
    visible: player && player.trackTitle
    radius:dockRoot.mainRounding
    Layout.preferredHeight: bg.implicitHeight
    Layout.preferredWidth: 2.5 * height
    color: Colors.colLayer0
    enableShadows: true
    enableBorders:true
    StyledRect {
        anchors.fill: parent
        color: "transparent"
        radius: parent.radius - anchors.margins
        clip: true
        BlurImage {
            id: artImage
            z: 2
            blur: true
            retainWhileLoading: true
            anchors.fill: parent
            source: BeatsService.activePlayer?.trackArtUrl ?? ""
            asynchronous: true
        }
        Controls {
            id: controls
            z: 9
            accentColor: TrackColorsService.colors.colOnLayer0
            anchors.centerIn: parent
            btnSize: parent.height /2
        }
    }

    component Controls: Item {
        id: root
        anchors.centerIn: parent
        property int btnSize: 30
        readonly property var player: BeatsService.activePlayer
        property color accentColor
        RowLayout {
            spacing: 8
            anchors.centerIn: parent

            MaterialSymbol {
                font.pixelSize: root.btnSize
                fill: 1
                text: "skip_previous"
                color: root.accentColor
                MouseArea {
                    anchors.fill: parent
                    onClicked: player?.previous()
                }
            }

            MaterialSymbol {
                font.pixelSize: root.btnSize
                fill: 1
                text: player && player.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                color: root.accentColor
                Layout.alignment: Qt.AlignCenter
                x: 0
                // animateChange: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: player?.togglePlaying()
                }
            }

            MaterialSymbol {
                font.pixelSize: root.btnSize
                fill: 1
                text: "skip_next"
                color: root.accentColor
                MouseArea {
                    anchors.fill: parent
                    onClicked: player?.next()
                }
            }
        }
    }
}
