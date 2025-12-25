import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

BottomDialog {
    id: root
    
    collapsedHeight: parent.height * 0.65
    show: GlobalStates.showWifiDialog
    finishAction: GlobalStates.showWifiDialog = reveal
    
    property bool isScanning: false
    
    onShowChanged: {
        if (show && NetworkService.wifiEnabled) {
            isScanning = true;
            NetworkService.rescanWifi();
            scanTimer.restart();
        }
    }
    
    Timer {
        id: scanTimer
        interval: 3000
        onTriggered: isScanning = false
    }
    
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Padding.verylarge
        spacing: 0

        BottomDialogHeader {
            title: "Connect to Wi-Fi"
        }
        
        BottomDialogSeparator {}

        StyledIndeterminateProgressBar {
            visible: root.isScanning
            Layout.fillWidth: true
        }

        StyledListView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            spacing: 4  // Add spacing between items

            model: {
                const networks = [...NetworkService.wifiNetworks];
                return networks.sort((a, b) => {
                    if (a.active && !b.active) return -1;
                    if (!a.active && b.active) return 1;
                    return b.strength - a.strength;
                });
            }

            delegate: WifiNetworkItem {
                required property var modelData
                required property int index
                
                width: ListView.view.width
                network: modelData
            }
        }

        RowLayout {
            Layout.preferredHeight: 50
            Layout.fillWidth: true
            
            Item {
                Layout.fillWidth: true
            }
            
            DialogButton {
                buttonText: qsTr("Refresh")
                onClicked: {
                    root.isScanning = true;
                    NetworkService.rescanWifi();
                    scanTimer.restart();
                }
            }
            
            DialogButton {
                buttonText: qsTr("Details")
                onClicked: {
                    root.show = false;
                    const app = NetworkService.ethernet ? 
                        Mem.options.apps.networkEthernet : 
                        Mem.options.apps.network;
                    Noon.exec(app);
                    Noon.callIpc("sidebar hide");
                }
            }

            DialogButton {
                buttonText: qsTr("Done")
                onClicked: root.show = false
            }
        }
    }
}
