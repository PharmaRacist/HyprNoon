import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    required property var panelWindow
    readonly property HyprlandMonitor monitor: panelWindow ? Hyprland.monitorFor(panelWindow.screen) : null
    readonly property var toplevels: ToplevelManager.toplevels
    property real windowOffset: 0.014
    property int rowsNumber: height / workspaceImplicitHeight
    property int columnsNumber: width / workspaceImplicitWidth
    readonly property int workspacesShown: rowsNumber * columnsNumber
    readonly property int workspaceGroup: Math.floor(((monitor?.activeWorkspace?.id ?? 1) - 1) / workspacesShown)
    property bool monitorIsFocused: (Hyprland.focusedMonitor?.id === monitor?.id)
    property var windows: HyprlandService.windowList
    property var windowByAddress: HyprlandService.windowByAddress
    property var windowAddresses: HyprlandService.addresses
    property real wsWidthMultiplier: 1
    property var monitorData: HyprlandService.monitors.find(m => m.id === root.monitor?.id) ?? null
    property real scale: 0.18
    property color activeBorderColor: Colors.colSecondary
    property bool expanded: false
    // Determine if we're in vertical mode (more rows than columns)
    readonly property bool isVerticalMode: rowsNumber > columnsNumber

    // Function to get workspace display text (ignoring symbol replacement)
    function getWorkspaceDisplayText(workspaceNumber) {
        // If Japanese is enabled, use Japanese numbering
        if (WorkspaceLabelManager.useJapanese) {
            return WorkspaceLabelManager.toJapaneseNumber(workspaceNumber);
        }
        // Otherwise, always use regular numbers (ignore string replacement for overview)
        return workspaceNumber.toString();
    }

    // Add null safety checks for monitor and monitorData properties
    property real workspaceImplicitWidth: {
        if (!monitorData || !monitor)
            return 200; // fallback width
        return (monitorData.transform % 2 === 1) ? ((monitor.height - (monitorData.reserved?.[0] ?? 0) - (monitorData.reserved?.[2] ?? 0)) * root.scale / monitor.scale) / 1.265 : ((monitor.width - (monitorData.reserved?.[0] ?? 0) - (monitorData.reserved?.[2] ?? 0)) * root.scale / monitor.scale) / 1.5 * wsWidthMultiplier;
    }

    property real workspaceImplicitHeight: {
        if (!monitorData || !monitor)
            return 150; // fallback height
        return (monitorData.transform % 2 === 1) ? ((monitor.width - (monitorData.reserved?.[1] ?? 0) - (monitorData.reserved?.[3] ?? 0)) * root.scale / monitor.scale) / 1.27 : ((monitor.height - (monitorData.reserved?.[1] ?? 0) - (monitorData.reserved?.[3] ?? 0)) * root.scale / monitor.scale) / 1.27;
    }

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: Math.min(workspaceImplicitHeight, workspaceImplicitWidth) * (monitor?.scale ?? 1)
    property int workspaceZ: 0
    property int windowZ: 1
    property int windowDraggingZ: 99999
    property real workspaceSpacing: 5

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    property Component windowComponent: OverviewWindow {}
    property list<OverviewWindow> windowWidgets: []

    // Helper function to calculate workspace number based on arrangement mode
    // Helper function to calculate workspace number based on arrangement mode
    function getWorkspaceNumber(rowIndex, colIndex) {
        if (!root.expanded) {
            // In vertical mode: arrange column-first (top to bottom, then left to right)
            return root.workspaceGroup * workspacesShown + colIndex * rowsNumber + rowIndex + 1;
        } else {
            // In horizontal mode: arrange row-first (left to right, then top to bottom)
            return root.workspaceGroup * workspacesShown + rowIndex * columnsNumber + colIndex + 1;
        }
    }

    // Helper function to get row index from workspace ID
    function getRowIndexFromWorkspace(workspaceId) {
        const localId = (workspaceId - 1) % workspacesShown;
        if (!root.expanded) {
            // Column-first arrangement
            return localId % rowsNumber;
        } else {
            // Row-first arrangement
            return Math.floor(localId / columnsNumber);
        }
    }

    // Helper function to get column index from workspace ID
    function getColIndexFromWorkspace(workspaceId) {
        const localId = (workspaceId - 1) % workspacesShown;
        if (!root.expanded) {
            // Column-first arrangement
            return Math.floor(localId / rowsNumber);
        } else {
            // Row-first arrangement
            return localId % columnsNumber;
        }
    }

    ColumnLayout { // Workspaces
        id: workspaceColumnLayout
        // anchors.fill: parent
        z: root.workspaceZ
        anchors.centerIn: parent
        spacing: workspaceSpacing
        Repeater {
            model: root.rowsNumber
            delegate: RowLayout {
                id: row
                property int rowIndex: index
                spacing: workspaceSpacing

                Repeater {
                    // Workspace repeater
                    model: columnsNumber
                    Rectangle { // Workspace
                        id: workspace
                        property int colIndex: index
                        property int workspaceValue: root.getWorkspaceNumber(rowIndex, colIndex)
                        property color defaultWorkspaceColor: ColorUtils.transparentize(Colors.m3.m3secondaryContainer, 0.86) // TODO: reconsider this color for a cleaner look
                        property color hoveredWorkspaceColor: ColorUtils.mix(defaultWorkspaceColor, Colors.colLayer1Hover, 0.1)
                        property color hoveredBorderColor: Colors.colLayer2Hover
                        property bool hoveredWhileDragging: false

                        implicitWidth: root.workspaceImplicitWidth
                        implicitHeight: root.workspaceImplicitHeight
                        color: hoveredWhileDragging ? hoveredWorkspaceColor : defaultWorkspaceColor
                        radius: Rounding.verylarge
                        border.width: 2
                        border.color: hoveredWhileDragging ? hoveredBorderColor : "transparent"
                        StyledText {
                            anchors.centerIn: parent
                            text: WorkspaceLabelManager.getDisplayText(workspaceValue)

                            // Use WorkspaceLabelManager styling functions
                            property var textStyle: WorkspaceLabelManager.getTextStyle(WorkspaceLabelManager.currentMode, text)
                            font.family: WorkspaceLabelManager.useJapanese ? "Noto Sans CJK JP" : "Rubik"
                            font.weight: WorkspaceLabelManager.useJapanese ? Font.Light : Font.DemiBold
                            font.pixelSize: root.workspaceNumberSize * root.scale
                            color: ColorUtils.transparentize(Colors.colOnLayer1, 0.8)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: workspaceArea
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                if (root.draggingTargetWorkspace === -1) {
                                    // Noon.exec(` qs ipc call overview close`)
                                    Hyprland.dispatch(`workspace ${workspaceValue}`);
                                }
                            }
                        }

                        DropArea {
                            anchors.fill: parent
                            onEntered: {
                                root.draggingTargetWorkspace = workspaceValue;
                                if (root.draggingFromWorkspace == root.draggingTargetWorkspace)
                                    return;
                                hoveredWhileDragging = true;
                            }
                            onExited: {
                                hoveredWhileDragging = false;
                                if (root.draggingTargetWorkspace == workspaceValue)
                                    root.draggingTargetWorkspace = -1;
                            }
                        }
                    }
                }
            }
        }
    }

    Item { // Windows & focused workspace indicator
        id: windowSpace
        anchors.centerIn: parent
        implicitWidth: workspaceColumnLayout.implicitWidth
        implicitHeight: workspaceColumnLayout.implicitHeight
        clip: true
        Repeater {
            // Window repeater
            model: ScriptModel {
                values: {
                    // console.log(JSON.stringify(ToplevelManager.toplevels.values.map(t => t), null, 2))
                    return ToplevelManager?.toplevels.values.filter(toplevel => {
                        const address = `0x${toplevel.HyprlandToplevel.address}`;
                        // console.log(`Checking window with address: ${address}`)
                        var win = windowByAddress[address];
                        return win && win.workspace && (root.workspaceGroup * root.workspacesShown < win.workspace.id && win.workspace.id <= (root.workspaceGroup + 1) * root.workspacesShown);
                    });
                }
            }
            delegate: OverviewWindow {
                id: window
                required property var modelData
                property var address: `0x${modelData.HyprlandToplevel.address}`
                windowData: windowByAddress[address]
                toplevel: modelData
                monitorData: root.monitorData
                scale: root.scale - root.windowOffset
                availableWorkspaceWidth: root.workspaceImplicitWidth
                availableWorkspaceHeight: root.workspaceImplicitHeight

                property bool atInitPosition: (initX == x && initY == y)
                restrictToWorkspace: Drag.active || atInitPosition

                // Fixed workspace calculations using helper functions
                property int workspaceColIndex: (windowData?.workspace?.id !== undefined) ? root.getColIndexFromWorkspace(windowData.workspace.id) : 0
                property int workspaceRowIndex: (windowData?.workspace?.id !== undefined) ? root.getRowIndexFromWorkspace(windowData.workspace.id) : 0

                xOffset: (root.workspaceImplicitWidth + workspaceSpacing) * workspaceColIndex

                yOffset: (root.workspaceImplicitHeight + workspaceSpacing) * workspaceRowIndex

                Timer {
                    id: updateWindowPosition
                    interval: Mem.options.hacks.arbitraryRaceConditionDelay
                    repeat: false
                    running: false
                    onTriggered: {
                        // Add comprehensive null checks
                        if (windowData?.at && monitorData?.reserved && windowData.at.length >= 2 && monitorData.reserved.length >= 4) {
                            window.x = Math.round(Math.max((windowData?.at[0] - (monitor?.x ?? 0) - monitorData?.reserved[0]) * root.scale, 0) + xOffset);
                            window.y = Math.round(Math.max((windowData?.at[1] - (monitor?.y ?? 0) - monitorData?.reserved[1]) * root.scale, 0) + yOffset);
                        }
                    }
                }

                z: atInitPosition ? root.windowZ : root.windowDraggingZ
                Drag.hotSpot.x: targetWindowWidth / 2
                Drag.hotSpot.y: targetWindowHeight / 2
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: hovered = true // For hover color change
                    onExited: hovered = false // For hover color change
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    drag.target: parent
                    onPressed: mouse => {
                        root.draggingFromWorkspace = windowData?.workspace.id;

                        window.pressed = true;

                        window.Drag.active = true;

                        window.Drag.source = window;

                        window.Drag.hotSpot.x = mouse.x;

                        window.Drag.hotSpot.y = mouse.y;
                    }
                    onReleased: {
                        const targetWorkspace = root.draggingTargetWorkspace;
                        window.pressed = false;
                        window.Drag.active = false;
                        root.draggingFromWorkspace = -1;
                        if (targetWorkspace !== -1 && windowData?.workspace?.id !== undefined && targetWorkspace !== windowData.workspace.id) {
                            Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${window.windowData.address}`);
                            updateWindowPosition.restart();
                        } else {
                            window.x = window.initX;
                            window.y = window.initY;
                        }
                    }
                    onClicked: event => {
                        if (!windowData)
                            return;

                        if (event.button === Qt.LeftButton) {
                            Hyprland.dispatch(`focuswindow address:${windowData.address}`);
                            event.accepted = true;
                        } else if (event.button === Qt.MiddleButton) {
                            Hyprland.dispatch(`closewindow address:${windowData.address}`);
                            event.accepted = true;
                        }
                    }

                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: dragArea.containsMouse && !window.Drag.active
                        content: windowData ? `${windowData.title ?? ""}\n[${windowData.class ?? ""}] ${windowData.xwayland ? "[XWayland] " : ""}\n` : ""
                    }
                }
            }
        }

        Rectangle { // Focused workspace indicator
            id: focusedWorkspaceIndicator
            // Fixed active workspace calculations using helper functions
            property int activeWorkspaceInGroup: (monitor?.activeWorkspace?.id !== undefined) ? monitor.activeWorkspace.id - (root.workspaceGroup * root.workspacesShown) : 1
            property int activeWorkspaceRowIndex: (monitor?.activeWorkspace?.id !== undefined) ? root.getRowIndexFromWorkspace(monitor.activeWorkspace.id) : 0
            property int activeWorkspaceColIndex: (monitor?.activeWorkspace?.id !== undefined) ? root.getColIndexFromWorkspace(monitor.activeWorkspace.id) : 0
            x: (root.workspaceImplicitWidth + workspaceSpacing) * activeWorkspaceColIndex
            y: (root.workspaceImplicitHeight + workspaceSpacing) * activeWorkspaceRowIndex
            z: root.windowZ
            width: root.workspaceImplicitWidth
            height: root.workspaceImplicitHeight
            color: "transparent"
            radius: Rounding.verylarge
            border.width: 2
            border.color: root.activeBorderColor
            Behavior on x {
                FAnim {}
            }
            Behavior on y {
                FAnim {}
            }
        }
    }
}
