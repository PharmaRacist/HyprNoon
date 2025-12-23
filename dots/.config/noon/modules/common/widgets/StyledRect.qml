import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick.Effects

Rectangle {
    id: root
    property bool enableShadows: false
    property bool enableBorders: false
    property int rightRadius
    property int leftRadius
    property int topRadius
    property int bottomRadius

    topRightRadius: Math.max(rightRadius, topRadius, radius)
    bottomRightRadius: Math.max(rightRadius, bottomRadius, radius)
    topLeftRadius: Math.max(leftRadius, topRadius, radius)
    bottomLeftRadius: Math.max(leftRadius, bottomRadius, radius)

    color: Colors.colPrimaryContainer
    border.color: enableBorders ? Colors.colOutline : "transparent"
    border.width: 1

    layer.enabled: clip
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root?.width
            height: root?.height
            radius: root?.radius
            topRightRadius: root?.topRightRadius
            bottomRightRadius: root?.bottomRightRadius
            topLeftRadius: root?.topLeftRadius
            bottomLeftRadius: root?.bottomLeftRadius
        }
    }

    Behavior on color {
        CAnim {}
    }

    Behavior on opacity {
        Anim {}
    }
    Behavior on width {
        Anim {}
    }
    Behavior on height {
        Anim {}
    }

    Behavior on implicitWidth {
        Anim {}
    }
    Behavior on implicitHeight {
        Anim {}
    }

    StyledRectangularShadow {
        visible: root.enableShadows
        target: parent
    }
}
