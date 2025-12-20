import "./widgets"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledRect {
    // gradient: Gradient {
    //     GradientStop {
    //         position: 0
    //         color: Colors.colLayer1
    //     }
    //     GradientStop {
    //         position: 0.95
    //         color: "transparent"
    //     }
    // }

    id: root

    implicitWidth: 450
    implicitHeight: parent.height
    color: "transparent"
    clip: true
    topRadius: Rounding.huge

    anchors {
        bottomMargin: -parent.height - 2 * Padding.massive
        bottom: parent.bottom
        left: parent.left
        margins: Padding.massive
    }

    ColumnLayout {
        z: 99

        anchors {
            fill: parent
            margins: Padding.large
            bottomMargin: 2 * Padding.massive
        }

        LockClock {
        }

        Spacer {
        }

        Row {
        }

        Weather {
        }

        Music {
        }

    }

    Anim on anchors.bottomMargin {
        from: -root.implicitHeight
        to: -Padding.massive
    }

}
