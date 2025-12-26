import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

StyledRect {
    property real padding: 0.85

    color: Mem.options.bar.appearance.modulesBg ? Colors.colLayer2 : "transparent"
    radius: Rounding.large
    clip: true
    implicitWidth: parent.implicitWidth //* padding
    implicitHeight: parent.implicitHeight // * padding
}
