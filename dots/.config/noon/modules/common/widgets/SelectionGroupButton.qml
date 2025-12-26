import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

GroupButton {
    id: root

    property bool leftmost: false
    property bool rightmost: false

    horizontalPadding: 12
    verticalPadding: 8
    bounce: false
    leftRadius: (toggled || leftmost) ? (height / 2) : Rounding.verysmall
    rightRadius: (toggled || rightmost) ? (height / 2) : Rounding.verysmall
    colBackground: Colors.colSecondaryContainer

    contentItem: StyledText {
        color: parent.toggled ? Colors.colOnPrimary : Colors.colOnSecondaryContainer
        text: root.buttonText
    }

}
