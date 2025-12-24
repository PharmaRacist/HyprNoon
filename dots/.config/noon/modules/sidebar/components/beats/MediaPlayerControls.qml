import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root
    implicitHeight: mediaControls.height
    implicitWidth: mediaControls.width

    property bool showDownload: true
    readonly property MprisPlayer player: BeatsService.player
    readonly property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing

    component DockMediaButton: RippleButtonWithIcon {
        implicitSize: 30
        buttonRadius: Rounding.full
        colBackground: toggled ? TrackColorsService.colors.colPrimary : TrackColorsService.colors.colSecondaryContainer
        colBackgroundHover: toggled ? TrackColorsService.colors.colPrimaryHover : TrackColorsService.colors.colSecondaryContainerHover
        colRipple: toggled ? TrackColorsService.colors.colSecondaryContainer : TrackColorsService.colors.colSecondaryContainerActive
    }

    RowLayout {
        id: mediaControls
        spacing: Padding.small

        DockMediaButton {
            materialIcon: "shuffle"
            enabled: root.player?.canControl
            opacity: root.player ? 1 : 0.5
            toggled: root.player?.shuffle ?? false
            onClicked: root.player && (root.player.shuffle = !root.player.shuffle)
        }

        DockMediaButton {
            materialIcon: "skip_previous"
            enabled: root.player?.canGoPrevious
            opacity: enabled ? 1 : 0.5
            onClicked: root.player?.previous()
        }

        RippleButtonWithIcon {
            toggled:root.isPlaying
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

            Behavior on implicitWidth { Anim {} }
        }

        DockMediaButton {
            materialIcon: "skip_next"
            enabled: root.player?.canGoNext
            opacity: enabled ? 1 : 0.5
            onClicked: root.player?.next()
        }

        DockMediaButton {
            materialIcon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            enabled: root.player?.canControl
            opacity: root.player ? 1 : 0.5
            toggled: root.player?.loopState !== MprisLoopState.None
            onClicked: BeatsService.cycleRepeat()
            StyledToolTip {
                content: root.player?.loopState === MprisLoopState.Track ? "Repeat Track" : root.player?.loopState === MprisLoopState.Playlist ? "Repeat Playlist" : "Repeat Off"
            }
        }

        DockMediaButton {
            visible: BeatsService.isCurrentPlayer()
            materialIcon: "close"
            onClicked: BeatsService.stopPlayer()
        }

        DockMediaButton {
            visible: root.showDownload && !BeatsService.isCurrentPlayer()
            materialIcon: "download"
            // enabled: !BeatsService.isDownloading
            onClicked: BeatsService.downloadCurrentSong()
        }
    }
}
