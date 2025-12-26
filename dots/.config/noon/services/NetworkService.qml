import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils
pragma Singleton

Singleton {
    property var stats: ({
        "wifi_enabled": false,
        "ethernet": false,
        "wifi": false,
        "wifi_status": "disconnected",
        "network_name": "",
        "signal_strength": 0,
        "signal_strength_text": "0%",
        "material_icon": "signal_wifi_bad",
        "wifi_networks": [],
        "download_speed": 0,
        "upload_speed": 0,
        "download_speed_text": "0 B/s",
        "upload_speed_text": "0 B/s"
    })
    // Convenience properties for direct access
    property bool wifiEnabled: stats.wifi_enabled
    property bool ethernet: stats.ethernet
    property bool wifi: stats.wifi
    property string wifiStatus: stats.wifi_status
    property string networkName: stats.network_name
    property int networkStrength: stats.signal_strength
    property string networkStrengthText: stats.signal_strength_text
    property string materialSymbol: stats.material_icon
    property real downloadSpeed: stats.download_speed
    property real uploadSpeed: stats.upload_speed
    property string downloadSpeedText: stats.download_speed_text
    property string uploadSpeedText: stats.upload_speed_text
    readonly property var wifiNetworks: stats.wifi_networks
    readonly property var active: wifiNetworks.find((n) => {
        return n.active;
    }) ?? null

    // Send command to Python daemon via stdin
    function sendCommand(cmd) {
        networkMonitor.write(JSON.stringify(cmd) + "\n");
    }

    // Control functions
    function enableWifi(enabled) {
        sendCommand({
            "action": "enable_wifi",
            "enabled": enabled
        });
    }

    function toggleWifi() {
        sendCommand({
            "action": "toggle_wifi"
        });
    }

    function rescanWifi() {
        sendCommand({
            "action": "rescan_wifi"
        });
    }

    function connectToWifiNetwork(ssid, password) {
        sendCommand({
            "action": "connect",
            "ssid": ssid,
            "password": password || ""
        });
    }

    function disconnectWifiNetwork() {
        if (active && active.ssid)
            sendCommand({
                "action": "disconnect",
                "ssid": active.ssid
            });

    }

    function forgetWifiNetwork(ssid) {
        sendCommand({
            "action": "forget",
            "ssid": ssid
        });
    }

    Process {
        id: networkMonitor

        running: true
        command: ["python3", Directories.scriptsDir + "/network_service.py"]
        onExited: (exitCode, exitStatus) => {
            console.error("Network service exited with code:", exitCode);
            restartTimer.running = true;
        }

        stdout: SplitParser {
            onRead: (data) => {
                try {
                    const result = JSON.parse(data.toString());
                    // Skip startup message
                    if (result.status === "started") {
                        console.log("Network service started");
                        return ;
                    }
                    // Log errors but don't update stats
                    if (result.error) {
                        console.error("Network service error:", result.error);
                        return ;
                    }
                    // Update stats with valid data
                    stats = result;
                } catch (e) {
                    console.error("Failed to parse network stats:", e);
                }
            }
        }

        stderr: SplitParser {
            onRead: (data) => {
                console.error("Network service stderr:", data.toString());
            }
        }

    }

    Timer {
        id: restartTimer

        interval: 2000
        onTriggered: {
            console.log("Restarting network service...");
            networkMonitor.running = true;
        }
    }

}
