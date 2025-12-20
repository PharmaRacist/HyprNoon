import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledRect {
    id: root

    visible: false
    Layout.preferredHeight: 160
    Layout.fillWidth: true
    Layout.margins: Padding.normal
    enableBorders: true
    enableShadows: true
    color: Colors.colLayer3
    radius: Rounding.verylarge

    ColumnLayout {
        anchors {
            fill: parent
            margins: Padding.verylarge
        }

    }

}
