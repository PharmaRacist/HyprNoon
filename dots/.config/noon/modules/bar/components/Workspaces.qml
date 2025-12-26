import qs.store
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property var bar

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / shownWs)
    readonly property int workspaceIndexInGroup: (monitor.activeWorkspace?.id - 1) % shownWs

    // Workspace configuration
    property int shownWs: Mem.options.bar.workspaces.shownWs
    property list<bool> workspaceOccupied: []

    // Visual properties - centralized
    readonly property int workspaceButtonWidth: 26
    readonly property real baseIconSize: workspaceButtonWidth * 0.69
    readonly property real shrinkedIconSize: workspaceButtonWidth * 0.55
    readonly property real shrinkedIconMargin: -4
    readonly property int buttonMargin: 2
    readonly property real previewScale: 0.2
    readonly property size previewMaxSize: Qt.size((bar.screen?.width ?? 1920) * previewScale, (bar.screen?.height ?? 1080) * previewScale)
    readonly property real previewIconScale: 0.15
    readonly property bool borders: Mem.options.bar.appearance.modulesBg
    readonly property int positionMultiplier: Mem.options.bar.behavior.position === "left" ? -1 : 1

    Layout.leftMargin: Padding.normal
    Layout.rightMargin: Padding.normal

    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({
            length: shownWs
        }, (_, i) => Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * shownWs + i + 1));
    }

    function findToplevelForWindow(hyprlandWindow) {
        if (!hyprlandWindow?.address)
            return null;

        return ToplevelManager.toplevels.values.find(toplevel => {
            if (!toplevel.HyprlandToplevel)
                return false;
            return `0x${toplevel.HyprlandToplevel.address}` === hyprlandWindow.address;
        }) ?? null;
    }

    Component.onCompleted: updateWorkspaceOccupied()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }

    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: rowLayout.implicitHeight

    WheelHandler {
        onWheel: event => Hyprland.dispatch(`workspace r${event.angleDelta.y < 0 ? '+' : '-'}1`)
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: event => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`togglespecialworkspace`);
            }
        }
    }

    BarGroup {
        implicitHeight: parent.height
        implicitWidth: rowLayout.width
    }

    // Background workspace indicators
    RowLayout {
        id: rowLayout
        z: 1
        spacing: 0
        anchors.fill: parent
        implicitHeight: 40

        Repeater {
            model: shownWs

            Rectangle {
                readonly property bool isActiveWorkspace: monitor.activeWorkspace?.id === index + 1
                readonly property bool isOccupied: workspaceOccupied[index] && !(isActiveWorkspace && !activeWindow?.activated)
                readonly property bool adjacentOccupiedLeft: workspaceOccupied[index - 1] && !isActiveWorkspace
                readonly property bool adjacentOccupiedRight: workspaceOccupied[index + 1] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index + 2)

                z: 1
                implicitWidth: workspaceButtonWidth
                implicitHeight: workspaceButtonWidth
                radius: Rounding.full
                color: "transparent"
                opacity: isOccupied ? 1 : 0

                topLeftRadius: adjacentOccupiedLeft ? 0 : Rounding.full
                bottomLeftRadius: adjacentOccupiedLeft ? 0 : Rounding.full
                topRightRadius: adjacentOccupiedRight ? 0 : Rounding.full
                bottomRightRadius: adjacentOccupiedRight ? 0 : Rounding.full

                Behavior on opacity {
                    Anim {}
                }
                Behavior on topLeftRadius {
                    Anim {}
                }
                Behavior on bottomLeftRadius {
                    Anim {}
                }
            }
        }
    }

    // Active workspace indicator
    Rectangle {
        readonly property real computedWidth: Math.abs(idx1 - idx2) * workspaceButtonWidth + workspaceButtonWidth - margin * 2
        readonly property real computedX: Math.min(idx1, idx2) * workspaceButtonWidth + margin

        z: 2
        property real margin: buttonMargin
        property real idx1: workspaceIndexInGroup
        property real idx2: workspaceIndexInGroup

        implicitHeight: workspaceButtonWidth - margin * 2
        implicitWidth: computedWidth
        anchors.verticalCenter: parent.verticalCenter
        x: computedX
        radius: Rounding.full
        color: Colors.colPrimary

        Behavior on margin {
            Anim {}
        }
        Behavior on idx1 {
            Anim {duration:Animations.durations.small}
        }
        Behavior on idx2 {
            Anim {duration:Animations.durations.large}
        }
    }

    // Workspace buttons with icons and popups
    RowLayout {
        id: rowLayoutNumbers
        z: 3
        spacing: 0
        anchors.fill: parent
        implicitHeight: 40

        Repeater {
            model: shownWs

            Button {
                id: button

                readonly property int workspaceValue: workspaceGroup * shownWs + index + 1
                readonly property string displayText: WorkspaceLabelManager.getDisplayText(workspaceValue)
                readonly property string currentMode: WorkspaceLabelManager.currentMode
                readonly property bool isActive: monitor.activeWorkspace?.id === workspaceValue

                readonly property var biggestWindow: {
                    const windows = HyprlandService.windowList.filter(w => w.workspace?.id === workspaceValue);
                    return windows.reduce((maxWin, win) => {
                        const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
                        const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
                        return winArea > maxArea ? win : maxWin;
                    }, null);
                }

                readonly property var windowToplevel: root.findToplevelForWindow(biggestWindow)
                readonly property string appIconSource: Noon.iconPath(AppSearch.guessIcon(biggestWindow?.class))
                readonly property bool showNumber: Mem.options.bar.workspaces.alwaysShowNumbers || GlobalStates.superHeld || !biggestWindow

                Layout.fillHeight: true
                width: workspaceButtonWidth
                onPressed: Hyprland.dispatch(`workspace ${workspaceValue}`)

                background: Item {
                    implicitWidth: workspaceButtonWidth
                    implicitHeight: workspaceButtonWidth

                    // Workspace number
                    MaterialSymbol {
                        readonly property color textColor: button.isActive ? Colors.colOnPrimary : (workspaceOccupied[index] ? Colors.colOnSecondaryContainer : Colors.colOnLayer1Inactive)

                        fill: 1
                        opacity: button.showNumber ? 0.8 : 0
                        anchors.centerIn: parent
                        font.family: WorkspaceLabelManager.getFontFamily(button.currentMode)
                        font.weight: WorkspaceLabelManager.getFontWeight(button.currentMode)
                        font.pixelSize: WorkspaceLabelManager.getFontPixelSize(button.currentMode, button.displayText)
                        text: button.displayText
                        color: textColor
                        horizontalAlignment: Qt.AlignCenter

                        Behavior on opacity {
                            Anim {}
                        }
                    }

                    // App icon with hover area
                    StyledIconImage {
                        id: mainAppIcon

                        readonly property real offsetMultiplier: button.showNumber ? 2 * root.shrinkedIconMargin : 0

                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.bottomMargin: button.showNumber ? root.shrinkedIconMargin : (workspaceButtonWidth - root.baseIconSize) / 2
                        anchors.rightMargin: button.showNumber ? root.shrinkedIconMargin : (workspaceButtonWidth - root.baseIconSize) / 2

                        source: button.appIconSource
                        implicitSize: button.showNumber ? root.shrinkedIconSize : root.baseIconSize
                        tint: 0.4
                        opacity: button.biggestWindow ? 1 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            Anim {}
                        }
                        Behavior on anchors.bottomMargin {
                            Anim {}
                        }
                        Behavior on anchors.rightMargin {
                            Anim {}
                        }
                        Behavior on implicitSize {
                            Anim {}
                        }

                        MouseArea {
                            id: iconHoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                // Live window preview popup
                StyledPopup {
                    name: `workspace-${button.workspaceValue}-preview`
                    hoverTarget: iconHoverArea
                    focus: false

                    StyledRect {
                        readonly property size targetSize: {
                            if (button.windowToplevel && button.biggestWindow?.size) {
                                const winWidth = button.biggestWindow.size[0];
                                const winHeight = button.biggestWindow.size[1];

                                if (winWidth <= 0 || winHeight <= 0)
                                    return root.previewMaxSize;

                                const aspectRatio = winWidth / winHeight;
                                let width = winWidth * root.previewScale;
                                let height = winHeight * root.previewScale;

                                if (width > root.previewMaxSize.width) {
                                    width = root.previewMaxSize.width;
                                    height = width / aspectRatio;
                                }

                                if (height > root.previewMaxSize.height) {
                                    height = root.previewMaxSize.height;
                                    width = height * aspectRatio;
                                }

                                return Qt.size(width, height);
                            }
                            return root.previewMaxSize;
                        }

                        clip: true
                        color: "transparent"
                        radius: Rounding.verylarge - Padding.normal
                        anchors.fill: parent
                        anchors.margins: Padding.normal
                        implicitWidth: targetSize.width - Padding.normal
                        implicitHeight: targetSize.height - Padding.normal

                        ScreencopyView {
                            id: preview
                            z: 0
                            anchors.fill: parent
                            constraintSize: Qt.size(parent.implicitWidth, parent.implicitHeight)
                            captureSource: button.windowToplevel || root.bar.screen
                            live: true
                            smooth: true
                        }

                        // Fallback app icon
                        IconImage {
                            z: 1
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: Padding.huge
                            width: Math.min(parent.implicitWidth, parent.implicitHeight) * root.previewIconScale
                            height: width
                            source: button.appIconSource
                            mipmap: true
                        }
                    }
                }
            }
        }
    }
}
