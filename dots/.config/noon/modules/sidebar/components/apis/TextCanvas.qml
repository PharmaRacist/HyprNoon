import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    // border.color: isInput ? Colors.colOutlineVariant : "transparent"
    // border.width: isInput ? 1 : 0

    id: root

    property bool isInput: true // true for input, false for output
    property string placeholderText
    property string text: ""
    property var inputTextArea: isInput ? inputLoader.item : undefined
    readonly property string displayedText: isInput ? inputLoader.item.text : root.text.length > 0 ? outputLoader.item.text : ""
    default property alias actionButtons: actions.data

    signal inputTextChanged() // Signal emitted when text changes

    Layout.fillWidth: true
    implicitHeight: Math.max(100, inputColumn.implicitHeight)
    color: isInput ? Colors.colLayer1 : Colors.colSurfaceContainer
    radius: Rounding.verylarge - 5

    ColumnLayout {
        id: inputColumn

        anchors.fill: parent
        spacing: 0

        Loader {
            id: inputLoader

            active: root.isInput
            visible: root.isInput
            Layout.fillWidth: true

            // Input area
            sourceComponent: StyledTextArea {
                id: inputTextArea

                placeholderText: root.placeholderText
                wrapMode: TextEdit.Wrap
                textFormat: TextEdit.PlainText
                font.pixelSize: Fonts.sizes.small
                font.family: Fonts.family.main
                color: Colors.colOnLayer1
                padding: 15
                background: null
                onTextChanged: root.inputTextChanged()
            }

        }

        Loader {
            id: outputLoader

            active: !root.isInput
            visible: !root.isInput
            Layout.fillWidth: true

            // Output area
            sourceComponent: StyledText {
                id: outputTextArea

                padding: 15
                wrapMode: Text.Wrap
                font.pixelSize: Fonts.sizes.small
                color: root.text.length > 0 ? Colors.colOnLayer1 : Colors.colSubtext
                text: root.text.length > 0 ? root.text : root.placeholderText
            }

        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            // Status row
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10

            Loader {
                active: root.isInput
                visible: root.isInput
                Layout.leftMargin: 10

                sourceComponent: StyledText {
                    text: qsTr("%1 characters").arg(inputLoader.item.text.length)
                    color: Colors.colOnLayer1
                    font.pixelSize: Fonts.sizes.verysmall
                }

            }

            Item {
                Layout.fillWidth: true
            }

            ButtonGroup {
                id: actions
            }

        }

    }

}
