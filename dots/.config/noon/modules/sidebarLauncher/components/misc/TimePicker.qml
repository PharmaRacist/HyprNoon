import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property int hour: 0
    property int minute: 0
    property bool clockPicker: true
    property color onSurface: Colors.colOnLayer3
    property color outline: Colors.colOutline
    property color surface: Colors.colLayer3

    Layout.fillWidth: true
    Layout.topMargin: Padding.large
    Layout.preferredHeight: 140

    RowLayout {
        anchors {
            // rightMargin: Padding.large
            // leftMargin: Padding.large

            fill: parent
        }

        TimeField {
            id: hourField

            fieldPlaceholder: clockPicker ? "12" : "00"
            fieldText: clockPicker ? "12" : root.hour.toString().padStart(2, '0')
            onTextChanged: root.hour = text
        }

        Text {
            text: ":"
            font.pixelSize: Fonts.sizes.title
            color: Colors.colOnLayer2
            opacity: 0.6
            Layout.alignment: Qt.AlignVCenter
        }

        TimeField {
            // onAccepted: root.minute = text;

            id: minuteField

            fieldPlaceholder: root.minute
            fieldText: root.minute.toString().padStart(2, '0')
            // fieldValidator: RegularExpressionValidator {
            //     regularExpression: /^[0-5][0-9]$/
            // }
            onTextChanged: root.minute = text
        }

        Text {
            text: ":"
            font.pixelSize: Fonts.sizes.title
            color: Colors.colOnLayer2
            opacity: 0.6
            Layout.alignment: Qt.AlignVCenter
            visible: clockPicker
        }

        TimeField {
            id: ampmField

            fieldPlaceholder: "AM"
            fieldText: "AM"
            fieldReadOnly: true
            visible: clockPicker
        }

    }

    component TimeField: TextField {
        id: field

        property string fieldPlaceholder: ""
        property string fieldText: ""
        property bool fieldReadOnly: false
        property var fieldValidator: null

        Layout.preferredHeight: parent.height
        Layout.fillWidth: true
        Layout.preferredWidth: parent.width / 3
        placeholderText: fieldPlaceholder
        text: fieldText
        font.pixelSize: 100
        font.family: Fonts.family.numbers
        font.variableAxes: Fonts.variableAxes.longNumbers
        color: Colors.colOnLayer2
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        selectByMouse: true
        selectionColor: Colors.colPrimary
        selectedTextColor: Colors.m3.m3onPrimaryContainer
        placeholderTextColor: Colors.colSubtext
        validator: fieldValidator

        background: StyledRect {
            border.color: field.focus ? Colors.colPrimary : "transparent"
            border.width: 2
            implicitHeight: parent.height
            radius: Rounding.normal
            color: Colors.colLayer3

            Behavior on border.color {
                CAnim {
                }

            }

        }

    }

}
