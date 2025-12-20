import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

StyledPopup {
    id: root

    ColumnLayout {
        id: columnLayout

        anchors.centerIn: parent
        spacing: 4
        implicitWidth: 400
        implicitHeight: 400

        // Header
        Row {
            id: header

            spacing: 5

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                fill: 0
                font.weight: Font.Medium
                text: Network.materialSymbol
                font.pixelSize: Fonts.sizes.large
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Network"
                color: Colors.m3.m3onSurfaceVariant

                font {
                    weight: Font.Medium
                    pixelSize: Fonts.sizes.normal
                }

            }

        }

        // Connection Type Row
        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            MaterialSymbol {
                text: Network.ethernet ? "lan" : "wifi"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Connection:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: Network.ethernet ? "Ethernet" : "Wi-Fi"
            }

        }

        // Network Name Row
        RowLayout {
            property bool rowVisible: Network.networkName.length > 0 && Network.networkName != "lo"

            spacing: 5
            Layout.fillWidth: true
            visible: rowVisible
            opacity: rowVisible ? 1 : 0

            MaterialSymbol {
                text: "router"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Network:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: Network.networkName
                elide: Text.ElideRight
            }

            Behavior on opacity {
                FAnim {
                }

            }

        }

        // Signal Strength Row (Wi-Fi only)
        RowLayout {
            property bool rowVisible: Network.wifi && !Network.ethernet && Network.networkStrength > 0

            spacing: 5
            Layout.fillWidth: true
            visible: rowVisible
            opacity: rowVisible ? 1 : 0

            MaterialSymbol {
                text: "signal_cellular_alt"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Signal:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: `${Network.networkStrength}%`
            }

            Behavior on opacity {
                FAnim {
                }

            }

        }

        // Download Speed Row
        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            MaterialSymbol {
                text: "download"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Download:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: Network.formatSpeed(Network.downloadSpeed)
            }

        }

        // Upload Speed Row - MOVED INSIDE ColumnLayout!
        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            MaterialSymbol {
                text: "upload"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Upload:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: Network.formatSpeed(Network.uploadSpeed)
            }

        }

    }

}
