import Qt5Compat.GraphicalEffects
import QtNetwork
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property bool verticalMode: false
    property real iconSpacing: 10
    property real commonIconSize: Fonts.sizes.verylarge
    property color commonIconColor: Colors.colOnLayer1

    Layout.fillWidth: verticalMode
    implicitWidth: verticalMode ? parent.width : grid.implicitWidth + 24
    implicitHeight: verticalMode ? grid.implicitHeight + Padding.verylarge : grid.implicitHeight
    states: [
        State {
            name: "verticalMode"
            when: root.verticalMode

            PropertyChanges {
                target: grid
                rows: 4
                columns: 1
                rowSpacing: iconSpacing
                columnSpacing: 0
            }

        },
        State {
            name: "horizontal"
            when: !root.verticalMode

            PropertyChanges {
                target: grid
                rows: 1
                columns: 4
                rowSpacing: 0
                columnSpacing: iconSpacing
            }

        }
    ]

    Timer {
        id: delayReveal

        property string mode: ""

        interval: 200
        onTriggered: {
            if (mode === "wifi") {
                GlobalStates.showWifiDialog = true;
                GlobalStates.showBluetoothDialog = false;
            } else if (mode === "bluetooth") {
                GlobalStates.showWifiDialog = false;
                GlobalStates.showBluetoothDialog = true;
            }
        }
    }

    BarGroup {
        anchors.centerIn: parent
        implicitHeight: parent.implicitHeight - Padding.small
        implicitWidth: parent.implicitWidth * padding
    }

    GridLayout {
        id: grid

        anchors.centerIn: parent
        rows: verticalMode ? 4 : 1
        columns: verticalMode ? 1 : 4
        rowSpacing: verticalMode ? iconSpacing : 0
        columnSpacing: verticalMode ? 0 : iconSpacing

        MaterialSymbol {
            id: networkIcon

            fill: 1
            font.pixelSize: commonIconSize
            color: commonIconColor
            text: {
                if (NetworkService.ethernet)
                    return "lan";
                else if (NetworkService.networkName.length > 0 && NetworkService.networkName !== "lo")
                    return NetworkService.networkStrength > 80 ? "signal_wifi_4_bar" : NetworkService.networkStrength > 60 ? "network_wifi_3_bar" : NetworkService.networkStrength > 40 ? "network_wifi_2_bar" : NetworkService.networkStrength > 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar";
                else
                    return "signal_wifi_off";
            }

            MouseArea {
                id: networkMouse

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    delayReveal.mode = "";
                    Noon.callIpc("sidebar reveal Notifs");
                    delayReveal.mode = "wifi";
                    delayReveal.restart();
                }
            }

            NetworkPopup {
                hoverTarget: networkMouse
            }

        }

        MaterialSymbol {
            text: BluetoothService.currentDeviceIcon
            font.pixelSize: commonIconSize
            color: commonIconColor
            fill: 1

            BluetoothPopup {
                hoverTarget: btMouse
            }

            MouseArea {
                id: btMouse

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    delayReveal.mode = "";
                    Noon.callIpc("sidebar reveal Notifs");
                    delayReveal.mode = "bluetooth";
                    delayReveal.restart();
                }
            }

        }

    }

}
