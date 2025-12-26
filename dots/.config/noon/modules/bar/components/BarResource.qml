import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: resourcesContainer

    // Required properties for each resource
    required property double batteryPercentage
    required property double cpuPercentage
    required property double memoryPercentage
    required property double swapPercentage

    spacing: 6

    // Battery Resource
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            fill: 1
            text: "battery_full" // This will show the battery icon
            iconSize: Fonts.sizes.normal
            color: Colors.m3.m3onSecondaryContainer
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            height: 4

            Rectangle {
                anchors.fill: parent
                color: Colors.m3.m3secondaryContainer
                radius: height / 2

                Rectangle {
                    height: parent.height
                    width: parent.width * batteryPercentage
                    color: Colors.m3.m3onSecondaryContainer
                    radius: height / 2

                    Behavior on width {
                        Anim {
                        }

                    }

                }

            }

        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.colOnLayer1
            text: `${Math.round(batteryPercentage * 100)}%`
            Layout.minimumWidth: 45
            horizontalAlignment: Text.AlignRight
        }

    }

    // CPU Resource
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            fill: 1
            text: "memory" // CPU icon
            iconSize: Fonts.sizes.normal
            color: Colors.m3.m3onSecondaryContainer
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            height: 4

            Rectangle {
                anchors.fill: parent
                color: Colors.m3.m3secondaryContainer
                radius: height / 2

                Rectangle {
                    height: parent.height
                    width: parent.width * cpuPercentage
                    color: Colors.m3.m3onSecondaryContainer
                    radius: height / 2

                    Behavior on width {
                        Anim {
                        }

                    }

                }

            }

        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.colOnLayer1
            text: `${Math.round(cpuPercentage * 100)}%`
            Layout.minimumWidth: 45
            horizontalAlignment: Text.AlignRight
        }

    }

    // Memory Resource
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            fill: 1
            text: "database" // Memory icon
            iconSize: Fonts.sizes.normal
            color: Colors.m3.m3onSecondaryContainer
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            height: 4

            Rectangle {
                anchors.fill: parent
                color: Colors.m3.m3secondaryContainer
                radius: height / 2

                Rectangle {
                    height: parent.height
                    width: parent.width * memoryPercentage
                    color: Colors.m3.m3onSecondaryContainer
                    radius: height / 2

                    Behavior on width {
                        Anim {
                        }

                    }

                }

            }

        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.colOnLayer1
            text: `${Math.round(memoryPercentage * 100)}%`
            Layout.minimumWidth: 45
            horizontalAlignment: Text.AlignRight
        }

    }

    // Swap Resource
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            fill: 1
            text: "swap_horiz" // Swap icon
            iconSize: Fonts.sizes.normal
            color: Colors.m3.m3onSecondaryContainer
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            height: 4

            Rectangle {
                anchors.fill: parent
                color: Colors.m3.m3secondaryContainer
                radius: height / 2

                Rectangle {
                    height: parent.height
                    width: parent.width * swapPercentage
                    color: Colors.m3.m3onSecondaryContainer
                    radius: height / 2

                    Behavior on width {
                        Anim {
                        }

                    }

                }

            }

        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.colOnLayer1
            text: `${Math.round(swapPercentage * 100)}%`
            Layout.minimumWidth: 45
            horizontalAlignment: Text.AlignRight
        }

    }

}
