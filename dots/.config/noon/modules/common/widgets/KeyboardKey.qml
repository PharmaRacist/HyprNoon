import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common

Rectangle {
    id: root

    property string key
    property real horizontalPadding: 10
    property real verticalPadding: 3.5
    property real borderWidth: 0
    property real extraBottomBorderWidth: 2
    property color borderColor: Colors.colOnLayer0
    property real borderRadius: Rounding.small
    property color keyColor: Colors.m3.m3surfaceContainerLow

    implicitWidth: keyFace.implicitWidth + borderWidth * 2
    implicitHeight: keyFace.implicitHeight + borderWidth * 2 + extraBottomBorderWidth
    radius: borderRadius
    color: borderColor

    Rectangle {
        id: keyFace

        implicitWidth: keyText.implicitWidth + horizontalPadding * 2
        implicitHeight: keyText.implicitHeight + verticalPadding * 2
        color: keyColor
        radius: borderRadius - borderWidth

        anchors {
            fill: parent
            topMargin: borderWidth
            leftMargin: borderWidth
            rightMargin: borderWidth
            bottomMargin: extraBottomBorderWidth + borderWidth
        }

        StyledText {
            id: keyText

            anchors.centerIn: parent
            font.family: Fonts.family.main
            font.pixelSize: Fonts.sizes.verysmall
            text: key
        }

    }

}
