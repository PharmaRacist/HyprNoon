pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.utils
/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})
    property real hyprlandGapsOut: 0
    property string hyprlandLayout: Mem.options.desktop.hyprland.tilingLayout
    property string externalTrackedHyprlandLayout: "dwindle"
    readonly property bool isHyprland: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""

    // ===== Keyboard layout =====
    property string keyboardName: ""
    property string currentKeyboardLayout: ""
        property var keyboardLayoutShortNames: Mem.options.bar.keyboard?.keyboardLayoutShortNames ?? ({
            "English (US)": "US",
            "Arabic": "AR"
    })
    readonly property string keyboardLayoutShortName: keyboardLayoutShortNames[currentKeyboardLayout]
                                                      ?? currentKeyboardLayout.substring(0, 2).toUpperCase()

    onHyprlandLayoutChanged: Qt.callLater(() => Noon.setHyprKey("general:layout", hyprlandLayout))

    function updateWindowList() {
        getClients.running = true;
    }

    function updateLayers() {
        getLayers.running = true;
    }

    function updateMonitors() {
        getMonitors.running = true;
    }

    function updateHyprlandGapsOut() {
        getHyprlandGapsOut.running = true;
    }

    function updateHyprlandLayout() {
        getHyprlandLayout.running = true;
    }

    function updateWorkspaces() {
        getWorkspaces.running = true;
        getActiveWorkspace.running = true;
    }

    function updateKeyboardLayout() {
        getKeyboardLayout.running = true;
    }

    function updateAll() {
        updateWindowList();
        updateMonitors();
        updateLayers();
        updateWorkspaces();
        updateHyprlandLayout();
        updateHyprlandGapsOut();
        updateKeyboardLayout();
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandService.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }
    function switchKeyboardLayout() {
        Noon.exec("hyprctl switchxkblayout current next");
    }
    Component.onCompleted: updateAll()

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            // Keyboard layout change: activelayout name,data
            if (event.name === "activelayout") {
                const parts = event.data.split(",");
                if (parts.length >= 2) {
                    root.keyboardName = parts[0];
                    root.currentKeyboardLayout = parts.slice(1).join(",");
                }
                return;
            }
            updateAll();
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                root.windowList = JSON.parse(clientsCollector.text);
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                root.monitors = JSON.parse(monitorsCollector.text);
            }
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: {
                root.layers = JSON.parse(layersCollector.text);
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                root.workspaces = JSON.parse(workspacesCollector.text);
                let tempWorkspaceById = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    tempWorkspaceById[ws.id] = ws;
                }
                root.workspaceById = tempWorkspaceById;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }

    Process {
        id: getHyprlandGapsOut
        command: ["hyprctl", "getoption", "general:gaps_out", "-j"]
        stdout: StdioCollector {
            id: gapsOutCollector
            onStreamFinished: {
                const json = JSON.parse(gapsOutCollector.text);
                const firstGap = json.custom.split(" ")[0];
                root.hyprlandGapsOut = parseInt(firstGap);
            }
        }
    }

    Process {
        id: getHyprlandLayout
        command: ["hyprctl", "getoption", "general:layout", "-j"]
        stdout: StdioCollector {
            id: layoutCollector
            onStreamFinished: {
                const json = JSON.parse(layoutCollector.text);
                root.externalTrackedHyprlandLayout = json.str;
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
            }
        }
    }

    Process {
        id: getKeyboardLayout
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            id: keyboardCollector
            onStreamFinished: {
                const devices = JSON.parse(keyboardCollector.text);
                const keyboards = devices.keyboards ?? [];
                const mainKeyboard = keyboards.find(kb => kb.main) ?? keyboards[0];
                if (mainKeyboard) {
                    root.keyboardName = mainKeyboard.name ?? "";
                    root.currentKeyboardLayout = mainKeyboard.active_keymap ?? "";
                }
            }
        }
    }
}
