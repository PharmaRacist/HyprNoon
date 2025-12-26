import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.functions
import qs.services

IconImage {
    id: root

    property real tint: 0.6
    property bool colorize: Mem.options.appearance.icons.tint
    property color tintColor: Colors.m3.m3surfaceTint
    property bool cache: backer.cache

    backer.cache: cache
    smooth: true
    antialiasing: true
    mipmap: true

    Loader {
        opacity: 1 - root.tint
        active: colorize
        anchors.fill: root
        asynchronous: true

        sourceComponent: Item {
            ColorOverlay {
                z: 1
                anchors.fill: parent
                source: root
                color: root.tintColor
            }

        }

    }

}
