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

    property var dialogConfigs: [{
        "name": "wifi",
        "show": GlobalStates.showWifiDialog,
        "component": wifiComponent,
        "onCompleted": function() {
            Network.enableWifi();
            Network.rescanWifi();
        }
    }, {
        "name": "recording",
        "show": GlobalStates.showRecordingDialog,
        "component": recordingComponent
    }, {
        "name": "kdeConnect",
        "show": GlobalStates.showKdeConnectDialog,
        "component": kdeComponent
    }, {
        "name": "caffaine",
        "show": GlobalStates.showCaffaineDialog,
        "component": caffaineComponent
    }, {
        "name": "bluetooth",
        "show": GlobalStates.showBluetoothDialog,
        "component": bluetoothComponent,
        "onCompleted": function() {
            BluetoothService.defaultAdapter.enabled = true;
            BluetoothService.defaultAdapter.discovering = true;
        }
    }, {
        "name": "appearance",
        "show": GlobalStates.showAppearanceDialog,
        "component": appearanceComponent
    }, {
        "name": "transparency",
        "show": GlobalStates.showTransparencyDialog,
        "component": transparencyComponent
    }, {
        "name": "temp",
        "show": GlobalStates.showTempDialog,
        "component": tempComponent
    }]
    property bool showDialogs: dialogConfigs.some((d) => {
        return d.show;
    })

    clip: true

    Timer {
        interval: 7000
        repeat: true
        running: dialogConfigs.some((d) => {
            return d.show;
        })
        onTriggered: {
            GlobalStates.showWifiDialog = false;
            GlobalStates.showRecordingDialog = false;
            GlobalStates.showCaffaineDialog = false;
            GlobalStates.showBluetoothDialog = false;
            GlobalStates.showTransparencyDialog = false;
            GlobalStates.showTempDialog = false;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Padding.normal
        opacity: root.showDialogs ? 0 : 1

        UpperWidgetGroup {
            Layout.fillWidth: true
        }

        NotificationList {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

    }

    Repeater {
        model: root.dialogConfigs

        Loader {
            id: dialogLoader

            active: modelData.show
            sourceComponent: modelData.component
            onLoaded: {
                item.show = modelData.show;
                // Connect dismiss signal
                item.dismiss.connect(function() {
                    switch (modelData.name) {
                    case "wifi":
                        GlobalStates.showWifiDialog = false;
                        break;
                    case "recording":
                        GlobalStates.showRecordingDialog = false;
                        break;
                    case "bluetooth":
                        GlobalStates.showBluetoothDialog = false;
                        break;
                    case "transparency":
                        GlobalStates.showTransparencyDialog = false;
                        break;
                    case "caffaine":
                        GlobalStates.showCaffaineDialog = false;
                        break;
                    case "kdeConnect":
                        GlobalStates.showKdeConnectDialog = false;
                    case "appearance":
                        GlobalStates.showAppearanceDialog = false;
                    case "temp":
                        GlobalStates.showTempDialog = false;
                        break;
                    }
                });
                if (modelData.onCompleted)
                    modelData.onCompleted();

            }
            states: [
                State {
                    name: "hidden"
                    when: !dialogLoader.active

                    PropertyChanges {
                        dialogLoader.height: 0
                        dialogLoader.opacity: 0
                    }

                },
                State {
                    name: "revealed"
                    when: dialogLoader.active

                    PropertyChanges {
                        dialogLoader.height: 1020
                        dialogLoader.opacity: 1
                    }

                }
            ]
            transitions: [
                Transition {
                    reversible: true
                    from: "*"
                    to: "revealed"

                    FAnim {
                        properties: "width,height"
                    }

                    Anim {
                    }

                },
                Transition {
                    reversible: true
                    from: "*"
                    to: "hidden"

                    FAnim {
                        properties: "width,height"
                    }

                    Anim {
                    }

                }
            ]

            anchors {
                // top: parent.top
                right: parent.right
                left: parent.left
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
