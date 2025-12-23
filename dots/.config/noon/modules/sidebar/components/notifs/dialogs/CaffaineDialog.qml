import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

BottomDialog {
    id: root

    collapsedHeight: parent.height * 0.4
    enableStagedReveal: false
    onShowChanged: GlobalStates.showCaffaineDialog = show
    finishAction: GlobalStates.showCaffaineDialog = reveal

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 1.5 * Padding.massive
        spacing: Padding.verylarge

        BottomDialogHeader {
            title: qsTr("Caffeine")
        }

        BottomDialogSeparator {
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Padding.large

            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: "coffee"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Awake")
                    color: Colors.colOnSurfaceVariant
                }

                StyledSwitch {
                    checked: Mem.options.services.idle.inhibit
                    onToggled: Mem.options.services.idle.inhibit = checked
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: "timer"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Idle Timeout (seconds)")
                    color: Colors.colOnSurfaceVariant
                }

                MaterialTextField {
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 100
                    text: String(Mem.options.services.idle.timeOut)
                    placeholderText: qsTr("Timeout")
                    inputMethodHints: Qt.ImhDigitsOnly
                    onEditingFinished: {
                        const val = parseInt(text);
                        if (!isNaN(val) && val >= 0)
                            Mem.options.services.idle.timeOut = val;
                        else
                            text = String(Mem.options.services.idle.timeOut);
                    }

                    validator: IntValidator {
                        bottom: 0
                        top: 36000
                    }

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
