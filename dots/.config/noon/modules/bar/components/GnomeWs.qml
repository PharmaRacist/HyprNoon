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
    required property var bar
    property bool borderless: !Mem.options.bar.appearance.modulesBg
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / 10)
    property color activeColor: Colors.colSecondary
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 8
    property int workspaceWidth: 10
    property int workspaceActiveWidth: 60
    property int workspaceActiveHeight: 15
    property int workspaceHeight: 10
    property int workspaceSpacing: 6
    property int workspaceIndexInGroup: (monitor.activeWorkspace?.id - 1) % Mem.options.bar.workspaces.shown

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({
            length: Mem.options.bar.workspaces.shown
        }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * Mem.options.bar.workspaces.shown + i + 1);
        });
    }

    // Initialize workspaceOccupied when the component is created
    Component.onCompleted: updateWorkspaceOccupied()

    // Listen for changes in Hyprland.workspaces.values
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }

    implicitWidth: rowLayout.implicitWidth + widgetPadding * 2
    implicitHeight: barHeight

    WheelHandler {
        onWheel: event => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`workspace r+1`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`workspace r-1`);
        }
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

    // Workspaces
    RowLayout {
        id: rowLayout
        z: 1
        spacing: workspaceSpacing
        anchors.centerIn: parent

        Repeater {
            model: Mem.options.bar.workspaces.shown

            Rectangle {
                id: workspaceRect
                property int workspaceValue: workspaceGroup * Mem.options.bar.workspaces.shown + index + 1
                property bool isActive: monitor.activeWorkspace?.id === workspaceValue
                property bool isOccupied: workspaceOccupied[index]
                property bool shouldShow: isActive || isOccupied

                implicitWidth: shouldShow ? (isActive ? workspaceActiveWidth : workspaceWidth) : 1 // prevent 0 width err
                implicitHeight: shouldShow ? (isActive ? workspaceActiveHeight : workspaceHeight) : 1
                radius: 99
                visible: shouldShow // ? 1.0 : 0.0

                // GNOME-style colors
                color: {
                    if (isActive) {
                        return activeColor;
                    } else if (isOccupied) {
                        return ColorUtils.transparentize(Colors.colOnLayer1, 0.3);
                    } else {
                        return ColorUtils.transparentize(Colors.colOnLayer1, 0.1);
                    }
                }

                // Smooth transitions
                Behavior on color {
                    CAnim {}
                }
                // Smooth width transition
                Behavior on implicitWidth {
                    Anim {}
                }

                // Smooth opacity transition
                Behavior on opacity {
                    Anim {}
                }

                // Click handler
                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch(`workspace ${workspaceRect.workspaceValue}`)
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
