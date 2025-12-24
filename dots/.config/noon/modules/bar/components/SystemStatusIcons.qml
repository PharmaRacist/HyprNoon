import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Io
import Quickshell.Widgets
import QtNetwork

Rectangle {
    // Common properties
    property real iconSpacing: 10
    property real commonIconSize: 16

    height: parent.height * 0.85
    radius: Rounding.small
    color: "transparent"
    width: indicatorsRowLayout.width + 20

    RowLayout {
        id: indicatorsRowLayout
        anchors.centerIn: parent
        spacing: 0

        // Muted audio indicator
        Revealer {
            reveal: AudioService.sink?.audio?.muted ?? false
            Layout.fillHeight: true
            Layout.rightMargin: reveal ? iconSpacing : 0

            Behavior on Layout.rightMargin {
                FAnim {}
            }

            IconImage {
                anchors.centerIn: parent
                source: Noon.iconPath("audio-volume-muted")
                implicitSize: commonIconSize
            }
        }

        // Muted microphone indicator
        Revealer {
            reveal: AudioService.source?.audio?.muted ?? false
            Layout.fillHeight: true
            Layout.rightMargin: reveal ? iconSpacing : 0

            Behavior on Layout.rightMargin {
                FAnim {}
            }

            Item {
                width: commonIconSize
                height: commonIconSize

                IconImage {
                    anchors.centerIn: parent
                    source: Noon.iconPath("microphone-sensitivity-muted")
                    implicitSize: commonIconSize
                    mipmap: true
                    smooth: true
                }
            }
        }

        // Network indicator
        Item {
            Layout.rightMargin: iconSpacing
            width: commonIconSize
            height: commonIconSize

            readonly property string networkIcon: {
                if ((NetworkService.networkName ?? "") !== "" && (NetworkService.networkName ?? "") !== "lo") {
                    const strength = NetworkService.networkStrength ?? 0;
                    if (strength > 80)
                        return "network-wireless-signal-excellent";
                    if (strength > 60)
                        return "network-wireless-signal-good";
                    if (strength > 40)
                        return "network-wireless-signal-ok";
                    if (strength > 20)
                        return "network-wireless-signal-weak";
                    return "network-wireless-signal-none";
                } else if (NetworkInformation.TransportMedium?.Ethernet ?? false) {
                    return "network-connected";
                }
                return "network-wireless-offline";
            }

            IconImage {
                anchors.centerIn: parent
                source: Noon.iconPath(parent.networkIcon)
                width: commonIconSize
                height: commonIconSize
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: Noon.exec(Mem.options.apps.networkEthernet)
            }
        }

        // Bluetooth indicator
        Item {
            width: commonIconSize
            height: commonIconSize
            visible: BluetoothService.available
            readonly property string bluetoothIcon: {
                const connected = BluetoothService.bluetoothConnected ?? false;
                const enabled = BluetoothService.bluetoothEnabled ?? false;

                if (connected)
                    return "bluetooth-active";
                if (enabled)
                    return "bluetooth";
                return "bluetooth-disabled";
            }

            IconImage {
                anchors.centerIn: parent
                source: Noon.iconPath(parent.bluetoothIcon)
                implicitSize: commonIconSize
            }
        }
    }
}
