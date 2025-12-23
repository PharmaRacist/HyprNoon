import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

BottomDialog {
    id: root

    collapsedHeight: 380
    revealOnWheel: true
    enableStagedReveal: false
    bottomAreaReveal: true
    hoverHeight: 100
    onShowChanged: GlobalStates.showTempDialog = show
    finishAction: GlobalStates.showTempDialog = reveal

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Padding.verylarge
        spacing: 0

        BottomDialogHeader {
            title: qsTr("Nightlight")
        }

        BottomDialogSeparator {
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Padding.large
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: "nightlight"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Enable Nightlight")
                    color: Colors.colOnSurfaceVariant
                }

                StyledSwitch {
                    checked: NightLightService.enabled
                    onToggled: NightLightService.enabled = checked
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: "night_sight_auto"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Auto")
                    color: Colors.colOnSurfaceVariant
                }

                StyledSwitch {
                    checked: Mem.options.services.time.autoNightLightCycle
                    onToggled: Mem.options.services.time.autoNightLightCycle = checked
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: "nightlight"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Temperature")
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    text: NightLightService.temperature + "K"
                    color: Colors.colOnSurfaceVariant
                    opacity: 0.7
                }

            }

            StyledSlider {
                Layout.fillWidth: true
                from: 3000
                to: 6500
                value: NightLightService.temperature
                enabled: NightLightService.temperature
                onMoved: NightLightService.temperature = value
                enableTooltip: false
            }

            Item {
                Layout.fillHeight: true
            }

        }

        RowLayout {
            Layout.preferredHeight: 50
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            DialogButton {
                buttonText: qsTr("Done")
                onClicked: root.show = false
            }

        }

    }

}
