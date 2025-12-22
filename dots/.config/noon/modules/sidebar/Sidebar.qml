import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.store

Scope {
    id: root
    property bool pinned: Mem.states.sidebar.behavior.pinned
    property bool barMode: true
    property bool seekOnSuper: Mem.options.sidebar.behavior.superHeldReveal
    property int sidebarWidth: LauncherData.currentSize(barMode, launcherContent.expanded, launcherContent.selectedCategory) + (launcherContent.auxVisible && !barMode ? LauncherData.sizePresets.contentQuarter : 0)
    property bool reveal: (hoverArea.containsMouse && root.barMode) || _isTransitioning || (seekOnSuper ? GlobalStates.superHeld : null) || PolkitService.flow !== null
    property bool _isTransitioning: false
    property bool shouldFocus: GlobalStates.sidebarOpen && !barMode
    function hideLauncher() {
        if (root._isTransitioning)
            return;

        root._isTransitioning = true;
        root.reveal = true;
        root.finalizeHide();
    }

    function showLauncher() {
        if (root._isTransitioning)
            return;

        root.barMode = false;
        GlobalStates.sidebarOpen = true;
        Mem.states.sidebar.behavior.expanded = true;
        launcherContent.forceActiveFocus();
    }

    function finalizeHide() {
        root._isTransitioning = false;
        root.barMode = true;
        Mem.states.sidebar.behavior.expanded = false;
        if (!pinned)
            root.reveal = Qt.binding(function () {
                return (hoverArea.containsMouse && root.barMode) || _isTransitioning || (seekOnSuper ? GlobalStates.superHeld : null) || PolkitService.flow !== null;
            });

        if (launcherContent.clearSearch)
            launcherContent.clearSearch();
    }
    function togglePin() {
        Mem.states.sidebar.behavior.pinned = !Mem.states.sidebar.behavior.pinned;
    }
    Binding {
        target: GlobalStates
        property: "sidebarHovered"
        value: root.reveal
    }
    Binding {
        target: LauncherData
        property: "sidebarWidth"
        value: sidebarWidth
    }
    Binding {
        target:GlobalStates
        property: "sidebarOpen"
        value:!barMode
    }
    StyledPanel {
        id: dashboardRoot
        name: "sidebar"
        visible: true
        implicitWidth: visualContainer.width + visualContainer.rounding
        exclusiveZone: root.pinned ? implicitWidth - visualContainer.rounding : 0
        aboveWindows: true
        kbFocus: root.shouldFocus
        WlrLayershell.layer: LauncherData?.isOverlay(launcherContent.selectedCategory) ? WlrLayer.Overlay : WlrLayer.Top

        anchors {
            left: !visualContainer.rightMode || !root.pinned
            top: true
            right: visualContainer.rightMode || !root.pinned
            bottom: true
        }

        RoundCorner {
            id: c1
            visible: visualContainer.mode === 2
            corner: visualContainer.rightMode ? cornerEnum.bottomRight : cornerEnum.bottomLeft
            color: visualContainer.color
            size: visualContainer.rounding
            anchors {
                left: visualContainer.rightMode ? undefined : visualContainer.right
                right: visualContainer.rightMode ? visualContainer.left : undefined
                bottom: visualContainer.bottom
                bottomMargin: Mem.options.bar.behavior.position === "bottom" ? 0 : Sizes.frameThickness
            }
        }

        RoundCorner {
            visible: c1.visible
            corner: visualContainer.rightMode ? cornerEnum.topRight : cornerEnum.topLeft
            color: visualContainer.color
            size: c1.size
            anchors {
                top: visualContainer.top
                left: visualContainer.rightMode ? undefined : visualContainer.right
                right: visualContainer.rightMode ? visualContainer.left : undefined
                topMargin: Mem.options.bar.behavior.position === "top" ? 0 : Sizes.frameThickness
            }
        }

        StyledRect {
            id: visualContainer

            property bool rightMode: Mem.options.bar?.behavior?.position === "left" ?? true
            property int mode: Mem.options.sidebar.appearance.mode
            property int rounding: Rounding.verylarge
            property real horizontalMargin: (!root.barMode || root.reveal) ? -1 : -(width - 1)
            enableShadows: true
            width: root.sidebarWidth
            color: launcherContent.contentColor
            topRightRadius: !rightMode && mode === 1 ? Rounding.verylarge : 0
            bottomRightRadius: !rightMode && mode === 1 ? Rounding.verylarge : 0
            topLeftRadius: rightMode && mode === 1 ? Rounding.verylarge : 0
            bottomLeftRadius: rightMode && mode === 1 ? Rounding.verylarge : 0
            anchors {
                topMargin: mode === 1 && Mem.options.bar.behavior.position !== "top" ? Sizes.frameThickness : 0
                bottomMargin: mode === 1 && Mem.options.bar.behavior.position !== "bottom" ? Sizes.frameThickness : 0
                top: parent.top
                bottom: parent.bottom
                left: !rightMode ? parent.left : undefined
                right: rightMode ? parent.right : undefined
                leftMargin: !rightMode ? horizontalMargin : 0
                rightMargin: rightMode ? horizontalMargin : 0
                margins: 0
            }

            MouseArea {
                id: hoverArea
                enabled: root.barMode
                z: 999
                anchors.fill: parent
                hoverEnabled: true
                anchors.margins: -1
                acceptedButtons: Qt.NoButton
            }

            Content {
                id: launcherContent
                rightMode: visualContainer.rightMode
                panelWindow: dashboardRoot
                showContent: !root.barMode
                pinned: root.pinned
                onRequestPin: root.togglePin()
            }

            Behavior on anchors.leftMargin {
                Anim {
                    duration: Animations.durations.small
                    easing.bezierCurve: Animations.curves.emphasized
                }
            }

            Behavior on anchors.rightMargin {
                Anim {
                    duration: Animations.durations.small
                    easing.bezierCurve: Animations.curves.emphasized
                }
            }

            Behavior on width {
                Anim {
                    duration: Animations.durations.normal
                    easing.bezierCurve: Animations.curves.emphasized
                }
            }
            Behavior on color {
                CAnim {
                    duration: Animations.durations.verylarge
                    easing.bezierCurve: Animations.curves.emphasized
                }
            }
            Behavior on radius {
                FAnim {
                    duration: Animations.durations.normal
                    easing.bezierCurve: Animations.curves.emphasized
                }
            }
        }
        SidebarBubble {
            show: !root.barMode
            rightMode:visualContainer.rightMode
            selectedCategory:launcherContent.selectedCategory
            anchors {
                right: !visualContainer.rightMode ? undefined : visualContainer.left
                left: visualContainer.rightMode ? undefined : visualContainer.right
                bottom: visualContainer.bottom
                margins: Padding.verylarge
            }

        }
        HyprlandFocusGrab {
            id: grab

            windows: [dashboardRoot]
            active: root.shouldFocus
            onCleared: if (!root.pinned)
                root.hideLauncher()
        }
        mask: Region {
            item: visualContainer
        }
    }

    Connections {
        function onHideBarRequested() {
            GlobalStates.sidebarOpen = false;
            root.hideLauncher();
        }

        function onAppLaunched() {
            if (root.barMode) {
                root.reveal = false;
                root.reveal = Qt.binding(function () {
                    return hoverArea.containsMouse && root.barMode && GlobalStates.sidebarOpen;
                });
            } else {
                root.hideLauncher();
            }
        }

        function onDismiss() {
            root.hideLauncher();
        }

        function onContentToggleRequested() {
            if (!root.barMode)
                root.hideLauncher();
            else
                root.showLauncher();
        }

        target: launcherContent
    }
    IpcHandler {
        target: "sidebar_launcher"
        function reveal_aux(cat: string) {
            launcherContent.auxReveal(cat);
        }
        function reveal(cat: string) {
            launcherContent.requestCategoryChange(cat);
        }
        function pin() {
            root.togglePin();
        }
        function hide() {
            root.hideLauncher();
        }
    }
}
