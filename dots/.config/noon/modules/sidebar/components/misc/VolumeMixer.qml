import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root
    property bool showDeviceSelector: false
    property bool deviceSelectorInput
    property PwNode selectedDevice

    readonly property list<PwNode> appPwNodes: Pipewire.nodes.values.filter(node => {
        // return node.type == "21" // Alternative, not as clean
        return node.isSink && node.isStream;
    })

    Keys.onPressed: event => {
        // Close dialog on pressing Esc if open
        if (event.key === Qt.Key_Escape && bottomDialog.show)
            bottomDialog.show = false;
        event.accepted = true;
    }

    ColumnLayout {
        anchors.fill: parent
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            StyledListView {
                id: listView
                model: root.appPwNodes
                clip: true
                anchors {
                    fill: parent
                    topMargin: 10
                    bottomMargin: 10
                }
                spacing: 6

                delegate: VolumeMixerEntry {
                    // Layout.fillWidth: true
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: 10
                        rightMargin: 10
                    }
                    required property var modelData
                    node: modelData
                }
            }
            PagePlaceholder {
                visible: root.appPwNodes.length === 0
                icon: "brand_awareness"
                title: "Nothing Playing"
                shape: MaterialShape.Clover4Leaf
            }
        }

        // Device selector
        ButtonGroup {
            id: deviceSelectorRowLayout
            Layout.fillWidth: true
            Layout.fillHeight: false
            AudioDeviceSelectorButton {
                Layout.fillWidth: true
                input: false
                onClicked: {
                    bottomDialog.show = true;
                    root.deviceSelectorInput = false;
                }
            }
            AudioDeviceSelectorButton {
                Layout.fillWidth: true
                input: true
                onClicked: {
                    bottomDialog.show = true;
                    root.deviceSelectorInput = true;
                }
            }
        }
    }

    BottomDialog {
        id: bottomDialog
        show: root.showDeviceSelector
        collapsedHeight: 180 + dialogFlickable.contentHeight
        enableStagedReveal:false
        bottomAreaReveal:true
        hoverHeight: 300
        contentItem: Item { // The dialog
            id: dialog
            anchors.fill: parent
            anchors.margins: Padding.massive

            ColumnLayout {
                id: dialogColumnLayout
                anchors.fill: parent
                spacing: Padding.normal

                StyledText {
                    id: dialogTitle
                    Layout.alignment: Qt.AlignLeft
                    color: Colors.m3.m3onSurface
                    font.pixelSize: Fonts.sizes.subTitle
                    text: root.deviceSelectorInput ? "Select input device" : "Select output device"
                }
                Separator {}
                StyledFlickable {
                    id: dialogFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: devicesColumnLayout.implicitHeight

                    ColumnLayout {
                        id: devicesColumnLayout
                        anchors.fill: parent
                        spacing: 0

                        Repeater {
                            model: ScriptModel {
                                values: Pipewire.nodes.values.filter(node => {
                                    return !node.isStream && node.isSink !== root.deviceSelectorInput && node.audio;
                                })
                            }

                            // This could and should be refractored, but all data becomes null when passed wtf
                            delegate: StyledRadioButton {
                                id: radioButton
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.leftMargin: Padding.normal
                                description: modelData.description
                                checked: modelData.id === Pipewire.defaultAudioSink?.id

                                Connections {
                                    target: root
                                    function onShowDeviceSelectorChanged() {
                                        if (!bottomDialog.show)
                                            return;
                                        radioButton.checked = (modelData.id === Pipewire.defaultAudioSink?.id);
                                    }
                                }

                                onCheckedChanged: {
                                    if (checked) {
                                        root.selectedDevice = modelData;
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    id: dialogButtonsRowLayout
                    Layout.alignment: Qt.AlignRight

                    DialogButton {
                        buttonText: "Cancel"
                        onClicked: {
                            bottomDialog.show = false;
                        }
                    }
                    DialogButton {
                        buttonText: "OK"
                        onClicked: {
                            bottomDialog.show = false;
                            if (root.selectedDevice) {
                                if (root.deviceSelectorInput) {
                                    Pipewire.preferredDefaultAudioSource = root.selectedDevice;
                                } else {
                                    Pipewire.preferredDefaultAudioSink = root.selectedDevice;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
