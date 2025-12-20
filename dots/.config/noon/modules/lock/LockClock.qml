import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ColumnLayout {
    id: root

    Layout.topMargin: Padding.massive
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: 160
    spacing: -Padding.normal

    StyledText {
        id: clockText

        Layout.alignment: Qt.AlignHCenter
        font.family: Fonts.family.numbers
        font.variableAxes: Fonts.variableAxes.longNumbers
        horizontalAlignment: Text.AlignHCenter
        color: Colors.colOnLayer0
        font.pixelSize: 200
        text: `${DateTime.hour}:${DateTime.minute}`
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        font.family: Fonts.family.title
        font.variableAxes: Fonts.variableAxes.title
        color: clockText.color
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 25
        opacity: 0.75
        text: DateTime.date
    }

}
