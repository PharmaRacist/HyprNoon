import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "dialogs"
import "notifications"
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property var activeDialog: {
        if (GlobalStates.showWifiDialog)
            return {
            "key": "wifi",
            "component": wifiComponent
        };

        if (GlobalStates.showRecordingDialog)
            return {
            "key": "recording",
            "component": recordingComponent
        };

        if (GlobalStates.showKdeConnectDialog)
            return {
            "key": "kdeConnect",
            "component": kdeComponent
        };

        if (GlobalStates.showCaffaineDialog)
            return {
            "key": "caffaine",
            "component": caffaineComponent
        };

        if (GlobalStates.showBluetoothDialog)
            return {
            "key": "bluetooth",
            "component": bluetoothComponent
        };

        if (GlobalStates.showAppearanceDialog)
            return {
            "key": "appearance",
            "component": appearanceComponent
        };

        if (GlobalStates.showTransparencyDialog)
            return {
            "key": "transparency",
            "component": transparencyComponent
        };

        if (GlobalStates.showTempDialog)
            return {
            "key": "temp",
            "component": tempComponent
        };

        return null;
    }
    property bool showDialog: activeDialog !== null

    ColumnLayout {
        anchors.fill: parent
        spacing: Padding.normal

        UpperWidgetGroup {
            Layout.fillWidth: true
        }

        NotificationList {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

    }

    Loader {
        id: dialogLoader

        anchors.fill: parent
        active: root.showDialog || unloadTimer.running
        sourceComponent: root.activeDialog ? root.activeDialog.component : null
        opacity: root.showDialog ? 1 : 0
        onLoaded: {
            if (item) {
                item.show = Qt.binding(() => {
                    return root.showDialog;
                });
                // Initialize services for specific dialogs
                if (root.activeDialog.key === "wifi") {
                    Network.enableWifi();
                    Network.rescanWifi();
                } else if (root.activeDialog.key === "bluetooth") {
                    BluetoothService.defaultAdapter.enabled = true;
                    BluetoothService.defaultAdapter.discovering = true;
                }
            }
        }

        Timer {
            id: unloadTimer

            interval: 600
        }

        Behavior on opacity {
            Anim {
                onFinished: {
                    if (!root.showDialog)
                        unloadTimer.restart();

                }
            }

        }

    }

    // Component definitions
    Component {
        id: wifiComponent

        WifiDialog {
        }

    }

    Component {
        id: recordingComponent

        RecordingDialog {
        }

    }

    Component {
        id: caffaineComponent

        CaffaineDialog {
        }

    }

    Component {
        id: bluetoothComponent

        BluetoothDialog {
        }

    }

    Component {
        id: transparencyComponent

        TransparencyDialog {
        }

    }

    Component {
        id: appearanceComponent

        AppearanceDialog {
        }

    }

    Component {
        id: kdeComponent

        KdeConnectDialog {
        }

    }

    Component {
        id: tempComponent

        TempDialog {
        }

    }

}
