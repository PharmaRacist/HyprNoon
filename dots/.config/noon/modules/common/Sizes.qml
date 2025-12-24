import QtQuick
import Quickshell
import qs.modules.common
import qs.services
pragma Singleton

Singleton {
    property real barElevation: hyprlandGapsOut / 4
    property real osdWidth: 220
    property real osdHeight: 45
    property real collapsedSideBarWidth: 50
    property real notificationPopupWidth: 420
    property real hyprlandGapsOut: HyprlandService.hyprlandGapsOut
    property real elevationValue: Padding.verylarge
    property real frameThickness: Mem.options.desktop.bg.borderMultiplier * (hyprlandGapsOut - Padding.normal)
    property real elevationMargin: frameThickness + elevationValue
    property var beamSize: Qt.size(450, 60)
    property var beamSizeExpanded: Qt.size(800, 100)
}
