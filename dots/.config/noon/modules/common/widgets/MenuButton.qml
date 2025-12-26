import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common

RippleButton {
    id: root

    buttonRadius: 0
    implicitHeight: 36
    implicitWidth: buttonTextWidget.implicitWidth + 14 * 2

    contentItem: StyledText {
        id: buttonTextWidget

        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        text: root.buttonText
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: Fonts.sizes.small
        color: root.enabled ? Colors.m3.m3onSurface : Colors.m3.m3outline

        Behavior on color {
            CAnim {
            }

        }

    }

}
