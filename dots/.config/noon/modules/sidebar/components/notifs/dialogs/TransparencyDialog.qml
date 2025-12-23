import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

BottomDialog {
    id: root

    collapsedHeight: 440
    revealOnWheel: true
    enableStagedReveal: false
    bottomAreaReveal: true
    hoverHeight: 100
    onShowChanged: GlobalStates.showTransparencyDialog = show
    finishAction: GlobalStates.showTransparencyDialog = reveal

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Padding.verylarge
        spacing: 0

        BottomDialogHeader {
            title: qsTr("Transparency")
        }

        BottomDialogSeparator {
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Padding.verylarge
            spacing: Padding.verylarge

            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: "opacity"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Enable Transparency")
                    color: Colors.colOnSurfaceVariant
                }

                StyledSwitch {
                    checked: Mem.options.appearance.transparency.enabled
                    onToggled: Mem.options.appearance.transparency.enabled = checked
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: "blur_on"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Blur Background")
                    color: Colors.colOnSurfaceVariant
                }

                StyledSwitch {
                    checked: Mem.options.appearance.transparency.blur
                    onToggled: Mem.options.appearance.transparency.blur = checked
                    enabled: Mem.options.appearance.transparency.enabled
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Padding.small

                    MaterialSymbol {
                        text: "tune"
                        font.pixelSize: Fonts.sizes.verylarge
                        color: Colors.colOnSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Transparency Amount")
                        color: Colors.colOnSurfaceVariant
                    }

                    StyledText {
                        text: Math.round(Mem.options.appearance.transparency.scale * 100) + "%"
                        color: Colors.colOnSurfaceVariant
                        opacity: 0.7
                    }

                }

                StyledSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: Mem.options.appearance.transparency.scale
                    onMoved: Mem.options.appearance.transparency.scale = value
                }

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
