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


StyledPanel {
    id: root
    name: "sidebar"
    visible: true
    
    property bool pinned: Mem.states.sidebar.behavior.pinned
    property bool barMode: true
    property bool seekOnSuper: Mem.options.sidebar.behavior.superHeldReveal
    property int sidebarWidth: LauncherData.currentSize(barMode, launcherContent.expanded, launcherContent.selectedCategory) + (launcherContent.auxVisible && !barMode ? LauncherData.sizePresets.contentQuarter : 0)
    property bool reveal: (hoverArea.containsMouse && barMode) || _isTransitioning || (seekOnSuper ? GlobalStates.superHeld : null) || PolkitService.flow !== null
    property bool _isTransitioning: false
    property bool noExlusiveZone: Mem.options.bar.appearance.mode === 0 && (Mem.options.bar.behavior.position === "top" || Mem.options.bar.behavior.position === "bottom")
    
    implicitWidth: visualContainer.width + visualContainer.rounding
    exclusiveZone: !barMode && pinned ? implicitWidth - visualContainer.rounding : noExlusiveZone ? -1 : 0
    aboveWindows: true
    kbFocus: GlobalStates.sidebarOpen && !barMode
    WlrLayershell.layer: LauncherData?.isOverlay(launcherContent.selectedCategory) ? WlrLayer.Overlay : WlrLayer.Top
    
    anchors {
        left: !visualContainer.rightMode || !pinned
        top: true
        right: visualContainer.rightMode || !pinned
        bottom: true
    }
    
    function hideLauncher() {
        if (_isTransitioning) return;
        
        _isTransitioning = true;
        reveal = true;
        finalizeHide();
    }

    function showLauncher() {
        if (_isTransitioning) return;
        
        barMode = false;
        GlobalStates.sidebarOpen = true;
        Mem.states.sidebar.behavior.expanded = true;
        launcherContent.forceActiveFocus();
    }

    function finalizeHide() {
        _isTransitioning = false;
        barMode = true;
        Mem.states.sidebar.behavior.expanded = false;
        
        if (!pinned) {
            reveal = Qt.binding(() => (hoverArea.containsMouse && barMode) || _isTransitioning || (seekOnSuper ? GlobalStates.superHeld : null) || PolkitService.flow !== null);
        }
        
        if (launcherContent.clearSearch) launcherContent.clearSearch();
    }
    
    function togglePin() {
        Mem.states.sidebar.behavior.pinned = !pinned;
    }
    
    Binding {
        target: GlobalStates
        property: "sidebarHovered"
        value: reveal
    }
    
    Binding {
        target: LauncherData
        property: "sidebarWidth"
        value: sidebarWidth
    }
    
    Binding {
        target: GlobalStates
        property: "sidebarOpen"
        value: !barMode
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

    Item {
        id: interactiveContainer
        
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: !visualContainer.rightMode ? parent.left : undefined
            right: visualContainer.rightMode ? parent.right : undefined
        }
        
        width: visualContainer.width + (bubble.visible ? bubble.width + Padding.verylarge * 2 : 0)

        StyledRect {
            id: visualContainer

            property bool rightMode: Mem.options.bar?.behavior?.position === "left" ?? true
            property int mode: Mem.options.sidebar.appearance.mode
            property int rounding: Rounding.verylarge
            
            enableShadows: true
            width: sidebarWidth
            color: launcherContent.contentColor
            
            topRightRadius: !rightMode && mode === 1 ? rounding : 0
            bottomRightRadius: !rightMode && mode === 1 ? rounding : 0
            topLeftRadius: rightMode && mode === 1 ? rounding : 0
            bottomLeftRadius: rightMode && mode === 1 ? rounding : 0
            
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: !rightMode ? parent.left : undefined
                right: rightMode ? parent.right : undefined
                leftMargin: !rightMode ? ((!barMode || reveal) ? -1 : -(width - 1)) : 0
                rightMargin: rightMode ? ((!barMode || reveal) ? -1 : -(width - 1)) : 0
                topMargin: mode === 1 && Mem.options.bar.behavior.position !== "top" ? Sizes.frameThickness : 0
                bottomMargin: mode === 1 && Mem.options.bar.behavior.position !== "bottom" ? Sizes.frameThickness : 0
            }

            MouseArea {
                id: hoverArea
                enabled: barMode
                z: 999
                anchors.fill: parent
                anchors.margins: -1
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            Content {
                id: launcherContent
                rightMode: visualContainer.rightMode
                panelWindow: root
                showContent: !barMode
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
            id: bubble
            show: !barMode
            rightMode: visualContainer.rightMode
            selectedCategory: launcherContent.selectedCategory
            
            anchors {
                right: !visualContainer.rightMode ? undefined : visualContainer.left
                left: visualContainer.rightMode ? undefined : visualContainer.right
                bottom: visualContainer.bottom
                margins: Padding.verylarge
            }
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: GlobalStates.sidebarOpen && !barMode
        onCleared: if (!pinned) hideLauncher()
    }
    
    mask: Region { item: interactiveContainer }

    Connections {
        target: launcherContent
        
        function onHideBarRequested() {
            GlobalStates.sidebarOpen = false;
            hideLauncher();
        }

        function onAppLaunched() {
            if (barMode) {
                reveal = false;
                reveal = Qt.binding(() => hoverArea.containsMouse && barMode && GlobalStates.sidebarOpen);
            } else {
                hideLauncher();
            }
        }

        function onDismiss() {
            hideLauncher();
        }

        function onContentToggleRequested() {
            barMode ? showLauncher() : hideLauncher();
        }
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
            togglePin();
        }
        
        function hide() {
            hideLauncher();
        }
    }
}
