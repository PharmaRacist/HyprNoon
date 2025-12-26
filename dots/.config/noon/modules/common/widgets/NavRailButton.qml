import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Button {
    id: button

    property bool toggled
    property string buttonIcon
    property string buttonText

    Layout.alignment: Qt.AlignHCenter
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    background: null

    PointingHandInteraction {
    }

    // Real stuff
    ColumnLayout {
        id: columnLayout

        spacing: 12

        Rectangle {
            width: 62
            implicitHeight: navRailButtonIcon.height + 2 * 2
            Layout.alignment: Qt.AlignHCenter
            radius: Rounding.full
            color: toggled ? (button.down ? Colors.colSecondaryContainerActive : button.hovered ? Colors.colSecondaryContainerHover : Colors.colSecondaryContainer) : (button.down ? Colors.colLayer1Active : button.hovered ? Colors.colLayer1Hover : ColorUtils.transparentize(Colors.colLayer1Hover, 1))

            MaterialSymbol {
                id: navRailButtonIcon

                anchors.centerIn: parent
                font.pixelSize: Fonts.sizes.huge
                fill: toggled ? 1 : 0
                text: buttonIcon
                color: toggled ? Colors.m3.m3onSecondaryContainer : Colors.colOnLayer1

                Behavior on color {
                    CAnim {
                    }

                }

            }

            Behavior on color {
                CAnim {
                }

            }

        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: buttonText
            color: Colors.colOnLayer1
        }

    }

}
