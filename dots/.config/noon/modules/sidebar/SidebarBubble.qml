import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledRect {
    id: root

    property bool show
    property bool rightMode
    property string selectedCategory
    property alias containsMouse: mouse.containsMouse

    visible: width > 0 && !Mem.states.sidebar.behavior.pinned
    enableShadows: true
    radius: Rounding.verylarge
    color: Colors.m3.m3surface
    height: content.implicitHeight + 2 * Padding.large
    width: show ? 55 : 0

    MouseArea {
        id: mouse

        anchors.fill: parent
        propagateComposedEvents: true
        hoverEnabled: true
    }

    ColumnLayout {
        id: content

        spacing: Padding.verysmall

        anchors {
            centerIn: parent
        }

        RippleButtonWithIcon {
            visible: root.selectedCategory === "Walls"
            materialIcon: "shuffle"
            releaseAction: () => {
                return WallpaperService.shuffleWallpapers();
            }
        }

        RippleButtonWithIcon {
            toggled: Mem.states.sidebar.behavior.pinned
            materialIcon: "push_pin"
            releaseAction: () => {
                return Mem.states.sidebar.behavior.pinned = !Mem.states.sidebar.behavior.pinned;
            }
        }

        Separator {
        }

        RippleButtonWithIcon {
            materialIcon: !visualContainer.rightMode && Mem.states.sidebar.behavior.expanded ? "keyboard_double_arrow_left" : "keyboard_double_arrow_right"
            releaseAction: () => {
                return Mem.states.sidebar.behavior.expanded = !Mem.states.sidebar.behavior.expanded;
            }
        }

    }

    Behavior on height {
        Anim {
        }

    }

    Behavior on width {
        Anim {
        }

    }

}
