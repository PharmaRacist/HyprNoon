import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * A ListView with animations.
 */
ListView {
    id: root

    property real removeOvershoot: 100 // Account for gaps and bouncy animations
    property int dragIndex: -1
    property real dragDistance: 0
    property bool popin: true
    property bool clip: false
    property color colBackground: "transparent"
    property int radius: Rounding.large
    property bool animateAppearance: true
    property bool animateMovement: false
    property bool fasterInteractions: Mem.options.interactions.scrolling.fasterTouchpadScroll
    // Accumulated scroll destination so wheel deltas stack while animating
    property real scrollTargetY: 0
    property real touchpadScrollFactor: Mem.options.interactions.scrolling.touchpadScrollFactor ?? 100
    property real mouseScrollFactor: Mem.options.interactions.scrolling.mouseScrollFactor ?? 50
    property real mouseScrollDeltaThreshold: Mem.options.interactions.scrolling.mouseScrollDeltaThreshold ?? 120
    property bool hint: true

    ScrollEdgeFade {
        visible: root.hint
        target: root
        vertical: true
    }
    function resetDrag() {
        root.dragIndex = -1;
        root.dragDistance = 0;
    }

    spacing: 5
    maximumFlickVelocity: 1000
    boundsBehavior: Flickable.StopAtBounds
    // Keep target synced when not animating (e.g., drag/flick or programmatic changes)
    onContentYChanged: {
        if (!scrollAnim.running)
            root.scrollTargetY = root.contentY;
    }
    layer.enabled: root.clip

    Rectangle {
        z: -1
        anchors.fill: parent
        color: root.colBackground
    }

    MouseArea {
        visible: Mem.options.interactions.scrolling.fasterTouchpadScroll
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function (wheelEvent) {
            const delta = wheelEvent.angleDelta.y / root.mouseScrollDeltaThreshold;
            var scrollFactor = Math.abs(wheelEvent.angleDelta.y) >= root.mouseScrollDeltaThreshold ? root.mouseScrollFactor : root.touchpadScrollFactor;
            const maxY = Math.max(0, root.contentHeight - root.height);
            const base = scrollAnim.running ? root.scrollTargetY : root.contentY;
            var targetY = Math.max(0, Math.min(base - delta * scrollFactor * 0.08, maxY));
            root.scrollTargetY = targetY;
            root.contentY = targetY;
            wheelEvent.accepted = true;
        }
    }

    ScrollBar.vertical: StyledScrollBar {}

    Behavior on contentY {
        Anim {
            id: scrollAnim

            duration: Animations.durations.small
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Animations.curves.expressiveFastSpatial
        }
    }

    add: Transition {
        Anim {
            properties: root.popin ? "opacity,scale" : "opacity"
            from: 0
            to: 1
            duration: Animations.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Animations.curves.expressiveFastSpatial
        }
    }

    addDisplaced: Transition {
        Anim {
            properties: "y"
            duration: Animations.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Animations.curves.expressiveFastSpatial
        }

        Anim {
            properties: root.popin ? "opacity,scale" : "opacity"
            to: 1
            duration: Animations.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Animations.curves.expressiveFastSpatial
        }
    }

    displaced: Transition {
        ParallelAnimation {
            Anim {
                properties: "y"
                duration: Animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Animations.curves.expressiveFastSpatial
            }

            Anim {
                properties: root.popin ? "opacity,scale" : "opacity"
                to: 1
                duration: Animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Animations.curves.expressiveFastSpatial
            }
        }
    }

    move: Transition {
        ParallelAnimation {
            Anim {
                properties: "y"
                duration: Animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Animations.curves.expressiveFastSpatial
            }

            Anim {
                properties: root.popin ? "opacity,scale" : "opacity"
                to: 1
                duration: Animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Animations.curves.expressiveFastSpatial
            }
        }
    }

    moveDisplaced: Transition {
        ParallelAnimation {
            Anim {
                properties: "y"
                duration: Animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Animations.curves.expressiveFastSpatial
            }

            Anim {
                properties: root.popin ? "opacity,scale" : "opacity"
                to: 1
                duration: Animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Animations.curves.expressiveFastSpatial
            }
        }
    }

    remove: Transition {
        ParallelAnimation {
            Anim {
                properties: "x"
                to: root.width + root.removeOvershoot
                duration: Animations.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Animations.curves.expressiveFastSpatial
            }

            Anim {
                properties: "opacity"
                to: 0
                duration: Animations.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Animations.curves.expressiveFastSpatial
            }
        }
    }

    // This is movement when something is removed, not removing animation!
    removeDisplaced: Transition {
        ParallelAnimation {
            Anim {
                properties: "y"
            }

            Anim {
                properties: root.popin ? "opacity,scale" : "opacity"
                to: 1
            }
        }
    }

    layer.effect: OpacityMask {

        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }
}
