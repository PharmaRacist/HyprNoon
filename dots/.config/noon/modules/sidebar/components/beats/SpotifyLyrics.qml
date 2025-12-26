import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import QtQuick.Effects
import qs.modules.common.widgets
import qs.services
import qs.modules.common
import qs.modules.common.functions


Item {
    id: root
    
    anchors.fill: parent
    z: -1
    
    property int coverArtSize: 320
    
    readonly property real scale: (parent.height + parent.width) / 1000
    readonly property var displayLines: syncedLines.length > 0 ? syncedLines : plainLines
    readonly property bool loading: LyricsService.state === LyricsService.Loading
    readonly property bool hasError: LyricsService.state === LyricsService.NetworkError
    readonly property bool noLyricsFound: LyricsService.state === LyricsService.NoLyricsFound
    readonly property bool showContent: !loading && displayLines.length > 0
    readonly property int currentLineIndex: getCurrentIndex()
    
    property var syncedLines: []
    property var plainLines: []

    readonly property var stateTexts: ({
        [LyricsService.Loading]: "Loading",
        [LyricsService.NetworkError]: "Network error",
        [LyricsService.NoLyricsFound]: "No lyrics",
        [LyricsService.HasSyncedLyrics]: "Synced",
        [LyricsService.HasPlainLyrics]: "Plain"
    })

    readonly property var stateIcons: ({
        [LyricsService.Idle]: "bedtime",
        [LyricsService.NetworkError]: "cloud_off",
        [LyricsService.NoLyricsFound]: "music_off",
        [LyricsService.Loading]: "hourglass_empty"
    })

    function getCurrentIndex() {
        if (!displayLines?.length || !syncedLines.length) return -1;
        
        const progress = BeatsService.currentTrackProgress;
        for (let i = displayLines.length - 1; i >= 0; i--) {
            if (progress >= displayLines[i].lineTime) return i;
        }
        return 0;
    }

    function parseLyrics(text, synced) {
    if (!text) return [];
    
    return text.split("\n")
        .map(line => {
            if (synced) {
                const m = line.match(/\[(\d+):(\d+\.\d+)\](.*)/);
                return m ? {
                    lineTime: parseInt(m[1]) * 60 + parseFloat(m[2]),
                    lineText: m[3].trim()
                } : null;
            }
            return { lineTime: 0, lineText: line.trim() };
        })
        .filter(l => l && (!synced || l.lineText));
}

    
    function updateLyrics() {
        const data = LyricsService.onlineLyricsData;
        
        syncedLines = data?.syncedLyrics ? parseLyrics(data.syncedLyrics, true) : [];
        plainLines = !syncedLines.length && data?.plainLyrics ? parseLyrics(data.plainLyrics, false) : [];
        
        if (data) {
            revealer.reveal = true;
            revealTimer.restart();
        }
    }

    Component.onCompleted: updateLyrics()
    
    Connections {
        target: LyricsService
        function onOnlineLyricsDataChanged() { updateLyrics() }
    }

    RippleButton {
        id: floatRect
        
        z: 1
        anchors { top: parent.top; right: parent.right; margins: Padding.verylarge }
        
        implicitHeight: 40
        implicitWidth: row.implicitWidth + 2 * Padding.large
        colBackground: TrackColorsService.colors.colSecondaryContainer
        buttonRadius: Rounding.verylarge
        
        altAction: LyricsService.fetchFromAPI
        onClicked: hasError ? 
            LyricsService.fetchLyrics(BeatsService.artist || "", BeatsService.title || "") :
            (revealer.reveal = !revealer.reveal)

        Timer {
            id: revealTimer
            interval: 1000
            onTriggered: revealer.reveal = false
        }

        RowLayout {
            id: row
            anchors { fill: parent; margins: Padding.large }
            spacing: Padding.normal

            Revealer {
                id: revealer
                visible: reveal
                reveal: floatRect.showTitle || hasError || noLyricsFound

                StyledText {
                    color: icon.color
                    font.pixelSize: Fonts.sizes.normal
                    animateChange: true
                    text: stateTexts[LyricsService.state] || "Enjoy"
                }
            }

            MaterialSymbol {
                id: icon
                fill: 1
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: Fonts.sizes.normal
                color: hasError ? Colors.m3.m3error : 
                       noLyricsFound ? TrackColorsService.colors.colTertiary : 
                       TrackColorsService.colors.colSecondary
                text: stateIcons[LyricsService.state] || "lyrics"
            }
        }
    }

    MaterialLoadingIndicator {
        anchors.centerIn: parent
        visible: root.loading
        implicitSize: 240
        color: TrackColorsService.colors.colPrimary
        shapeColor: TrackColorsService.colors.colOnPrimary
    }

    Loader {
        anchors.centerIn: parent
        width: coverArtSize
        height: coverArtSize
        active: !loading && !displayLines.length
        sourceComponent: MusicCoverArt {
            anchors.fill: parent
            clip: true
            radius:Rounding.massive
            enableShadows: true
            enableBorders: false
        }
    }

    StyledFlickable {
        id: flick
        
        visible: showContent
        anchors { fill: parent; leftMargin: Padding.verylarge }
        boundsBehavior: Flickable.StopAtBounds
        interactive: false
        
        Column {
            id: column
            width: parent.width
            spacing: 22

            Repeater {
                model: displayLines
                
                delegate: StyledText {
                    required property int index
                    required property var modelData
                    
                    width: column.width
                    font.family: "Rubik"
                    font.variableAxes: Fonts.variableAxes.lyrics
                    font.pixelSize: index === currentLineIndex ? 
                        Fonts.sizes.title * scale : 
                        Fonts.sizes.verylarge * scale
                    text: modelData.lineText
                    color: TrackColorsService.colors.colOnLayer2
                    wrapMode: Text.Wrap
                    opacity: Math.max(0.2, 1 - Math.abs(index - currentLineIndex) / 4)

                    Behavior on font.pixelSize { Anim {} }
                    Behavior on opacity { Anim {} }
                }
            }
        }

        Timer {
            interval: 25
            running: showContent && currentLineIndex >= 0 && column.height > flick.height
            repeat: true
            onTriggered: {
                const lineItem = column.children[currentLineIndex];
                if (lineItem) {
                    flick.contentY += (lineItem.y - flick.height / 2 + lineItem.height / 2 - flick.contentY) * 0.4;
                }
            }
        }
    }
}
