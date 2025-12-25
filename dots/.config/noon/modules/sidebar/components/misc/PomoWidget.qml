import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property bool revealAddDialog: false

    ColumnLayout {
        anchors.fill: parent
        spacing: Padding.gigantic
        StyledText {
            text: "Pomos"
            font.pixelSize: Fonts.sizes.subTitle
            color: Colors.colOnLayer1
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Padding.normal
            Layout.topMargin: Padding.normal
        }

        StyledListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Padding.normal
            clip: true

            model: TimerService.uiTimers
            delegate: PomoItem {
                width: listView.width
                timer: modelData
            }

            PagePlaceholder {
                shown: TimerService.uiTimers.length === 0
                icon: "hourglass"
                title: "No active timers"
            }
        }
    }

    BottomDialog {
        id: addDialog
        expandedHeight: 640
        collapsedHeight: 360
        enableStagedReveal:true
        bottomAreaReveal:true
        hoverHeight: 200

        show: root.revealAddDialog
        expand: false
        function addPomo() {
            const duration = TimerService.parseTimeString(`${timePicker.hour}h  ${timePicker.minute}m`);
            TimerService.addTimer(nameField.text, duration);
            addDialog.show = false;
        }
        contentItem: Item {
            anchors.fill: parent
            ColumnLayout {
                spacing: Padding.large

                anchors {
                    fill: parent
                    margins: Padding.massive
                }

                RowLayout {
                    id: header
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 50
                    Layout.bottomMargin: 0
                    Layout.margins: Padding.normal
                    StyledText {
                        text: "Add Pomo"
                        font.pixelSize: Fonts.sizes.subTitle
                        color: Colors.colOnLayer2
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Spacer {}
                    RippleButtonWithIcon {
                        materialIcon: "close"
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        releaseAction: () => addDialog.show = false
                    }
                }
                Separator {}
                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    Layout.leftMargin: Padding.normal
                    font.pixelSize: Fonts.sizes.normal
                    placeholderText: "Pomo Name"
                    background: null
                    selectionColor: Colors.colPrimaryContainer
                    selectedTextColor: Colors.m3.m3onPrimaryContainer
                    color: Colors.colOnLayer0
                    placeholderTextColor: Colors.colSubtext
                    selectByMouse: true
                    onAccepted: addDialog.addPomo()
                }
                TimePicker {
                    id: timePicker
                    clockPicker: false
                }
                StyledListView {
                    id: presets
                    visible: addDialog.expand
                    clip: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: TimerService.presets
                    delegate: StyledDelegateItem {
                        property var preset: modelData
                        title: preset.name
                        materialIcon: preset.icon
                        subtext: TimerService.formatTime(preset.duration)
                        releaseAction: () => TimerService.addTimer(preset.name, preset.duration, true)
                    }
                }
                Spacer {
                    visible: !presets.visible
                }
            }
            RippleButton {
                id: saveButton
                visible: addDialog.height > 300
                buttonRadius: Rounding.verylarge
                colBackground: Colors.colPrimaryContainer
                implicitWidth: 100
                implicitHeight: 50
                releaseAction: () => addDialog.addPomo()
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    margins: 20
                }
                RowLayout {
                    anchors.centerIn: parent
                    spacing: Padding.normal
                    MaterialSymbol {
                        text: "edit"
                        fill: 1
                        font.pixelSize: Fonts.sizes.large
                        color: Colors.colOnPrimaryContainer
                    }
                    StyledText {
                        color: Colors.colOnPrimaryContainer
                        font.pixelSize: Fonts.sizes.normal
                        text: "Save"
                    }
                }
            }
        }
    }
    component PomoItem: RippleButton {
        id: root
        property var timer
        implicitHeight: 120
        colBackground: Colors.colLayer1
        buttonRadius: Rounding.normal
        releaseAction: () => {
            if (timer.isRunning) {
                TimerService.pauseTimer(timer.id);
            } else {
                TimerService.startTimer(timer.id);
            }
        }
        RowLayout {
            id: contentLayout
            anchors {
                fill: parent
                rightMargin: Padding.massive
                leftMargin: Padding.verylarge
            }
            spacing: Padding.large
            CircularProgress {
                Layout.alignment: Qt.AlignVCenter
                lineWidth: 12
                // fill: false
                value: Math.min(1, (timer.originalDuration - timer.remainingTime) / timer.originalDuration)
                size: parent.height * 0.8
                secondaryColor: Colors.m3.m3secondaryContainer
                primaryColor: timer?.color || Colors.m3.m3primary
                MaterialSymbol {
                    text: timer.icon
                    anchors.centerIn: parent
                    font.pixelSize: Fonts.sizes.title
                    color: Colors.colOnLayer0
                }
            }
            ColumnLayout {
                id: info
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                Layout.preferredHeight: 40
                spacing: 0
                StyledText {
                    id: duration
                    font.variableAxes: Fonts.variableAxes.numbers
                    text: TimerService.formatTime(timer.remainingTime)
                    font.pixelSize: Fonts.sizes.subTitle
                    color: Colors.colOnLayer1
                }
                StyledText {
                    id: name
                    text: timer.name
                    font.pixelSize: Fonts.sizes.normal
                    color: Colors.colOnLayer1
                }
            }
            Spacer {}
            RowLayout {
                id: controls
                RippleButtonWithIcon {
                    materialIcon: timer?.isRunning ? "pause" : "play_arrow"
                    enabled: timer && timer.remainingTime > 0
                    onClicked: {
                        if (timer.isRunning) {
                            TimerService.pauseTimer(timer.id);
                        } else {
                            TimerService.startTimer(timer.id);
                        }
                    }
                }

                RippleButtonWithIcon {
                    materialIcon: "restart_alt"
                    enabled: timer !== null
                    onClicked: TimerService.resetTimer(timer.id)
                }

                RippleButtonWithIcon {
                    materialIcon: "delete"
                    enabled: timer !== null
                    onClicked: TimerService.removeTimer(timer.id)
                }
            }
        }
    }
}
