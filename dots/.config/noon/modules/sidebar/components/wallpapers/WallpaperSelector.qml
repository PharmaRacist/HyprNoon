import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    property string searchQuery: ""
    property int gridColumns: expanded ? 5 : 1
    property int gridItemWidth: width / gridColumns
    property int gridItemHeight: gridItemWidth * (9 / 16)
    property bool expanded: false

    readonly property int itemSpacing: 8

    signal searchFocusRequested
    signal contentFocusRequested

    function updateGridModel() {
        if (!WallpaperService?.wallpaperModel) {
            Qt.callLater(updateGridModel)
            return
        }
        gridView.model = WallpaperService.wallpaperModel.count
    }

    function shuffleWallpaper() {
        if (gridView.model <= 0) return
        const randomIndex = Math.floor(Math.random() * gridView.model)
        const fileUrl = WallpaperService.wallpaperModel.getFile(randomIndex)
        if (fileUrl) {
            WallpaperService.applyWallpaper(fileUrl)
            gridView.currentIndex = randomIndex
        }
    }

    Component.onCompleted: updateGridModel()
    
    onSearchQueryChanged: {
        if (!WallpaperService?.wallpaperModel) return
        const model = WallpaperService.wallpaperModel
        if (searchQuery.length > 0) {
            model.filterWallpapers(searchQuery)
        } else {
            model.clearFilter()
        }
    }

    StyledRect {
        anchors.fill: parent
        color: "transparent"
        clip: true
        radius: Rounding.verylarge

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            StyledGridView {
                id: gridView
                property int currentIndex: -1

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: root.gridItemWidth
                cellHeight: root.gridItemHeight
                model: WallpaperService.wallpaperModel?.count ?? 0
                focus: true

                onCountChanged: {
                    if (count > 0 && currentIndex === -1 && activeFocus)
                        currentIndex = 0
                }

                Keys.onPressed: event => {
                    if (!gridView.model || gridView.model === 0) return

                    const cols = root.gridColumns
                    const shift = event.modifiers & Qt.ShiftModifier
                    const jump = shift ? 5 : 1
                    const page = Math.floor(gridView.height / root.gridItemHeight) * cols

                    switch (event.key) {
                    case Qt.Key_Down:
                        if (currentIndex === -1) currentIndex = 0
                        else if (currentIndex + cols * jump < model) currentIndex += cols * jump
                        else currentIndex = model - 1
                        gridView.positionViewAtIndex(currentIndex, GridView.Contain)
                        event.accepted = true
                        break
                    case Qt.Key_Up:
                        if (currentIndex === -1) currentIndex = model - 1
                        else if (currentIndex >= cols * jump) currentIndex -= cols * jump
                        else if (currentIndex >= 0) {
                            if (shift) currentIndex = 0
                            else { currentIndex = -1; root.searchFocusRequested() }
                        }
                        gridView.positionViewAtIndex(currentIndex, GridView.Contain)
                        event.accepted = true
                        break
                    case Qt.Key_Left:
                        if (currentIndex === -1) currentIndex = 0
                        else if (currentIndex >= jump) currentIndex -= jump
                        else if (currentIndex > 0) currentIndex = 0
                        gridView.positionViewAtIndex(currentIndex, GridView.Contain)
                        event.accepted = true
                        break
                    case Qt.Key_Right:
                        if (currentIndex === -1) currentIndex = 0
                        else if (currentIndex + jump < model) currentIndex += jump
                        else currentIndex = model - 1
                        gridView.positionViewAtIndex(currentIndex, GridView.Contain)
                        event.accepted = true
                        break
                    case Qt.Key_PageDown:
                        currentIndex = (currentIndex === -1) ? 0 : Math.min(currentIndex + page, model - 1)
                        gridView.positionViewAtIndex(currentIndex, GridView.Contain)
                        event.accepted = true
                        break
                    case Qt.Key_PageUp:
                        currentIndex = (currentIndex === -1) ? model - 1 : Math.max(currentIndex - page, 0)
                        gridView.positionViewAtIndex(currentIndex, GridView.Contain)
                        event.accepted = true
                        break
                    case Qt.Key_Home:
                        if (model > 0) { currentIndex = 0; gridView.positionViewAtIndex(0, GridView.Beginning) }
                        event.accepted = true
                        break
                    case Qt.Key_End:
                        if (model > 0) { currentIndex = model - 1; gridView.positionViewAtIndex(model - 1, GridView.End) }
                        event.accepted = true
                        break
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        if (currentIndex >= 0 && currentIndex < model) {
                            const fileUrl = WallpaperService.wallpaperModel.getFile(currentIndex)
                            if (fileUrl) WallpaperService.applyWallpaper(fileUrl)
                        }
                        event.accepted = true
                        break
                    }
                }

                delegate: Item {
                    id: delegateItem
                    required property int index
                    width: root.gridItemWidth
                    height: root.gridItemHeight

                    WallpaperItem {
                        property int delegateIndex: index
                        isKeyboardSelected: delegateIndex === gridView.currentIndex && gridView.activeFocus
                        isCurrentWallpaper: fileUrl === WallpaperService.currentWallpaper
                        fileUrl: WallpaperService.wallpaperModel?.getFile(delegateIndex) ?? ""
                        onClicked: {
                            if (!fileUrl) return
                            WallpaperService.applyWallpaper(fileUrl)
                            gridView.currentIndex = delegateIndex
                        }

                        Behavior on anchors.margins { Anim {} }
                    }
                }
            }
        }

        Connections {
            target: WallpaperService?.wallpaperModel ?? null
            ignoreUnknownSignals: true
            function onModelUpdated() { root.updateGridModel() }
        }

        Connections {
            target: root
            function onContentFocusRequested() {
                if (gridView.model > 0) {
                    gridView.currentIndex = 0
                    gridView.forceActiveFocus()
                    gridView.positionViewAtIndex(0, GridView.Beginning)
                }
            }
        }

        PagePlaceholder {
            visible: gridView.model === 0 && root.searchQuery !== ""
            icon: "block"
            title: "Nothing found"
        }

        WallpaperControls {
        }
    }

}
