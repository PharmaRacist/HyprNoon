import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

ColumnLayout {
    id: root
    readonly property MprisPlayer player: BeatsService.player
    readonly property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing
    spacing: Padding.huge
    Layout.fillWidth: true

    StyledProgressBar {
        sperm: true
        value: BeatsService.currentTrackProgressRatio
        highlightColor: TrackColorsService.colors.colPrimary
        trackColor: TrackColorsService.colors.colSecondaryContainer
        Layout.fillWidth: true
        Layout.preferredHeight: 18
        MouseArea {
            anchors.fill: parent
            enabled: BeatsService.player?.canSeek && BeatsService.player?.length > 0
            hoverEnabled: true
            property bool isDragging: false

            onPressed: mouse => {
                isDragging = true;
                seekTo(mouse.x);
            }
            onPositionChanged: mouse => isDragging && seekTo(mouse.x)
            onReleased: isDragging = false

            function seekTo(x) {
                const player = BeatsService.player;
                if (!player?.canSeek || !player?.length)
                    return;
                player.position = Math.max(0, Math.min(1, x / width)) * player.length;
            }
        }
    }

    RowLayout {
        spacing: Padding.small
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        MediaButton {
            materialIcon: "shuffle"
            enabled: root.player?.canControl
            opacity: root.player ? 1 : 0.5
            toggled: root.player?.shuffle ?? false
            onClicked: root.player && (root.player.shuffle = !root.player.shuffle)
        }

        MediaButton {
            materialIcon: "skip_previous"
            enabled: root.player?.canGoPrevious
            opacity: enabled ? 1 : 0.5
            onClicked: root.player?.previous()
        }

        RippleButtonWithIcon {
            toggled: root.isPlaying
            enabled: root.player?.canPause

            implicitWidth: toggled ? 80 : 40
            implicitHeight: 40
            buttonRadius: toggled ? Rounding.verylarge : Rounding.large

            colBackground: toggled ? TrackColorsService.colors.colPrimary : TrackColorsService.colors.colSecondaryContainer
            colBackgroundHover: toggled ? TrackColorsService.colors.colPrimaryHover : TrackColorsService.colors.colSecondaryContainerHover
            colRipple: toggled ? TrackColorsService.colors.colPrimaryActive : TrackColorsService.colors.colSecondaryContainerActive

            onClicked: root.player?.canPause ? root.player.togglePlaying() : (GlobalStates.playlistOpen = true)
            materialIcon: toggled ? "pause" : "play_arrow"
            iconColor: toggled ? TrackColorsService.colors.colOnPrimary : TrackColorsService.colors.colOnSecondaryContainer

            Behavior on implicitWidth {
                Anim {}
            }
        }

        MediaButton {
            materialIcon: "skip_next"
            enabled: root.player?.canGoNext
            opacity: enabled ? 1 : 0.5
            onClicked: root.player?.next()
        }

        MediaButton {
            materialIcon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            enabled: root.player?.canControl
            opacity: root.player ? 1 : 0.5
            toggled: root.player?.loopState !== MprisLoopState.None
            onClicked: BeatsService.cycleRepeat()
        }
    }
    component MediaButton: RippleButtonWithIcon {
        implicitSize: 30
        buttonRadius: Rounding.full
        colBackground: toggled ? TrackColorsService.colors.colPrimary : TrackColorsService.colors.colSecondaryContainer
        colBackgroundHover: toggled ? TrackColorsService.colors.colPrimaryHover : TrackColorsService.colors.colSecondaryContainerHover
        colRipple: toggled ? TrackColorsService.colors.colSecondaryContainer : TrackColorsService.colors.colSecondaryContainerActive
    }
}
