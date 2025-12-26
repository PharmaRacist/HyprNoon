import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 expressive split button with primary and secondary actions
 */
Item {
    id: root

    // Public properties
    property bool enabled: true
    property bool toggled: false
    property bool autoToggle: true // Whether primary button toggles itself on click
    property string primaryText: "Primary"
    property string primaryIcon: "expand_more"
    property string secondaryIcon: "expand_more"
    property real buttonRadius: 99
    property real buttonSmallRadius: 8
    property real buttonHeight: 45
    property int transitionDuration: 200
    property int buttonWide: 100
    property int buttonShrinked: buttonHeight
    // State properties
    property bool primaryPressed: false
    property bool secondaryPressed: false
    property color secondaryBgColor: {
        if (!enabled)
            return Colors.colSecondaryContainer;

        if (secondaryPressed)
            return Colors.colSecondaryContainerActive;

        if (secondaryMouseArea.containsMouse)
            return Colors.colSecondaryContainerHover;

        return Colors.colSecondaryContainer;
    }

    // Signals
    signal primaryClicked()
    signal secondaryClicked()

    // Size binding
    implicitWidth: content.width
    implicitHeight: buttonHeight
    // Opacity based on enabled state
    opacity: enabled ? 1 : 0.38
    // Focus handling
    focus: true
    Keys.onPressed: {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
            if (autoToggle)
                root.toggled = !root.toggled;

            root.primaryClicked();
            event.accepted = true;
        }
    }
    // Accessibility
    Accessible.role: Accessible.ButtonMenu
    Accessible.name: primaryText
    Accessible.description: "Split button with primary action: " + primaryText + " and secondary action"
    Accessible.onPressAction: primaryMouseArea.clicked()

    RowLayout {
        id: content

        anchors.fill: parent
        spacing: 3

        // Primary button (left side)
        Rectangle {
            id: primaryButton

            Layout.fillHeight: true
            Layout.preferredWidth: !secondaryPressed ? buttonWide : buttonShrinked // Square button
            height: buttonHeight
            topLeftRadius: buttonRadius
            bottomLeftRadius: buttonRadius
            topRightRadius: buttonSmallRadius
            bottomRightRadius: buttonSmallRadius
            color: {
                if (!enabled)
                    return Colors.colSecondaryContainer;

                if (primaryPressed)
                    return Colors.colSecondaryContainerActive;

                if (primaryMouseArea.containsMouse)
                    return Colors.colSecondaryContainerHover;

                return Colors.colSecondaryContainer;
            }

            StyledRectangularShadow {
                target: parent
            }
            // Color states based on mouse area state

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                MaterialSymbol {
                    id: primaryIconLabel

                    text: root.primaryIcon
                    color: Colors.colOnSecondaryContainer
                    fill: 1
                    font.pixelSize: Fonts.sizes.huge

                    Behavior on color {
                        CAnim {
                        }

                    }

                }
                // Primary button text

                StyledText {
                    id: primaryTextLabel

                    visible: !secondaryPressed
                    text: root.primaryText
                    color: Colors.colOnSecondaryContainer
                    font.pixelSize: 18

                    Behavior on color {
                        ColorAnimation {
                            duration: transitionDuration
                        }

                    }

                }

            }

            // Primary button mouse area
            MouseArea {
                id: primaryMouseArea

                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: primaryPressed = true
                onReleased: primaryPressed = false
                onClicked: {
                    if (autoToggle)
                        root.toggled = !root.toggled;

                    root.primaryClicked();
                }
            }

            Behavior on Layout.preferredWidth {
                Anim {
                }

            }
            // Rounded corners - left side only

            // Smooth color transitions
            Behavior on color {
                ColorAnimation {
                    duration: transitionDuration
                }

            }

        }

        // Secondary button (right side)
        Rectangle {
            id: secondaryButton

            Layout.fillHeight: true
            Layout.preferredWidth: secondaryPressed ? buttonWide : buttonShrinked // Square button
            height: buttonHeight
            topLeftRadius: buttonSmallRadius
            bottomLeftRadius: buttonSmallRadius
            topRightRadius: buttonRadius
            bottomRightRadius: buttonRadius
            // Color states based on mouse area state
            color: {
                if (!enabled)
                    return Colors.colSecondaryContainer;

                if (secondaryPressed)
                    return Colors.colSecondaryContainerActive;

                if (secondaryMouseArea.containsMouse)
                    return Colors.colSecondaryContainerHover;

                return Colors.colSecondaryContainer;
            }

            StyledRectangularShadow {
                target: parent
            }

            // Secondary button icon with rotation effect
            MaterialSymbol {
                id: secondaryIconLabel

                anchors.centerIn: parent
                text: root.secondaryIcon
                color: Colors.colOnSecondaryContainer
                font.pixelSize: buttonHeight * 0.5
                // Rotation based on interaction state
                rotation: {
                    if (secondaryPressed)
                        return 180;

                    if (secondaryMouseArea.containsMouse)
                        return 90;

                    return 0;
                }

                // Smooth rotation animation
                Behavior on rotation {
                    NumberAnimation {
                        duration: transitionDuration
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: transitionDuration
                    }

                }

            }

            // Secondary button mouse area
            MouseArea {
                id: secondaryMouseArea

                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: secondaryPressed = true
                onReleased: secondaryPressed = false
                onClicked: {
                    root.secondaryClicked();
                }
            }

            Behavior on Layout.preferredWidth {
                Anim {
                }

            }
            // Rounded corners - right side only

            // Smooth color transitions
            Behavior on color {
                CAnim {
                }

            }

        }

    }

}
