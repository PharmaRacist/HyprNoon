import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

/**
 * Material 3 button with expressive bounciness.
 * See https://m3.material.io/components/button-groups/overview
 */
Button {
    id: root
    property bool toggled
    property string buttonText
    property real buttonRadius: Rounding.small ?? 8
    property real buttonRadiusPressed: Rounding.small ?? 6
    property var downAction // When left clicking (down)
    property var releaseAction // When left clicking (release)
    property var altAction // When right clicking
    property var holdAction // When pressed and hold
    property var middleClickAction // When middle clicking
    property bool bounce: true
    property real baseWidth: contentItem.implicitWidth + horizontalPadding * 2
    property real baseHeight: contentItem.implicitHeight + verticalPadding * 2
    property real clickedWidth: baseWidth + 20
    property real clickedHeight: baseHeight
    property var parentGroup: root.parent
    property int clickIndex: parentGroup?.clickIndex ?? -1

    Layout.fillWidth: (clickIndex - 1 <= parentGroup.children.indexOf(root) && parentGroup.children.indexOf(root) <= clickIndex + 1)
    Layout.fillHeight: (clickIndex - 1 <= parentGroup.children.indexOf(root) && parentGroup.children.indexOf(root) <= clickIndex + 1)
    implicitWidth: (root.down && bounce) ? clickedWidth : baseWidth
    implicitHeight: (root.down && bounce) ? clickedHeight : baseHeight

    property color colBackground: ColorUtils.transparentize(Colors.colLayer1Hover, 1) || "transparent"
    property color colBackgroundHover: Colors.colLayer1Hover ?? "#E5DFED"
    property color colBackgroundActive: Colors.colLayer1Active ?? "#D6CEE2"
    property color colBackgroundToggled: Colors.colPrimary ?? "#65558F"
    property color colBackgroundToggledHover: Colors.colPrimaryHover ?? "#77699C"
    property color colBackgroundToggledActive: Colors.colPrimaryActive ?? "#D6CEE2"

    property real radius: root.down ? root.buttonRadiusPressed : root.buttonRadius
    property real leftRadius: root.down ? root.buttonRadiusPressed : root.buttonRadius
    property real rightRadius: root.down ? root.buttonRadiusPressed : root.buttonRadius
    property color color: root.enabled ? (root.toggled ? (root.down ? colBackgroundToggledActive : root.hovered ? colBackgroundToggledHover : colBackgroundToggled) : (root.down ? colBackgroundActive : root.hovered ? colBackgroundHover : colBackground)) : colBackground

    onDownChanged: {
        if (root.down) {
            if (root.parent.clickIndex !== undefined) {
                root.parent.clickIndex = parent.children.indexOf(root);
            }
        }
    }

    Behavior on implicitWidth {
        FAnim {}
    }

    Behavior on implicitHeight {
        FAnim {}
    }

    Behavior on leftRadius {
        FAnim {}
    }
    Behavior on rightRadius {
        FAnim {}
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressAndHold: root.holdAction()
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: event => {
            if (event.button === Qt.RightButton) {
                if (root.altAction)
                    root.altAction();
                return;
            }
            if (event.button === Qt.MiddleButton) {
                if (root.middleClickAction)
                    root.middleClickAction();
                return;
            }
            root.down = true;
            if (root.downAction)
                root.downAction();
        }
        onReleased: event => {
            root.down = false;
            if (event.button != Qt.LeftButton)
                return;
            if (root.releaseAction)
                root.releaseAction();
            root.click(); // Because the MouseArea already consumed the event
        }
        onCanceled: event => {
            root.down = false;
        }
    }

    background: Rectangle {
        id: buttonBackground
        topLeftRadius: root.leftRadius
        topRightRadius: root.rightRadius
        bottomLeftRadius: root.leftRadius
        bottomRightRadius: root.rightRadius
        implicitHeight: 50

        color: root.color
        Behavior on color {
            CAnim {}
        }
    }

    contentItem: StyledText {
        text: root.buttonText
    }
}
