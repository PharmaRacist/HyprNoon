import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

MouseArea {
    id: root

    implicitHeight: BarData.currentBarExclusiveSize
    implicitWidth: 200
    hoverEnabled: true

    Rectangle {
        anchors.fill: parent
        color: Mem.options.bar.appearance.modulesBg ? Colors.colLayer1 : "transparent"
        radius: Rounding.small
        Layout.maximumWidth: implicitWidth

        StyledText {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Fonts.sizes.large
            color: Colors.colOnLayer1
            text: DateTimeService.gnomeClockWidgetFormat
        }

    }

}
