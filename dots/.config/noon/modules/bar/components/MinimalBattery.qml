import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.modules.common
import qs.modules.common.widgets

MouseArea {
    id: mouse

    readonly property var chargeState: UPower.displayDevice.state
    readonly property bool isCharging: chargeState == UPowerDeviceState.Charging
    readonly property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    readonly property real percentage: UPower.displayDevice.percentage
    readonly property bool isLow: percentage <= Mem.options.bar.batteryLowThreshold / 100
    readonly property color batteryLowBackground: Colors.m3.darkmode ? Colors.m3.m3error : Colors.m3.m3errorContainer
    readonly property color batteryLowOnBackground: Colors.m3.darkmode ? Colors.m3.m3errorContainer : Colors.m3.m3error

    width: 26
    height: 26
    hoverEnabled: true

    Item {
        id: batteryWidget

        anchors.fill: parent
        width: 26
        height: 26

        BatteryPopup {
            id: batteryPopup

            hoverTarget: mouse
        }

        CircularProgress {
            anchors.centerIn: parent
            lineWidth: 2
            value: percentage
            size: 26
            secondaryColor: (isLow && !isCharging) ? batteryLowBackground : Colors.m3.m3secondaryContainer
            primaryColor: (isLow && !isCharging) ? batteryLowOnBackground : Colors.m3.m3onSecondaryContainer
            fill: (isLow && !isCharging)

            MaterialSymbol {
                anchors.centerIn: parent
                text: "bolt"
                font.pixelSize: Fonts.sizes.normal
                color: Colors.m3.m3onSecondaryContainer
                visible: isCharging
            }

            // Show battery_full icon when 100%, otherwise show percentage
            Item {
                anchors.centerIn: parent
                visible: !isCharging
                width: parent.width
                height: parent.height

                StyledText {
                    anchors.centerIn: parent
                    color: Colors.colOnLayer1
                    text: `${Math.round(percentage * 100)}`
                    font.pixelSize: Fonts.sizes.normal - 3.6
                    visible: Math.round(percentage * 100) < 100
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "battery_full"
                    font.pixelSize: Fonts.sizes.normal
                    color: Colors.colOnLayer1
                    visible: Math.round(percentage * 100) >= 100
                }

            }

        }

    }

}
