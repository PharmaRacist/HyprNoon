import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets


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

    Loader {
        anchors.fill: parent
        active: Mem.options.mediaPlayer.showVisualizer && root.playing
        sourceComponent: Visualizer {
            active: true
            mode: Mem.options.mediaPlayer.visualizerMode
            visualizerSmoothing: 4
            maxVisualizerValue: mode === "atom" ? 500 : 1500
            visualizerColor: TrackColorsService.colors.colPrimary
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Padding.large
        }
        spacing: Padding.large

        Item { Layout.fillHeight: true }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Padding.large
            layoutDirection: displayingLyrics ? Qt.LeftToRight : Qt.RightToLeft

            Item { Layout.fillHeight: true }
        }

        PlayerSelector {}

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: Padding.large
            spacing: Padding.huge

            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.large

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
                        radius: Rounding.normal
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

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 18

                StyledProgressBar {
                    sperm: true
                    anchors.fill: parent
                    value: BeatsService.currentTrackProgressRatio
                    highlightColor: TrackColorsService.colors.colPrimary
                    trackColor: TrackColorsService.colors.colSecondaryContainer
                }

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
                        if (!player?.canSeek || !player?.length) return;
                        player.position = Math.max(0, Math.min(1, x / width)) * player.length;
                    }
                }
            }

            MediaPlayerControls {
                Layout.alignment: Qt.AlignHCenter
                showDownload: !(BeatsService.player?.dbusName?.includes("vlc") ?? false)
            }
        }
    }

    SpotifyLyrics {
    }

    BottomDialog {
        id: bottomDialog
        
        z: 99
        expandedHeight: root.height * 0.45
        collapsedHeight: 100
        revealOnWheel: true
        enableStagedReveal: true

        contentItem: ColumnLayout {
            anchors.fill:parent
            anchors.margins:Padding.verylarge
            spacing: Padding.large

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.margins: Padding.large

                StyledText {
                    text: `${BeatsService.filteredIndices.length} Tracks`
                    font.pixelSize: Fonts.sizes.subTitle
                    color: Colors.colOnLayer2
                }

                Item { Layout.fillWidth: true }

                RippleButtonWithIcon {
                    materialIcon: "close"
                    releaseAction: () => bottomDialog.expand = false
                }
            }

            Separator {
                visible: bottomDialog.expand
                Layout.leftMargin: Padding.large
                Layout.rightMargin: Padding.large
            }
            // SearchBar {
            //     Layout.fillWidth: true
            //     Layout.preferredHeight: 40
            //     Layout.leftMargin: Padding.large
            //     Layout.rightMargin: Padding.large
            //     searchInput.placeholderText: "Search Tracks"
            //     color: "transparent"
            //     onSearchTextChanged: BeatsService.updateSearchFilter(searchText)
            // }
            StyledListView {
                visible: bottomDialog.expand
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Padding.large
                spacing: 8
                clip: true
                model: BeatsService.filteredTracksCount

                Component.onCompleted: BeatsService.initializeTracks()

                delegate: StyledDelegateItem {
                    required property int index

                    readonly property var trackInfo: BeatsService.getFilteredTrackInfo(index)
                    readonly property string trackPath: trackInfo.path || ""
                    readonly property bool currentlyPlaying: trackPath === BeatsService.currentTrackPath

                    title: trackInfo.name || "Unknown Track"
                    subtext: trackInfo.extension ? `${trackInfo.extension} Audio` : ""
                    colActiveColor: currentlyPlaying ? TrackColorsService.colors.colSecondaryContainerActive : TrackColorsService.colors.colSecondaryContainer
                    colActiveItemColor: currentlyPlaying ? TrackColorsService.colors.colPrimary : TrackColorsService.colors.colSecondary
                    colBackground: currentlyPlaying ? TrackColorsService.colors.colSecondaryContainerActive : TrackColorsService.colors.colLayer1

                    TrackContextMenu {
                        id: trackContextMenu
                        trackPath: parent.trackPath
                        trackName: parent.title
                        parentButton: parent
                    }

                    releaseAction: () => trackPath && BeatsService.playTrackByPath(trackPath)
                    altAction: () => trackPath && trackContextMenu.showMenu()
                }
            }
            Spacer {}
        }
    }
}
