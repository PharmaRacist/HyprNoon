import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property int collapsedHeight: 200
    property int expandedHeight: 400
    property bool expand: false
    property bool show: false
    property bool revealOnWheel: true
    property bool enableStagedReveal: true
    property bool bottomAreaReveal: false
    property int hoverHeight: 100
    property var contentItem
    property alias backgroundColor: bg.color
    property alias topRadius: bg.topRadius
    property alias enableShadows: bg.enableShadows
    property alias bgAnchors: bg.anchors
    property alias backgroundOpacity: bg.opacity
    readonly property bool reveal: show || bg.visible
    readonly property int targetHeight: show ? (expand && enableStagedReveal ? expandedHeight : collapsedHeight) : 0
    property var finishAction

    onRevealChanged: {
        if (!reveal)
            return finishAction();

    }
    anchors.fill: parent

    Rectangle {
        z: -1
        opacity: root.reveal ? 1 : 0
        color: ColorUtils.transparentize(Colors.m3.m3surfaceDim, 0.24)
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: root.show ? Qt.LeftButton : Qt.NoButton
            onClicked: root.show = false
        }

        Behavior on opacity {
            Anim {
                duration: Animations.durations.normal
                easing.bezierCurve: Animations.curves.emphasized
            }

        }

    }

    MouseArea {
        property int scrollSum: 0
        readonly property int threshold: 750

        height: root.bottomAreaReveal ? root.hoverHeight : parent.height
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        scrollGestureEnabled: root.revealOnWheel
        onWheel: (wheel) => {
            if (!root.revealOnWheel) {
                wheel.accepted = false;
                return ;
            }
            scrollSum += wheel.angleDelta.y;
            if (Math.abs(scrollSum) >= threshold) {
                if (scrollSum > 0) {
                    if (!root.show) {
                        root.show = true;
                        root.expand = false;
                    } else if (!root.expand && root.enableStagedReveal) {
                        root.expand = true;
                    }
                } else {
                    if (root.expand && root.enableStagedReveal)
                        root.expand = false;
                    else if (root.show)
                        root.show = false;
                }
                scrollSum = 0;
            }
            wheel.accepted = true;
        }

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

    }

    StyledRect {
        id: bg

        z: 999
        visible: height > 0
        height: root.targetHeight
        topRadius: Rounding.verylarge
        color: Colors.m3.m3surfaceContainerLow
        enableShadows: true
        children: root.contentItem
        Component.onCompleted: {
            if (contentItem)
                contentItem.anchors.fill = bg;

        }

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Behavior on anchors.rightMargin {
            Anim {
            }

        }

        Behavior on anchors.leftMargin {
            Anim {
            }

        }

        Behavior on height {
            Anim {
                duration: Animations.durations.normal
                easing.bezierCurve: Animations.curves.emphasized
            }

        }

    }

}
