import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

MouseArea {
    id: root

    property bool borderless: !Mem.options.bar.appearance.modulesBg
    readonly property var chargeState: BatteryService.chargeState
    readonly property bool isCharging: BatteryService.isCharging
    readonly property bool isPluggedIn: BatteryService.isPluggedIn
    readonly property real percentage: BatteryService.percentage
    readonly property bool isLow: percentage <= Mem.options.BatteryService.low / 100
    property bool verticalMode: false
    property bool enablePopup: true

    implicitWidth: batteryProgress.implicitWidth
    implicitHeight: BarData.currentBarExclusiveSize
    hoverEnabled: true

    ClippedProgressBar {
        id: batteryProgress

        vertical: verticalMode
        valueBarHeight: verticalMode ? 38 : (BarData.currentBarExclusiveSize * 0.55) * BarData.barPadding
        valueBarWidth: !verticalMode ? 38 : (BarData.currentBarExclusiveSize * 0.55) * BarData.barPadding
        anchors.centerIn: parent
        value: percentage
        highlightColor: (isLow && !isCharging) ? Colors.m3.m3error : Colors.colOnSecondaryContainer
        text: ""

        Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            RowLayout {
                anchors.centerIn: parent
                spacing: 0

                MaterialSymbol {
                    id: boltIcon

                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: -2
                    Layout.rightMargin: -2
                    fill: 1
                    text: "bolt"
                    font.pixelSize: Fonts.sizes.verysmall
                    visible: isCharging && percentage < 1 // TODO: animation
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    font: batteryProgress.font
                    text: batteryProgress.text
                }

            }

        }

    }

    BatteryPopup {
        id: batteryPopup

        active: hoverTarget.containsMouse && root.enablePopup
        hoverTarget: root
    }

}
