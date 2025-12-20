import "./widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledRect {
    id: root

    implicitWidth: 450
    implicitHeight: parent.height
    color: "transparent"
    clip: true
    topRadius: Rounding.huge

    anchors {
        bottomMargin: -parent.height - Padding.massive
        bottom: parent.bottom
        right: parent.right
        margins: Padding.massive
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Padding.massive
        }

        LockClock {
        }

        Weather {
        }

        Spacer {
        }

        Row {
        }

        Music {
        }

    }

    Anim on anchors.bottomMargin {
        from: -root.implicitHeight
        to: -Padding.massive
    }

    gradient: Gradient {
        GradientStop {
            position: 0
            color: Colors.colLayer1
        }

        GradientStop {
            position: 0.95
            color: "transparent"
        }

    }

}
