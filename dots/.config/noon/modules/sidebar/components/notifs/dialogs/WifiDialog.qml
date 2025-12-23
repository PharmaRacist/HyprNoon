import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell


BottomDialog {
    id: root
    
    collapsedHeight: parent.height * 0.65
    show:GlobalStates.showWifiDialog
    finishAction:GlobalStates.showWifiDialog = reveal
    
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Padding.verylarge
        spacing: 0

        BottomDialogHeader {
            title: "Connect to Wi-Fi"
        }
        BottomDialogSeparator {}

        StyledIndeterminateProgressBar {
            visible: Network.wifiScanning
            Layout.fillWidth: true
        }

        StyledListView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            spacing: 0

            model: ScriptModel {
                values: [...Network.wifiNetworks].sort((a, b) => {
                    if (a.active && !b.active) return -1;
                    if (!a.active && b.active) return 1;
                    return b.strength - a.strength;
                })
            }

            delegate: WifiNetworkItem {
                required property WifiAccessPoint modelData
                wifiNetwork: modelData
                anchors {
                    left: parent?.left
                    right: parent?.right
                }
            }
        }

        
        RowLayout {
            Layout.preferredHeight: 50
            Layout.fillWidth: true
            
            Item {
                Layout.fillWidth:true
            }
            
            DialogButton {
                buttonText: qsTr("Details")
                onClicked: {
                    root.show = false;
                    const app = Network.ethernet ? 
                        Mem.options.apps.networkEthernet : 
                        Mem.options.apps.network;
                    Noon.exec(app);
                    Noon.callIpc("sidebar_launcher hide");
                }
            }

            DialogButton {
                buttonText: qsTr("Done")
                onClicked: root.show = false
            }
        }
    }
}
