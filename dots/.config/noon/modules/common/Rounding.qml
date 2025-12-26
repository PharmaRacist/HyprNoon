import QtQuick
import Quickshell
import qs.modules.common
pragma Singleton

Singleton {
    property real scale: Mem.options.appearance.rounding.scale
    property int tiny: 2 * scale
    property int verysmall: 4 * scale
    property int small: 6 * scale
    property int normal: 8 * scale
    property int large: 10 * scale
    property int verylarge: 16 * scale
    property int huge: 18 * scale
    property int massive: 24 * scale
    property int full: 999

    onScaleChanged: Noon.setHyprKey("decoration:rounding", verylarge)
}
