import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

BottomDialog {
    id: root

    collapsedHeight: parent.height * 0.64
    enableStagedReveal: false
    onShowChanged: GlobalStates.showKdeConnectDialog = show
    finishAction: GlobalStates.showKdeConnectDialog = reveal

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Padding.massive
        spacing: Padding.large

        BottomDialogHeader {
            title: "Phone Actions"
        }

        BottomDialogSeparator {
        }
        // --- Paired Devices ---

        StyledText {
            text: qsTr("Paired Devices")
            color: Colors.colOnSurfaceVariant
            font.pixelSize: Fonts.sizes.small
            opacity: 0.7
        }

        Repeater {
            model: KdeConnectService.devices

            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: KdeConnectService.isDeviceAvailable(modelData.id) ? "phone_android" : "phone_disabled"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: KdeConnectService.isDeviceAvailable(modelData.id) ? Colors.colPrimaryActive : Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: modelData.name + (KdeConnectService.isDeviceAvailable(modelData.id) ? "" : qsTr(" (offline)"))
                    color: Colors.colOnSurfaceVariant
                    opacity: KdeConnectService.isDeviceAvailable(modelData.id) ? 1 : 0.6
                }

                StyledSwitch {
                    checked: modelData.id === KdeConnectService.selectedDeviceId
                    enabled: KdeConnectService.isDeviceAvailable(modelData.id)
                    onToggled: {
                        if (checked)
                            KdeConnectService.selectDevice(modelData.id);

                    }
                }

            }

        }

        // --- Empty Paired State ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Padding.small
            visible: KdeConnectService.devices.length === 0

            MaterialSymbol {
                text: "info"
                font.pixelSize: Fonts.sizes.verylarge
                color: Colors.colOnSurfaceVariant
                opacity: 0.5
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("No paired devices")
                color: Colors.colOnSurfaceVariant
                opacity: 0.7
            }

        }

        BottomDialogSeparator {
        }

        // --- Quick Actions + Device Management ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Padding.small
            visible: KdeConnectService.selectedDeviceId !== ""

            StyledText {
                text: qsTr("Quick Actions")
                color: Colors.colOnSurfaceVariant
                font.pixelSize: Fonts.sizes.small
                opacity: 0.7
            }

            Repeater {
                model: [{
                    "icon": "notifications_active",
                    "text": qsTr("Ring Device"),
                    "action": () => {
                        return KdeConnectService.ringDevice();
                    }
                }, {
                    "icon": "notifications",
                    "text": qsTr("Send Ping"),
                    "action": () => {
                        return KdeConnectService.pingDevice();
                    }
                }, {
                    "icon": "lock",
                    "text": qsTr("Lock Device"),
                    "action": () => {
                        return KdeConnectService.lockDevice();
                    }
                }, {
                    "icon": "content_paste",
                    "text": qsTr("Send Clipboard"),
                    "action": () => {
                        return KdeConnectService.sendClipboard();
                    }
                }]

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Padding.small

                    MaterialSymbol {
                        text: modelData.icon
                        font.pixelSize: Fonts.sizes.verylarge
                        color: Colors.colOnSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.text
                        color: Colors.colOnSurfaceVariant
                    }

                    RippleButtonWithIcon {
                        materialIcon: "play_arrow"
                        onClicked: modelData.action()
                    }

                }

            }

            BottomDialogSeparator {
            }

            StyledText {
                text: qsTr("Device Management")
                color: Colors.colOnSurfaceVariant
                font.pixelSize: Fonts.sizes.small
                opacity: 0.7
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: "link"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Send Media")
                    color: Colors.colOnSurfaceVariant
                }

                RippleButtonWithIcon {
                    materialIcon: "play_arrow"
                    onClicked: {
                        const deviceId = KdeConnectService.selectedDeviceId;
                        KdeConnectService.shareFile(deviceId);
                        Noon.callIpc("sidebar_launcher hide");
                    }
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: "link_off"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Unpair Device")
                    color: Colors.colOnSurfaceVariant
                }

                RippleButtonWithIcon {
                    materialIcon: "delete"
                    onClicked: {
                        const deviceId = KdeConnectService.selectedDeviceId;
                        KdeConnectService.unpairDevice(deviceId);
                        KdeConnectService.selectDevice("");
                    }
                }

            }

        }

        Item {
            Layout.fillHeight: true
        }

        // --- Dialog Buttons ---
        RowLayout {
            Layout.preferredHeight: 50
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            DialogButton {
                buttonText: qsTr("Refresh")
                onClicked: KdeConnectService.refresh()
            }

            DialogButton {
                buttonText: qsTr("Done")
                onClicked: root.show = false
            }

        }

    }

}
