import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils
pragma Singleton

Singleton {
    property var stats: ({
        "cpu_percent": 0,
        "cpu_freq_ghz": 0,
        "cpu_temp": 0,
        "mem_total": 1,
        "mem_available": 1,
        "swap_total": 1,
        "swap_free": 1,
        "gpus": []
    })

    Process {
        id: systemProbe

        running: true
        command: ["python3", Directories.scriptsDir + "/resources_service.py"]

        stdout: SplitParser {
            onRead: (data) => {
                try {
                    stats = JSON.parse(data.toString());
                } catch (e) {
                    console.error("Failed to parse system stats:", e);
                }
            }
        }

    }

}
