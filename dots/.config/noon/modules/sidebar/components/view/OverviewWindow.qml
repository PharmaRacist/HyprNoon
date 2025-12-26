import qs.services
import qs.modules.common
import qs.modules.common.widgets

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Rectangle { // Window
    id: root
    property var toplevel
    property var windowData
    property var monitorData
    property var scale
    property var availableWorkspaceWidth
    property var availableWorkspaceHeight
    property bool restrictToWorkspace: true
    property real initX: Math.max((windowData?.at[0] - (monitorData?.x ?? 0) - monitorData?.reserved[0]) * root.scale, 0) + xOffset
    property real initY: Math.max((windowData?.at[1] - (monitorData?.y ?? 0) - monitorData?.reserved[1]) * root.scale, 0) + yOffset
    property real xOffset: 0
    property real yOffset: 0
    property var targetWindowWidth: windowData?.size[0] * scale
    property var targetWindowHeight: windowData?.size[1] * scale
    property bool hovered: false
    property bool pressed: false

    property var iconToWindowRatio: 0.3
    property var xwaylandIndicatorToIconRatio: 0.35
    property var iconToWindowRatioCompact: 0.6
    property var iconPath: Noon.iconPath(AppSearch.guessIcon(windowData?.class))
    property bool compactMode: Fonts.sizes.verysmall * 4 > targetWindowHeight || Fonts.sizes.verysmall * 4 > targetWindowWidth

    property bool indicateXWayland: (windowData?.xwayland) ?? false

    x: initX
    y: initY
    width: Math.round(Math.min(targetWindowWidth, (restrictToWorkspace ? availableWorkspaceWidth : availableWorkspaceWidth - x + xOffset)))
    height: Math.round(Math.min(targetWindowHeight, (restrictToWorkspace ? availableWorkspaceHeight : availableWorkspaceHeight - y + yOffset)))
    color: Colors.colLayer2
    radius: Rounding.verylarge
    border.color: Colors.colOutline
    StyledRectangularShadow {
        target: parent
    }
    Behavior on x {
        FAnim {}
    }
    Behavior on y {
        FAnim {}
    }
    Behavior on width {
        FAnim {}
    }
    Behavior on height {
        FAnim {}
    }
    clip: true

    Loader {
        id: windowLoader
        anchors.fill: parent
        anchors.margins: Padding.normal
        sourceComponent: StyledScreencopyView {
            id: windowPreview
            anchors.fill: parent
            captureSource: root.toplevel
            live: true

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: windowPreview.width
                    height: windowPreview.height
                    radius: Rounding.verylarge
                }
            }
        }
        Image {
            id: windowIcon
            property var iconSize: Math.min(targetWindowWidth, targetWindowHeight) * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio)
            mipmap: true
            source: root.iconPath
            width: iconSize
            height: iconSize
            sourceSize: Qt.size(iconSize, iconSize)
            anchors {
                centerIn: windowLoader
            }
            Behavior on width {
                Anim {}
            }
            Behavior on height {
                Anim {}
            }
        }
    }
}
