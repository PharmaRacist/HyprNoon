import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

TabButton {
    id: root
    property string buttonText
    property string buttonIcon
    property bool showIcons: true
    property bool selected: false
    property int rippleDuration: 1200
    property int fontSize: Fonts.sizes.large

    height: buttonBackground.height
    property int tabContentWidth: buttonBackground.width - buttonBackground.radius * 2

    property color colBackground: ColorUtils.transparentize(Colors.colLayer1Hover, 1)
    property color colBackgroundHover: Colors.colLayer1Hover
    property color colRipple: Colors.colLayer1Active
    property color colTextSelected: Colors.colPrimary
    property color colText: Colors.colOnLayer1

    PointingHandInteraction {}

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
            root.click(); // Because the MouseArea already consumed the event
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
        radius: Rounding.small ?? 7
        implicitHeight: 37
        color: (root.hovered ? root.colBackgroundHover : root.colBackground)
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

        Rectangle {
            id: ripple

            radius: Rounding.full
            color: root.colRipple
            opacity: 0

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }

    contentItem: Item {
        anchors.centerIn: buttonBackground
        RowLayout {
            anchors.centerIn: parent
            spacing: 0

            Loader {
                id: iconLoader
                active: showIcons && buttonIcon?.length > 0
                sourceComponent: buttonIcon?.length > 0 ? materialSymbolComponent : null
                Layout.rightMargin: 5
            }

            Component {
                id: materialSymbolComponent
                MaterialSymbol {
                    verticalAlignment: Text.AlignVCenter
                    text: buttonIcon
                    font.pixelSize: Fonts.sizes.huge
                    fill: selected ? 1 : 0
                    color: selected ? root.colTextSelected : root.colText
                    Behavior on color {
                        CAnim {}
                    }
                }
            }
            StyledText {
                id: buttonTextWidget
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.family: Fonts.family.main
                font.pixelSize: fontSize
                color: selected ? root.colTextSelected : root.colText
                text: buttonText
                Behavior on color {
                    CAnim {}
                }
            }
        }
    }
}
