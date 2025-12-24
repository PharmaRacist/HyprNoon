import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledPopup {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        Row {
            spacing: 6

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "memory"
                fill: 1
                font.pixelSize: Fonts.sizes.large
                color: Colors.m3.m3onSurfaceVariant
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledText {
                    text: qsTr("System Resources")
                    color: Colors.m3.m3onSurfaceVariant
                    font.pixelSize: Fonts.sizes.large
                    font.weight: Font.Medium
                }

            }

        }

        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            MaterialSymbol {
                text: "speed"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("CPU Usage:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                font.weight: Font.Medium
                color: Colors.m3.m3onSurfaceVariant
                text: `${(ResourcesService.cpuUsagePercentage).toFixed(1)}%`
            }

        }

        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            MaterialSymbol {
                text: "device_thermostat"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("CPU Temp:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: `${(ResourcesService.avgCpuTemp * 100).toFixed(1)} °C`
            }

        }

        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            MaterialSymbol {
                text: "speed"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("CPU Clock:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: `${ResourcesService.cpuClockGHz.toFixed(2)} GHz`
            }

        }

        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            MaterialSymbol {
                text: "memory_alt"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Mem:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: `${(ResourcesService.memoryUsedPercentage * 100).toFixed(1)}% (${(ResourcesService.memoryUsed / 1073741824).toFixed(1)} / ${(ResourcesService.memoryTotal / 1073741824).toFixed(1)} GB)`
            }

        }

        RowLayout {
            spacing: 5
            Layout.fillWidth: true
            visible: ResourcesService.swapTotal > 0

            MaterialSymbol {
                text: "sync_alt"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Swap:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: `${(ResourcesService.swapUsedPercentage * 100).toFixed(1)}% (${(ResourcesService.swapUsed / 1073741824).toFixed(1)} / ${(ResourcesService.swapTotal / 1073741824).toFixed(1)} GB)`
            }

        }

        Repeater {
            model: ResourcesService.gpus

            Column {
                spacing: 4
                Layout.fillWidth: true

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.m3.m3outlineVariant
                    opacity: 0.5
                }

                StyledText {
                    text: `GPU ${modelData.index}: ${modelData.name}`
                    color: Colors.m3.m3onSurfaceVariant
                    font.weight: Font.Medium
                    font.pixelSize: Fonts.sizes.normal
                }

                RowLayout {
                    spacing: 5
                    width: parent.width

                    MaterialSymbol {
                        text: "monitor_heart"
                        color: Colors.m3.m3onSurfaceVariant
                        font.pixelSize: Fonts.sizes.large
                    }

                    StyledText {
                        text: qsTr("Utilization:")
                        color: Colors.m3.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        color: Colors.m3.m3onSurfaceVariant
                        text: `${(modelData.utilization * 100).toFixed(1)}%`
                    }

                }

                RowLayout {
                    spacing: 5
                    width: parent.width

                    MaterialSymbol {
                        text: "device_thermostat"
                        color: Colors.m3.m3onSurfaceVariant
                        font.pixelSize: Fonts.sizes.large
                    }

                    StyledText {
                        text: qsTr("Temperature:")
                        color: Colors.m3.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        color: Colors.m3.m3onSurfaceVariant
                        text: `${(modelData.temperature * 100).toFixed(1)} °C`
                    }

                }

                RowLayout {
                    spacing: 5
                    width: parent.width

                    MaterialSymbol {
                        text: "memory"
                        color: Colors.m3.m3onSurfaceVariant
                        font.pixelSize: Fonts.sizes.large
                    }

                    StyledText {
                        text: qsTr("VRAM:")
                        color: Colors.m3.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        color: Colors.m3.m3onSurfaceVariant
                        text: `${(modelData.memoryPercentage * 100).toFixed(1)}% (${modelData.memoryUsed} / ${modelData.memoryTotal} MB)`
                    }

                }

                RowLayout {
                    spacing: 5
                    width: parent.width
                    visible: modelData.powerDraw !== null

                    MaterialSymbol {
                        text: "bolt"
                        color: Colors.m3.m3onSurfaceVariant
                        font.pixelSize: Fonts.sizes.large
                    }

                    StyledText {
                        text: qsTr("Power:")
                        color: Colors.m3.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        color: Colors.m3.m3onSurfaceVariant
                        text: modelData.powerDraw !== null ? `${modelData.powerDraw.toFixed(1)} / ${modelData.powerLimit.toFixed(0)} W` : "N/A"
                    }

                }

            }

        }

    }

}
