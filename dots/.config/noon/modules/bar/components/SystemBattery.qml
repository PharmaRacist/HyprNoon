import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: batteryLayout

    readonly property var chargeState: UPower.displayDevice.state
    readonly property bool isCharging: chargeState == UPowerDeviceState.Charging
    readonly property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    readonly property real percentage: UPower.displayDevice.percentage
    readonly property bool isLow: percentage <= Mem.options.bar.batteryLowThreshold / 100
    readonly property bool isCritical: percentage <= 0.15
    readonly property bool isEmpty: percentage <= 0.05
    // Battery icon name based on percentage and state
    readonly property string batteryIcon: {
        if (isEmpty)
            return "battery-empty";

        if (isCharging) {
            if (percentage >= 0.9)
                return "battery-full-charging";

            if (percentage >= 0.6)
                return "battery-good-charging";

            if (percentage >= 0.4)
                return "battery-low-charging";

            return "battery-caution-charging";
        } else {
            if (percentage >= 0.9)
                return "battery-full";

            if (percentage >= 0.6)
                return "battery-good";

            if (percentage >= 0.4)
                return "battery-low";

            if (percentage >= 0.15)
                return "battery-caIndicatorution";

            return "battery-empty";
        }
    }

    Item {
        Layout.preferredWidth: batteryIcon.width + percentageText.width + 4
        Layout.preferredHeight: Math.max(batteryIcon.height, percentageText.height)
        width: Math.max(Math.round(batteryIcon + percentageText + 7), 50)

        // System battery icon
        Image {
            id: batteryIcon

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            source: `image://icon/${batteryLayout.batteryIcon}`
            width: 24
            height: 24
            smooth: true

            // Color overlay for low battery warning
            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: {
                    if (isCritical && !isCharging)
                        return Colors.m3.m3error;

                    if (isLow && !isCharging)
                        return Colors.m3.m3primary;

                    return Colors.colOnLayer1;
                }
                visible: true
            }

        }

        // Battery percentage text
        StyledText {
            id: percentageText

            anchors.left: batteryIcon.right
            anchors.leftMargin: 4
            font.family: Fonts.family.monospace
            anchors.verticalCenter: parent.verticalCenter
            text: `${Math.round(percentage * 100)}%`
            color: {
                if (isCritical && !isCharging)
                    return Colors.m3.m3error;

                if (isLow && !isCharging)
                    return Colors.m3.m3primary;

                return Colors.colOnLayer1;
            }
            font.pixelSize: Fonts.sizes.verysmall
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true

            BatteryPopup {
                hoverTarget: hover
            }

        }

    }

}
