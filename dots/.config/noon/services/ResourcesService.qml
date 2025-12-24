pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    // --- Memory ---
    property double memoryTotal: 1
    property double memoryFree: 1
    property double memoryUsed: memoryTotal - memoryFree
    property double memoryUsedPercentage: memoryUsed / memoryTotal

    // --- Swap ---
    property double swapTotal: 1
    property double swapFree: 1
    property double swapUsed: swapTotal - swapFree
    property double swapUsedPercentage: swapUsed / swapTotal

    // --- CPU ---
    property double cpuUsage: 0
    property double cpuUsagePercentage: cpuUsage * 100
    property var previousCpuStats
    property double avgCpuTemp: 0
    property double cpuClockGHz: 0

    // --- GPU ---
    property string gpuVendor: "unknown" // "nvidia", "amd", "intel"
    property double gpuUsage: 0
    property double gpuTemp: 0
    property double gpuClockMHz: 0
    Component.onCompleted: {
        // Immediately populate CPU/GPU/memory values
        fileMeminfo.reload();
        fileStat.reload();
        readTemp.running = true;
        readCpuClock.running = true;
        detectGpuVendor.running = true;
    }
    onGpuVendorChanged: {
        if (gpuVendor !== "unknown") {
            gpuProbe.running = true;
        }
    }

    Timer {
        id: poller
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            fileMeminfo.reload();
            fileStat.reload();
            readTemp.running = true;
            readCpuClock.running = true;
            if (gpuVendor === "unknown")
                detectGpuVendor.running = true;
            else
                gpuProbe.running = true;

            // --- Memory ---
            const textMeminfo = fileMeminfo.text();
            memoryTotal = Number(textMeminfo.match(/MemTotal:\s+(\d+)/)?.[1] ?? 1);
            memoryFree = Number(textMeminfo.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
            swapTotal = Number(textMeminfo.match(/SwapTotal:\s+(\d+)/)?.[1] ?? 1);
            swapFree = Number(textMeminfo.match(/SwapFree:\s+(\d+)/)?.[1] ?? 0);

            // --- CPU Usage ---
            const textStat = fileStat.text();
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number);
                const total = stats.reduce((a, b) => a + b, 0);
                const idle = stats[3];
                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total;
                    const idleDiff = idle - previousCpuStats.idle;
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;
                }
                previousCpuStats = {
                    total,
                    idle
                };
            }
        }
    }

    // --- CPU Temp ---
    Process {
        id: readTemp
        command: ["bash", "-c", "sensors | awk '/Core [0-9]+:/ {gsub(/\\+|°C/,\"\",$3); sum+=$3; n++} END {if(n) printf \"%.1f\", sum/n}'"]
        stdout: SplitParser {
            onRead: data => {
                const val = parseFloat(data.toString().trim());
                if (!isNaN(val))
                    avgCpuTemp = val / 100;
            }
        }
    }

    // --- CPU Clock GHz ---
    Process {
        id: readCpuClock
        command: ["bash", "-c", "awk '/cpu MHz/ {sum+=$4; n++} END {if(n) printf \"%.2f\", sum/n/1000}' /proc/cpuinfo"]
        stdout: SplitParser {
            onRead: data => {
                const val = parseFloat(data.toString().trim());
                if (!isNaN(val))
                    cpuClockGHz = val;
            }
        }
    }

    // --- GPU Vendor Detection ---
    // --- GPU Vendor Detection ---
    Process {
        id: detectGpuVendor
        command: ["bash", "-c", `
        nvidia_installed=$(command -v nvidia-smi >/dev/null 2>&1 && echo 1 || echo 0)
        intel_present=$(lspci | grep -i 'intel.*vga\|intel.*3d' | wc -l)
        amd_present=$(lspci | grep -i 'amd\|advanced micro' | wc -l)

        if [ "$nvidia_installed" -eq 1 ]; then
            echo "nvidia"
        elif [ "$amd_present" -gt 0 ]; then
            echo "amd"
        elif [ "$intel_present" -gt 0 ]; then
            echo "intel"
        else
            echo "unknown"
        fi
    `]
        stdout: SplitParser {
            onRead: data => {
                gpuVendor = data.toString().trim().toLowerCase();
            }
        }
    }

    // --- GPU Probe ---
    Process {
        id: gpuProbe
        command: ["bash", "-c", `
            case "$GPU" in
                nvidia)
                    nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,clocks.gr --format=csv,noheader,nounits 2>/dev/null
                    ;;
                amd)
                    cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null
                    echo $(cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null)
                    echo $(cat /sys/class/drm/card0/device/pp_dpm_sclk | grep '*' | awk '{print $2}' 2>/dev/null)
                    ;;
                intel)
                    intel_gpu_top -J -s 1000 | head -n 20 | jq -r '.engines[].busy' | awk '{sum+=$1;n++}END{if(n)print sum/n}'
                    ;;
                *)
                    ;;
            esac
        `]
        environment: [`GPU=${gpuVendor}`]
        stdout: SplitParser {
            onRead: data => {
                const lines = data.toString().trim().split(/\s+|,/);
                if (gpuVendor === "nvidia" && lines.length >= 3) {
                    gpuUsage = parseFloat(lines[0]) / 100.0;
                    gpuTemp = parseFloat(lines[1]) / 100.0;
                    gpuClockMHz = parseFloat(lines[2]);
                } else if (gpuVendor === "amd") {
                    if (lines.length >= 3) {
                        gpuUsage = parseFloat(lines[0]) / 100.0;
                        gpuTemp = parseFloat(lines[1]) / 100000.0; // m°C → °C/100
                        gpuClockMHz = parseFloat(lines[2]);
                    }
                } else if (gpuVendor === "intel") {
                    gpuUsage = parseFloat(lines[0]) / 100.0;
                    gpuTemp = 0;
                    gpuClockMHz = 0;
                }
            }
        }
    }

    FileView {
        id: fileMeminfo
        path: "/proc/meminfo"
    }
    FileView {
        id: fileStat
        path: "/proc/stat"
    }
}
