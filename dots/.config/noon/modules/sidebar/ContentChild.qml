import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

Item {
    id: panel

    // Required properties
    required property string category
    required property string searchText
    required property var dataModel
    required property var componentMap
    required property var parentRoot
    required property bool isAux
    property bool showContent
    property bool effectiveSearchable: category ? SidebarData.isSearchable(category) : false
    property alias searchInput: searchInput
    property real contentYOffset: 0
    property real contentOpacity: 1
    property string previousCategory: ""

    // Unified signals
    signal searchUpdated(string newText)
    signal contentFocusRequested()
    signal searchFocusRequested()

    // Helper function to determine animation direction
    function getCategoryDirection(oldCat, newCat) {
        if (!oldCat || !newCat || oldCat === newCat)
            return 1;

        const categories = SidebarData.enabledCategories || [];
        const oldIndex = categories.indexOf(oldCat);
        const newIndex = categories.indexOf(newCat);
        if (oldIndex !== -1 && newIndex !== -1)
            return newIndex > oldIndex ? -1 : 1;

        return 1; // Default to downward motion
    }

    onCategoryChanged: {
        if (category && category !== previousCategory && previousCategory !== "") {
            const direction = getCategoryDirection(previousCategory, category);
            contentYOffset = direction * 100;
            contentOpacity = 0;
            resetAnimation.restart();
        }
        previousCategory = category;
        // Force reload of content when category changes
        if (category) {
            contentLoader.sourceComponent = null;
            Qt.callLater(() => {
                const componentName = SidebarData.getComponent(category);
                contentLoader.sourceComponent = componentMap[componentName] || null;
            });
        }
    }

    ColumnLayout {
        spacing: Padding.large
        clip: true
        anchors.fill: parent

        ParallelAnimation {
            id: resetAnimation

            Anim {
                target: panel
                property: "contentYOffset"
                to: 0
            }

            Anim {
                target: panel
                property: "contentOpacity"
                to: 1
            }

        }

        Loader {
            id: contentLoader

            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true
            asynchronous: isAux
            opacity: contentOpacity
            sourceComponent: {
                if (!category)
                    return null;

                const componentName = SidebarData.getComponent(category);
                return componentMap[componentName] || null;
            }
            onLoaded: {
                if (item) {
                    if ("model" in item)
                        item.model = dataModel;

                    if ("selectedCategory" in item)
                        item.selectedCategory = Qt.binding(() => {
                        return category;
                    });

                    if ("searchQuery" in item)
                        item.searchQuery = Qt.binding(() => {
                        return searchText;
                    });

                    if ("expanded" in item) {
                        // Aux always collapsed, main follows parent's expanded state
                        if (isAux)
                            item.expanded = false;
                        else
                            item.expanded = Qt.binding(() => {
                            return parentRoot.expanded;
                        });
                    }
                    if ("panelWindow" in item && !isAux)
                        item.panelWindow = parentRoot.panelWindow;

                    if ("sidebarMode" in item && !isAux)
                        item.sidebarMode = true;

                }
            }

            Connections {
                function onSearchFocusRequested() {
                    if (!isAux && searchInput && effectiveSearchable)
                        searchInput.forceActiveFocus();

                }

                function onContentFocusRequested() {
                    if (contentLoader.item && "contentFocusRequested" in contentLoader.item)
                        contentLoader.item.contentFocusRequested();

                }

                target: panel
            }

            Connections {
                function onSearchFocusRequested() {
                    if (!isAux)
                        panel.searchFocusRequested();

                }

                function onAltLaunched(app) {
                    SidebarData.altLaunch(app, isAux);
                }

                function onAppLaunched(app) {
                    SidebarData.launch(category, app, parentRoot.switchToLayout, isAux);
                }

                target: contentLoader.item
                ignoreUnknownSignals: true
            }

            transform: Translate {
                y: contentYOffset
            }

        }

        // Search Bar
        StyledRect {
            id: searchBar

            visible: opacity > 0
            clip: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: SidebarData.sizePresets.quarter
            Layout.preferredHeight: effectiveSearchable ? 45 : 0
            Layout.margins: effectiveSearchable ? Padding.normal : 0
            radius: Rounding.normal
            color: Colors.colLayer1
            opacity: effectiveSearchable ? contentOpacity : 0

            Rectangle {
                id: sideRect

                color: Colors.colSecondary
                implicitWidth: 40

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: Padding.tiny
                    font.pixelSize: 20
                    text: SidebarData.getIcon(category) || "apps"
                    color: Colors.colOnSecondary
                    opacity: 0.6
                }

            }

            RowLayout {
                spacing: Padding.small

                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                    left: sideRect.right
                    leftMargin: Padding.normal
                }

                StyledTextField {
                    id: searchInput

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    objectName: "searchInput"
                    visible: effectiveSearchable
                    enabled: effectiveSearchable
                    text: searchText
                    placeholderText: SidebarData.getPlaceholder(category) || "Search..."
                    background: null
                    selectionColor: Colors.colSecondaryContainer
                    selectedTextColor: Colors.m3.m3onSecondaryContainer
                    color: Colors.m3.m3onSurfaceVariant
                    placeholderTextColor: Colors.m3.m3outline
                    selectByMouse: true
                    onTextChanged: {
                        panel.searchUpdated(text);
                    }
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Down && effectiveSearchable || event.key === Qt.Key_PageDown && effectiveSearchable) {
                            panel.contentFocusRequested();
                            event.accepted = true;
                        }
                    }

                    font {
                        family: Fonts.family.main
                        pixelSize: Fonts.sizes.small
                    }

                }

                RippleButton {
                    buttonRadius: 12
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    visible: searchInput.text.length > 0
                    colBackground: "transparent"
                    releaseAction: () => {
                        searchInput.clear();
                        if (!isAux)
                            Qt.callLater(() => {
                            return searchInput.forceActiveFocus();
                        });

                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        font.pixelSize: 16
                        text: "close"
                        color: Colors.m3.m3onSurfaceVariant
                    }

                }

            }

            transform: Translate {
                y: contentYOffset
            }

            Behavior on Layout.preferredHeight {
                Anim {
                }

            }

        }

        // Close button (only for aux panel)
        RippleButton {
            visible: isAux
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: parent.width - Padding.veryhuge
            Layout.preferredHeight: 32
            buttonRadius: 16
            colBackground: Colors.colError
            colBackgroundHover: Colors.colErrorHover
            opacity: contentOpacity
            releaseAction: () => {
                if (isAux && parentRoot)
                    parentRoot.closeAuxPanel();

            }

            RowLayout {
                anchors.centerIn: parent

                MaterialSymbol {
                    font.pixelSize: 20
                    text: "close"
                    color: Colors.m3.m3onError
                }

                StyledText {
                    text: "Dismiss"
                    color: Colors.m3.m3onError
                }

            }

            transform: Translate {
                y: contentYOffset
            }

        }

    }

    PagePlaceholder {
        visible: dataModel.count === 0 && SidebarData.hasModel(category) && showContent
        opacity: visible ? contentOpacity : 0
        icon: "block"
        shape: MaterialShape.Clover4Leaf
        title: "Nothing found"

        transform: Translate {
            y: contentYOffset
        }

        Behavior on opacity {
            Anim {
            }

        }

    }

}
