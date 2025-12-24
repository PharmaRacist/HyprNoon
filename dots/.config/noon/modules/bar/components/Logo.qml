import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

MouseArea {
    id: logoComponent

    property var barRoot
    property bool hovered: false
    property int iconSize: BarData.currentBarExclusiveSize * 0.85
    property bool bordered: bg && Mem.options.bar.appearance.modulesBg
    property bool bg: true

    hoverEnabled: true
    Layout.alignment: Qt.AlignCenter
    implicitWidth: iconSize
    implicitHeight: iconSize

    Rectangle {
        id: background

        width: iconSize
        height: iconSize
        radius: Rounding.normal
        color: logoComponent.bordered ? Colors.colLayer2 : "transparent"
        scale: hovered ? 1.2 : 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: hovered = true
            onExited: hovered = false
            onClicked: Noon.callIpc("sidebar_launcher reveal Tweaks")
        }

        CustomIcon {
            id: distroIcon

            anchors.centerIn: background
            width: background.width * 0.65
            height: background.height * 0.65
            source: SysInfoService.distroIcon
        }

        ColorOverlay {
            anchors.fill: distroIcon
            source: distroIcon
            color: hovered ? Colors.colPrimary : Colors.m3.m3onSecondaryContainer

            Behavior on color {
                CAnim {
                }

            }

        }

        Behavior on scale {
            Anim {
            }

        }

    }

}
