import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

FocusScope {
    id: root

    property bool revealAddDialog: false

    Keys.onPressed: (event) => {
        if ((event.modifiers & Qt.ControlModifier)) {
            if (event.key === Qt.Key_L)
                AlarmService.clearAll();

            if (event.key === Qt.Key_R)
                AlarmService.reload();

            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Padding.gigantic

        StyledText {
            text: "Alarms"
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
            model: AlarmService.alarms

            PagePlaceholder {
                shown: !AlarmService.hasAlarms
                icon: "timer"
                title: "No active alarms"
            }

            delegate: AlarmItem {
                width: listView.width
                alarmData: modelData
            }

        }

    }

    BottomDialog {
        id: bottomDialog

        show: revealAddDialog
        collapsedHeight: 380
        enableStagedReveal: false
        bottomAreaReveal: true
        hoverHeight: 200
        onShowChanged: root.revealAddDialog = bottomDialog.show
        expand: true

        contentItem: Item {
            function addTimer() {
                if (nameField.text) {
                    const time = `${timePicker.hour}:${timePicker.minute}`;
                    const message = nameField.text;
                    AlarmService.addTimer(time, message);
                    bottomDialog.show = false;
                }
            }

            anchors.fill: parent

            ColumnLayout {
                id: content

                spacing: Padding.normal

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
                        text: "Add Timer"
                        font.pixelSize: Fonts.sizes.subTitle
                        color: Colors.colOnLayer2
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }

                    Spacer {
                    }

                    RippleButtonWithIcon {
                        materialIcon: "close"
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        releaseAction: () => {
                            return bottomDialog.show = false;
                        }
                    }

                }

                Separator {
                }

                RowLayout {
                    id: nameArea

                    Layout.fillWidth: true
                    Layout.preferredHeight: 30

                    TextField {
                        id: nameField

                        Layout.fillWidth: true
                        Layout.leftMargin: Padding.normal
                        placeholderText: "Name"
                        background: null
                        selectionColor: Colors.colPrimaryContainer
                        selectedTextColor: Colors.m3.m3onPrimaryContainer
                        color: Colors.colOnLayer0
                        placeholderTextColor: Colors.colSubtext
                        selectByMouse: true
                        onAccepted: bottomDialog.addTimer()
                    }

                }

                TimePicker {
                    id: timePicker

                    clockPicker: true
                }

                Spacer {
                }

            }

            RippleButton {
                id: saveButton

                visible: bottomDialog.height > 300
                buttonRadius: Rounding.verylarge
                colBackground: Colors.colPrimaryContainer
                implicitWidth: 100
                implicitHeight: 50
                releaseAction: () => {
                    return bottomDialog.addTimer();
                }

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

    component AlarmItem: RippleButton {
        id: alarmRoot

        property var alarmData: null
        readonly property int timeUntilSeconds: {
            if (!alarmData || !alarmData.time)
                return 0;

            let alarmTime = new Date(alarmData.time);
            let now = new Date();
            return alarmTime > now ? Math.floor((alarmTime - now) / 1000) : 0;
        }

        implicitHeight: 110
        colBackground: Colors.colLayer1
        buttonRadius: Rounding.normal
        clip: true
        visible: alarmData !== null && alarmData !== undefined
        releaseAction: () => {
            if (alarmData && alarmData.id)
                toggleSwitch.checked = !toggleSwitch.checked;

        }

        RowLayout {
            id: mainRow

            anchors {
                fill: parent
                margins: Padding.large
                leftMargin: Padding.gigantic
                rightMargin: Padding.massive
            }

            ColumnLayout {
                id: infoColumn

                Layout.fillHeight: true
                Layout.preferredWidth: parent.width / 2
                spacing: 0

                StyledText {
                    id: alarmTime

                    Layout.fillWidth: true
                    font.pixelSize: Fonts.sizes.subTitle
                    color: Colors.colOnLayer1
                    maximumLineCount: 1
                    font.variableAxes: Fonts.variableAxes.numbers
                    horizontalAlignment: Text.AlignLeft
                    text: alarmData ? (alarmData.period || AlarmService.formatTime(alarmData.time)) : ""
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    StyledText {
                        id: alarmName

                        Layout.fillWidth: true
                        font.pixelSize: Fonts.sizes.normal
                        color: Colors.colOnLayer1
                        maximumLineCount: 1
                        horizontalAlignment: Text.AlignLeft
                        text: alarmData ? (alarmData.message || "Unnamed Alarm") : ""
                    }

                    StyledText {
                        font.pixelSize: Fonts.sizes.small
                        color: Colors.colSubtext
                        opacity: 0.6
                        text: AlarmService.formatUntil(alarmRoot.timeUntilSeconds)
                        Layout.alignment: Qt.AlignLeft
                    }

                }

            }

            Item {
                Layout.fillWidth: true
            }

            StyledSwitch {
                id: toggleSwitch

                scale: 1
                checked: alarmData ? (alarmData.active || false) : false
                enabled: alarmData ? (alarmRoot.timeUntilSeconds >= 0) : false
                onCheckedChanged: {
                    if (alarmData && alarmData.id) {
                        console.log("Toggle alarm ID:", alarmData.id, "to", checked);
                        AlarmService.toggleAlarm(alarmData.id, checked); // ✅ Use ID not time
                    }
                }
            }

        }

    }

}
