import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland


BottomDialog {
    id: root
    expandedHeight:  parent.height * 0.65  
    collapsedHeight: parent.height * 0.45
    enableStagedReveal: true
    bottomAreaReveal: true
    hoverHeight: 100

    onShowChanged: GlobalStates.showBluetoothDialog = show
    finishAction:GlobalStates.showBluetoothDialog = reveal

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Padding.verylarge
        spacing: Padding.large

        BottomDialogHeader {
            title: qsTr("Bluetooth devices")
        }

        BottomDialogSeparator {
            extraVisibleCondition:!loading.visible
        }

        StyledIndeterminateProgressBar {
            id:loading
            visible: Bluetooth.defaultAdapter?.discovering ?? false
            Layout.fillWidth: true
        }

        StyledListView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            spacing: 0

            model: ScriptModel {
                values: [...Bluetooth.devices.values].sort((a, b) => {
                    // Connected -> paired -> others
                    let conn = (b.connected - a.connected) || (b.paired - a.paired);
                    if (conn !== 0) return conn;

                    // Ones with meaningful names before MAC addresses
                    const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
                    const aIsMac = macRegex.test(a.name);
                    const bIsMac = macRegex.test(b.name);
                    if (aIsMac !== bIsMac) return aIsMac ? 1 : -1;

                    // Alphabetical by name
                    return a.name.localeCompare(b.name);
                })
            }

            delegate: BluetoothDeviceItem {
                required property BluetoothDevice modelData
                device: modelData
                anchors {
                    left: parent?.left
                    right: parent?.right
                }
            }
        }

        RowLayout {
            Layout.preferredHeight: 50
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            DialogButton {
                buttonText: qsTr("Details")
                onClicked: {
                    root.show = false;
                    Noon.exec(Mem.options.apps.bluetooth);
                    GlobalStates.sidebarRightOpen = false;
                }
            }

            DialogButton {
                buttonText: qsTr("Done")
                onClicked: root.show = false
            }
        }
    }
}
