import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

RippleButton {
    id: root

    property string displayText: ""

    colBackground: Colors.colLayer2
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: languageRow.implicitWidth
        implicitHeight: languageText.implicitHeight

        RowLayout {
            id: languageRow

            anchors.centerIn: parent
            spacing: 0

            StyledText {
                id: languageText

                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 5
                text: root.displayText
                color: Colors.colOnLayer2
                font.pixelSize: Fonts.sizes.small
            }

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: Fonts.sizes.huge
                text: "arrow_drop_down"
                color: Colors.colOnLayer2
            }

        }

    }

}
