import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.bar.components
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

MouseArea {
    id: root

    implicitHeight: columnLayout.height + Padding.huge
    implicitWidth: BarData.currentBarExclusiveSize
    hoverEnabled: true

    BarGroup {
        anchors.centerIn: parent
        implicitHeight: parent.implicitHeight
        implicitWidth: parent.implicitWidth * padding

        ColumnLayout {
            id: columnLayout

            anchors.centerIn: parent
            spacing: 6

            StyledText {
                font.pixelSize: Fonts.sizes.small
                color: Colors.colOnLayer1
                text: DateTimeService.hour
                font.variableAxes: Fonts.variableAxes.title
                Layout.alignment: Qt.AlignHCenter
            }

            StyledText {
                font.pixelSize: Fonts.sizes.small
                font.variableAxes: Fonts.variableAxes.title
                color: Colors.colOnLayer1
                text: DateTimeService.minute
                Layout.alignment: Qt.AlignHCenter
            }

            // Add AM/PM indicator for 12-hour format
            StyledText {
                font.pixelSize: Fonts.sizes.small
                font.variableAxes: Fonts.variableAxes.title
                color: Colors.colOnLayer1
                text: DateTimeService.dayTime
                Layout.alignment: Qt.AlignHCenter
                visible: DateTimeService.dayTime !== "" // Only show if 12-hour format is enabled
            }

        }

    }

    PrayerPopup {
        hoverTarget: root
    }

}
