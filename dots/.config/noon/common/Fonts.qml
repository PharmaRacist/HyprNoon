import QtQuick
import Quickshell
import qs.common
pragma Singleton

Singleton {
    property QtObject family
    property QtObject sizes
    property QtObject variableAxes

    family: QtObject {
        readonly property string main: Mem.options.appearance.fonts.main ?? "Roboto Flex"
        readonly property string reading: "Rubik"
        readonly property string numbers: "Roboto Flex"
        readonly property string monospace: "Iosevka"
        readonly property string variable: "Roboto Flex"
        readonly property string iconMaterial: "Material Symbols Rounded"
    }

    sizes: QtObject {
        readonly property real scale: Mem.options.appearance.fonts.scale ?? 1
        readonly property int verysmall: 12 * scale
        readonly property int small: 14 * scale
        readonly property int normal: 16 * scale
        readonly property int large: 18 * scale
        readonly property int verylarge: 20 * scale
        readonly property int huge: 24 * scale
        readonly property int title: 46 * scale
        readonly property int subTitle: 32 * scale
    }

    variableAxes: QtObject {
        readonly property var main: ({
            "wght": 450,
            "wdth": 100
        })
        readonly property var lyrics: ({
            "wght": 600,
            "wdth": 100
        })
        readonly property var numbers: ({
            "wght": 550,
            "wdth": 100
        })
        readonly property var title: ({
            "wght": 650
        })
        readonly property var longNumbers: ({
            "wght": 500,
            "ytfi": 788,
            "opsz": 144,
            "wdth": 50
        })
        readonly property var display: ({
            "wght": Mem.states.fonts.variableAxes.display.wght,
            "wdth": Mem.states.fonts.variableAxes.display.wdth,
            "ital": Mem.states.fonts.variableAxes.display.ital,
            "slnt": Mem.states.fonts.variableAxes.display.slnt,
            "opsz": Mem.states.fonts.variableAxes.display.opsz
        })
    }

}
