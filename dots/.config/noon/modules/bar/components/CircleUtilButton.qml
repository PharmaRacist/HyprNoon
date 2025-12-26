import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Button {
    id: button

    required default property Item content
    property bool extraActiveCondition: false

    implicitHeight: Math.max(content.implicitHeight, 26, content.implicitHeight)
    implicitWidth: Math.max(content.implicitHeight, 26, content.implicitWidth)
    contentItem: content

    PointingHandInteraction {
    }

    background: Rectangle {
        anchors.fill: parent
        radius: Rounding.full
        color: (button.down || extraActiveCondition) ? Colors.colLayer1Active : (button.hovered ? Colors.colLayer1Hover : ColorUtils.transparentize(Colors.colLayer1, 1))
    }

}
