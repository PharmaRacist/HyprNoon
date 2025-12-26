import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.modules.common.functions

import qs.modules.common.widgets
import qs.modules.common
import qs.services

Loader {
    property bool loadCondition: false
    property bool transluscent: false
    property int cubeSize: 145
    property int cubeWidth: 145
    property string title: "title"
    Layout.alignment: Qt.AlignRight
    active: loadCondition
    sourceComponent: Rectangle {
        radius: Rounding.verylarge
        border.width: Mem.options.desktop?.desktopIsland.borderWidth ?? 4
        border.color: Colors.m3.m3surfaceContainerLow
        color: transluscent ? "transparent" : Colors.colLayer0
        implicitWidth: cubeWidth
        implicitHeight: cubeSize
        StyledRectangularShadow {
            target: parent
        }
        StyledText {
            color: Colors.colSubtext
            font.pixelSize: 15
            z: 999
            text: title
            anchors.left: parent.left
            anchors.leftMargin: 26
            anchors.top: parent.top
            anchors.topMargin: 16
        }
    }
}
