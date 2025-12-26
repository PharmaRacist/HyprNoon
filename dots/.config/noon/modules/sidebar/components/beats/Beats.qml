import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

StyledRect {
    id: root
    
    clip: true
    radius: Rounding.verylarge
    color: "transparent"
    
    readonly property bool playing: BeatsService.player?.playbackState === MprisPlaybackState.Playing
    readonly property bool displayingLyrics: LyricsService.lyrics.length > 0

    Keys.onPressed: event => {
        const ctrl = event.modifiers & Qt.ControlModifier;
        const shift = event.modifiers & Qt.ShiftModifier;
        const player = BeatsService.player;
        
        if (ctrl && shift) {
            switch (event.key) {
                case Qt.Key_R:
                    LyricsService.fetchLyrics(BeatsService.artist || "", BeatsService.title || "");
                    break;
                case Qt.Key_Right:
                    player?.canControl && player.next();
                    break;
                case Qt.Key_Left:
                    player?.canControl && player.previous();
                    break;
                case Qt.Key_D:
                    BeatsService.downloadCurrentSong();
                    break;
                case Qt.Key_S:
                    player && (player.shuffle = !player.shuffle);
                    break;
                default:
                    return;
            }
        } else if (ctrl && event.key === Qt.Key_R) {
            BeatsService.cycleRepeat();
        } else {
            switch (event.key) {
                case Qt.Key_Up:
                    AudioService?.sink?.audio && (AudioService.sink.audio.volume = Math.min(1.0, AudioService.sink.audio.volume + 0.05));
                    break;
                case Qt.Key_Down:
                    AudioService?.sink?.audio && (AudioService.sink.audio.volume = Math.max(0.0, AudioService.sink.audio.volume - 0.05));
                    break;
                case Qt.Key_Space:
                    player?.togglePlaying();
                    break;
                case Qt.Key_Right:
                    player?.canSeek && player.length && (player.position = Math.min(player.length, player.position + 10));
                    break;
                case Qt.Key_Left:
                    player?.canSeek && player.length && (player.position = Math.max(0, player.position - 10));
                    break;
                default:
                    return;
            }
        }
        event.accepted = true;
    }

    Loader {
        z: -1
        active: Mem.options.mediaPlayer.useBlur
        anchors.fill: parent
        sourceComponent: BlurImage {
            anchors.fill: parent
            source: BeatsService.artUrl
            asynchronous: true
            blur: true
            tint: true
            tintLevel: 0.65
            tintColor: TrackColorsService.colors.colSecondaryContainer
        }
    }

    Visualizer {
        active: Mem.options.mediaPlayer.showVisualizer && root.playing
        mode: Mem.options.mediaPlayer.visualizerMode
        visualizerColor: TrackColorsService.colors.colPrimary
    }
    ColumnLayout {
        anchors {
            fill: parent
            margins: Padding.large
        }
        spacing: Padding.large

        Spacer {}
        PlayerSelector {}
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: Padding.large
            spacing: Padding.massive

            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.massive

                Revealer {
                    reveal: LyricsService.state !== LyricsService.NoLyricsFound
                    Layout.maximumWidth: 75
                    Layout.maximumHeight: 75

                    CroppedImage {
                        visible: parent.reveal
                        anchors.centerIn: parent
                        z: 99
                        source: BeatsService.artUrl
                        sourceSize: Qt.size(width, height)
                        mipmap: true
                        radius: Rounding.large
                        tint: true
                        tintLevel: 0.8
                        tintColor: TrackColorsService.colors.colSecondaryContainer
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Fonts.sizes.huge
                        font.weight: Font.Medium
                        color: TrackColorsService.colors.colOnLayer0
                        elide: Text.ElideRight
                        text: BeatsService.player?.trackTitle || "No players available"
                        horizontalAlignment:Text.AlignLeft
                    }

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: 17
                        color: TrackColorsService.colors.colSubtext
                        elide: Text.ElideRight
                        text: BeatsService.player?.trackArtist || "No players available"
                        horizontalAlignment:Text.AlignLeft

                    }
                }
            }
            MediaPlayerControls {}
        }
    }

    SpotifyLyrics {}
    BottomTracksDialog {}
}
