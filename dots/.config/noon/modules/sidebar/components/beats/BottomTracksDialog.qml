import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets
import qs.services

BottomDialog {
    id: bottomDialog

    z: 99
    expandedHeight: root.height * 0.76
    collapsedHeight: root.height * 0.46
    bottomAreaReveal: true
    hoverHeight: 200
    revealOnWheel: true
    enableStagedReveal: true

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Padding.verylarge
        spacing: Padding.large

        BottomDialogHeader {
            title: "Beats"
            subTitle: `There is ${BeatsService.filteredIndices.length} Tracks in your playlist !`

            RippleButtonWithIcon {
                materialIcon: "close"
                releaseAction: () => {
                    return bottomDialog.expand = false;
                }
            }
        }
        SearchBar {
            Layout.fillWidth: true
            implicitHeight: 40
            Layout.leftMargin: Padding.large
            Layout.rightMargin: Padding.large
            searchInput.placeholderText: "Search Tracks"
            color: "transparent"
            onSearchTextChanged: searchTimer.restart()

            Timer {
                id: searchTimer

                interval: 200
                onTriggered: BeatsService.updateSearchFilter(searchText)
            }
        }

        StyledListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Padding.normal
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
                shape: MaterialShape.Bun
                shapePadding: Padding.normal
                releaseAction: () => {
                    return BeatsService.playTrackByPath(trackPath);
                }
                altAction: () => {
                    return trackContextMenu.showMenu();
                }

                TrackContextMenu {
                    id: trackContextMenu

                    trackPath: parent.trackPath
                    trackName: parent.title
                    parentButton: parent
                }
            }
        }
    }
}
