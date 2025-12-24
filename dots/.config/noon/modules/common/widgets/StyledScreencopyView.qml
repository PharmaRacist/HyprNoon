import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.modules.common
import qs.services

ScreencopyView {
    id: root

    property int radius: 0

    visible: HyprlandService.isHyprland
    live: true
    paintCursor: true
    layer.enabled: radius > 0

    layer.effect: OpacityMask {

        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: radius
        }

    }

}
