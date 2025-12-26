import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

Menu {
    id: contextMenu
    Material.theme: Material.Dark
    Material.primary: Colors.colPrimaryContainer
    Material.accent: Colors.colSecondaryContainer
    Material.roundedScale: Rounding.normal
    Material.elevation: 8

    background: Rectangle {
        implicitWidth: 255
        implicitHeight: 26 * (parent.contentItem.children.length + 1)
        color: Colors.colLayer0
        radius: Rounding.verylarge
        clip: true

        // Simplified shadow: Use Layer with GaussianBlur for lighter GPU load (optimization)
        layer.enabled: parent.Material.elevation > 0
        layer.effect: GaussianBlur {
            radius: 8  // Reduced from DropShadow's 17 samples
        }
    }

    enter: Transition {
        Anim{
            property: "opacity"
            from: 0
            to: 1
            duration:Animations.durations.small
        }
        Anim{
            property: "scale"
            from: 0.95
            to: 1
            duration:Animations.durations.small
        }
    }

    exit: Transition {
        Anim{
            property: "opacity"
            from: 1
            to: 0
            duration:Animations.durations.small
        }
        Anim{
            property: "scale"
            from: 1
            to: 0.95
            duration:Animations.durations.small
        }
    }

    MenuItem {
        text: " Launch"
        Material.foreground: Colors.colOnLayer2
        Material.accent: Colors.colPrimary
        background: Rectangle {
            color: parent.hovered ? Colors.colOnSurface : "transparent"
            radius: Rounding.normal
            anchors.margins: Padding.small
            anchors.leftMargin: Padding.large
            anchors.rightMargin: Padding.large
            anchors.fill: parent
            opacity: parent.hovered ? 0.08 : 0
        }
        onTriggered: appGridView.appLaunched(model)
    }

    MenuItem {
        text: appItem.isPinned ? " Unpin from Dock" : " Pin to Dock"
        Material.foreground: Colors.colOnSurface
        Material.accent: Colors.colPrimary
        background: Rectangle {
            color: parent.hovered ? Colors.colOnSurface : "transparent"
            radius: Rounding.normal
            anchors.margins: Padding.small
            anchors.leftMargin: Padding.large
            anchors.rightMargin: Padding.large
            anchors.fill: parent
            opacity: parent.hovered ? 0.08 : 0
        }
        onTriggered: {
            const normalizedAppId = appItem.appId.toLowerCase();
            if (appItem.isPinned) {
                Mem.states.dock.pinnedApps = Mem.states.dock.pinnedApps.filter(id => id.toLowerCase() !== normalizedAppId);
            } else {
                if (!Mem.states.dock.pinnedApps.some(id => id.toLowerCase() === normalizedAppId)) {
                    Mem.states.dock.pinnedApps = [...Mem.states.dock.pinnedApps, appItem.appId];
                }
            }
        }
    }

    onClosed: {
        if (appGridView.currentMenu === contextMenu) {
            appGridView.currentMenu = null;
        }
        if (appGridView.menuIndex === index) {
            appGridView.currentIndex = -1;
            appGridView.menuIndex = -1;
        }
    }
}
