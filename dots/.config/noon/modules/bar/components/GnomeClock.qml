import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledText {
    font.family: "Rubik"
    font.pixelSize: Fonts.sizes.normal
    color: Colors.m3.m3onSurfaceVariant
    text: DateTimeService.gnomeClockWidgetFormat

    MouseArea {
        anchors.fill: parent
        onClicked: Noon.callIpc("sidebar_launcher reveal Apps")
    }

}
