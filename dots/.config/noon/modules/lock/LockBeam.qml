import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledRect {
    id: entryArea

    z: 99
    implicitHeight: 60
    implicitWidth: passwordBox.length > 5 ? Sizes.beamSizeExpanded.width : Sizes.beamSize.width
    radius: Rounding.large
    color: Colors.colLayer1
    enableShadows: true
    enableBorders: false

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: -60 + Sizes.elevationMargin
    }

    TextField {
        id: passwordBox

        enabled: !root.context.unlockInProgress
        leftPadding: 72
        rightPadding: 30
        topPadding: 0
        bottomPadding: 0
        focus: true
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
        placeholderText: "Enter your password"
        font.pixelSize: 16
        color: Colors.m3.m3onSurface
        selectionColor: Colors.m3.m3primary
        onAccepted: root.context.tryUnlock()
        onTextChanged: root.context.currentText = this.text
        scale: focus ? 1.05 : 1
        background: null

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: enter.left
        }

        MaterialShape {
            id: lockSymb

            z: 999
            implicitSize: parent.height * 0.6
            shape: MaterialShape.Cookie6Sided
            color: Colors.colSecondaryContainer

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Padding.massive
            }

            StyledText {
                anchors.centerIn: parent
                animateChange: true
                text: HyprlandData.keyboardLayoutShortName
            }

        }

        Connections {
            function onCurrentTextChanged() {
                passwordBox.text = root.context.currentText;
            }

            target: root.context
        }

        Behavior on scale {
            Anim {
            }

        }

    }

    RippleButtonWithIcon {
        id: enter

        enabled: passwordBox.text.length > 0 && !root.context.unlockInProgress
        materialIcon: "arrow_forward"
        implicitSize: 45
        releaseAction: () => {
            root.context.tryUnlock();
        }

        anchors {
            right: parent.right
            rightMargin: Padding.normal
            verticalCenter: parent.verticalCenter
        }

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

    }

    Behavior on implicitWidth {
        Anim {
        }

    }

    Anim on anchors.bottomMargin {
        from: -implicitHeight
        to: Sizes.elevationMargin
    }

}
