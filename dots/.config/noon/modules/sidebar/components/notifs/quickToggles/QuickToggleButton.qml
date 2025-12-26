import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.store

GroupButton {
    id: root

    property string buttonIcon
    property string buttonName
    property bool showButtonName: buttonName.length > 0
    property bool hasDialog: false
    property int activeRadius: {
        const r1 = Rounding.verylarge;
        const r2 = Rounding.normal;
        if (toggled)
            return r2;
        else
            return r1;
    }

    signal requestDialog()

    Layout.fillWidth: showButtonName
    Layout.fillHeight: false
    baseWidth: !showButtonName ? 48 : (SidebarData.sizePresets.quarter / 2.5) - Padding.normal
    baseHeight: 48
    clip: true
    clickedWidth: implicitWidth
    toggled: false
    buttonRadius: toggled ? Rounding.verylarge : Rounding.normal
    buttonRadiusPressed: activeRadius
    color: toggled ? Colors.m3.m3primary : Colors.m3.m3surfaceContainer
    altAction: () => {
        if (!showButtonName)
            requestDialog();

    }

    StyledRect {
        id: dialogBox

        z: 99
        color: !toggled ? Colors.m3.m3primary : Colors.m3.m3surfaceContainerHigh
        visible: hasDialog && showButtonName
        enableShadows: true
        implicitWidth: 50
        topRightRadius: root.rightRadius
        bottomRightRadius: root.rightRadius

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            margins: -0.5
        }

        MaterialSymbol {
            id: symbol

            text: "keyboard_arrow_right"
            font.pixelSize: Fonts.sizes.huge
            fill: 1
            color: !toggled ? Colors.colOnPrimary : Colors.colOnLayer2
            anchors.centerIn: parent
            rotation: dialogBoxMouse.containsMouse ? 90 : 0

            Behavior on rotation {
                Anim {
                }

            }

        }

        MouseArea {
            id: dialogBoxMouse

            hoverEnabled: true
            anchors.fill: parent
            onReleased: {
                root.requestDialog();
                Noon.playSound("pressed");
            }
        }

    }

    Behavior on color {
        CAnim {
        }

    }

    contentItem: RowLayout {
        spacing: 10

        anchors {
            top: parent.top
            bottom: parent.bottom
            centerIn: !showButtonName ? parent : undefined
            right: dialogBox.left
            left: parent.left
            leftMargin: Padding.large
        }

        MaterialSymbol {
            font.pixelSize: Fonts.sizes.verylarge
            fill: toggled ? 1 : 0
            color: toggled ? Colors.colOnPrimary : Colors.colOnLayer2
            horizontalAlignment: Text.AlignHLeft
            verticalAlignment: Text.AlignVCenter
            Layout.leftMargin: parent.spacing / 2
            text: buttonIcon

            Behavior on color {
                CAnim {
                }

            }

        }

        StyledText {
            visible: showButtonName
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHLeft
            elide: Text.ElideRight // Truncates the text on the right
            font.pixelSize: Fonts.sizes.normal
            color: toggled ? Colors.colOnPrimary : Colors.colOnLayer2
            text: buttonName
        }

        Spacer {
        }

    }

}
