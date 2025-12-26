import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

TabButton {
    id: button
    property string buttonText
    property string buttonIcon
    property real minimumWidth: 110
    property bool selected: false
    property int tabContentWidth: contentItem.children[0].implicitWidth
    property int rippleDuration: 1200
    height: buttonBackground.height
    implicitWidth: Math.max(tabContentWidth, buttonBackground.implicitWidth, minimumWidth)

    property color colBackground: ColorUtils.transparentize(Colors.colLayer0, 1) || "transparent"
    property color colBackgroundHover: Colors.colLayer1Hover ?? "#E5DFED"
    property color colRipple: Colors.colLayer1Active ?? "#D6CEE2"
    property color colActive: Colors.colPrimary ?? "#65558F"
    property color colInactive: Colors.colOnLayer1 ?? "#45464F"

    component RippleAnim: Anim {}

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => {
            const {
                x,
                y
            } = event;
            const stateY = buttonBackground.y;
            rippleAnim.x = x;
            rippleAnim.y = y - stateY;

            const dist = (ox, oy) => ox * ox + oy * oy;
            const stateEndY = stateY + buttonBackground.height;
            rippleAnim.radius = Math.sqrt(Math.max(dist(0, stateY), dist(0, stateEndY), dist(width, stateY), dist(width, stateEndY)));

            rippleFadeAnim.complete();
            rippleAnim.restart();
        }
        onReleased: event => {
            button.click(); // Because the MouseArea already consumed the event
            rippleFadeAnim.restart();
        }
    }

    RippleAnim {
        id: rippleFadeAnim
        target: ripple
        property: "opacity"
        to: 0
    }

    SequentialAnimation {
        id: rippleAnim

        property real x
        property real y
        property real radius

        PropertyAction {
            target: ripple
            property: "x"
            value: rippleAnim.x
        }
        PropertyAction {
            target: ripple
            property: "y"
            value: rippleAnim.y
        }
        PropertyAction {
            target: ripple
            property: "opacity"
            value: 1
        }
        ParallelAnimation {
            RippleAnim {
                target: ripple
                properties: "implicitWidth,implicitHeight"
                from: 0
                to: rippleAnim.radius * 2
            }
        }
    }

    background: Rectangle {
        id: buttonBackground
        radius: Rounding.small
        implicitHeight: 50
        color: (button.hovered ? button.colBackgroundHover : button.colBackground)
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: buttonBackground.width
                height: buttonBackground.height
                radius: buttonBackground.radius
            }
        }

        Behavior on color {
            CAnim {}
        }

        Item {
            id: ripple
            width: ripple.implicitWidth
            height: ripple.implicitHeight
            opacity: 0

            property real implicitWidth: 0
            property real implicitHeight: 0
            visible: width > 0 && height > 0

            Behavior on opacity {
                FAnim {}
            }

            RadialGradient {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: button.colRipple
                    }
                    GradientStop {
                        position: 0.3
                        color: button.colRipple
                    }
                    GradientStop {
                        position: 0.5
                        color: Qt.rgba(button.colRipple.r, button.colRipple.g, button.colRipple.b, 0)
                    }
                }
            }

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }

    contentItem: Item {
        anchors.centerIn: buttonBackground
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            MaterialSymbol {
                visible: buttonIcon?.length > 0
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: buttonIcon
                font.pixelSize: Fonts.sizes.huge ?? 25
                fill: selected ? 1 : 0
                color: selected ? button.colActive : button.colInactive
                Behavior on color {
                    CAnim {}
                }
            }
            StyledText {
                id: buttonTextWidget
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Fonts.sizes.small
                color: selected ? button.colActive : button.colInactive
                text: buttonText
                Behavior on color {
                    CAnim {}
                }
            }
        }
    }
}
