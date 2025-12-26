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
    property color activeColor: Colors.colOnSecondaryContainer
    property color inactiveColor: ColorUtils.transparentize(Colors.colOnLayer1, 0.5)
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 8
    property int iconSpacing: 8
    property int fontSize: 16

    // Display mode: "icons" or "numbers"
    property string displayMode: "icons"
    property string workspaceIcon: "\uf004"

    // New: auto orientation mode (horizontal / vertical)
    property bool verticalMode:false

    property int workspaceIndexInGroup: (monitor.activeWorkspace?.id - 1) % Mem.options.bar.workspaces.shown

    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({
            length: Mem.options.bar.workspaces.shown
        }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * Mem.options.bar.workspaces.shown + i + 1);
        });
    }

    Component.onCompleted: updateWorkspaceOccupied()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }

    implicitWidth: !verticalMode ? layout.implicitWidth + widgetPadding * 2 : fontSize + widgetPadding * 2
    implicitHeight: verticalMode ? layout.implicitHeight + widgetPadding * 2 : fontSize + widgetPadding * 2

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
            if (event.button === Qt.BackButton)
                Hyprland.dispatch(`togglespecialworkspace`);
        }
    }

    // Switch between horizontal and vertical layout
    Loader {
        id: layout
        anchors.centerIn: parent
        sourceComponent: verticalMode ? columnLayout : rowLayout
    }

    // Horizontal layout
    Component {
        id: rowLayout
        RowLayout {
            spacing: iconSpacing
            Repeater {
                model: Mem.options.bar.workspaces.shown
                WorkspaceIndicator {}
            }
        }
    }

    // Vertical layout
    Component {
        id: columnLayout
        ColumnLayout {
            spacing: iconSpacing
            Repeater {
                model: Mem.options.bar.workspaces.shown
                WorkspaceIndicator {}
            }
        }
    }

        component WorkspaceIndicator :Item {
            id: workspaceItem
            property int workspaceValue: workspaceGroup * Mem.options.bar.workspaces.shown + index + 1
            property bool isActive: monitor.activeWorkspace?.id === workspaceValue
            property bool isOccupied: workspaceOccupied[index]
            property bool shouldShow: isActive || isOccupied

            implicitWidth: shouldShow ? iconText.implicitWidth : 0
            implicitHeight: shouldShow ? iconText.implicitHeight : 0
            visible: shouldShow

            states: [
                State {
                    name: "active"
                    when: workspaceItem.isActive
                    PropertyChanges { target: iconText; color: activeColor; scale: 1.2 }
                    PropertyChanges { target: workspaceItem; opacity: 1.0 }
                },
                State {
                    name: "inactive"
                    when: !workspaceItem.isActive && workspaceItem.shouldShow
                    PropertyChanges { target: iconText; color: inactiveColor; scale: 1.0 }
                    PropertyChanges { target: workspaceItem; opacity: 1.0 }
                },
                State {
                    name: "hidden"
                    when: !workspaceItem.shouldShow
                    PropertyChanges { target: workspaceItem; opacity: 0.0 }
                }
            ]

            transitions: [
                Transition {
                    from: "*"; to: "*"
                    CAnim { target: iconText; property: "color"; }
                    Anim { target: iconText; property: "scale" }
                    Anim { target: workspaceItem; property: "opacity"; }
                    Anim { target: workspaceItem; property: "implicitWidth" }
                }
            ]

            Text {
                id: iconText
                text: displayMode === "numbers" ? (index + 1).toString() : workspaceIcon
                font.pixelSize: fontSize
                anchors.centerIn: parent
                font.family: Fonts.family.monospace
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                onClicked: Hyprland.dispatch(`workspace ${workspaceItem.workspaceValue}`)
                cursorShape: Qt.PointingHandCursor
            }
    }
}
