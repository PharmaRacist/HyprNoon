import QtQuick
import Quickshell

Item {
    id: networkModule

    property real uploadSpeed: 0
    property real downloadSpeed: 0
    property string networkInterface: "enp34s0"
    property int previousRxBytes: 0
    property int previousTxBytes: 0
    property int previousTime: 0

    function calculateSpeed() {
        if (!rxFile.content || !txFile.content) {
            console.log("Missing file content");
            return ;
        }
        const currentRxBytes = parseInt(rxFile.content.trim());
        const currentTxBytes = parseInt(txFile.content.trim());
        const currentTime = Date.now();
        console.log("Current RX:", currentRxBytes, "Current TX:", currentTxBytes);
        if (previousTime > 0 && previousRxBytes > 0 && previousTxBytes > 0) {
            const timeDiff = (currentTime - previousTime) / 1000;
            if (timeDiff > 0) {
                const rxDiff = currentRxBytes - previousRxBytes;
                const txDiff = currentTxBytes - previousTxBytes;
                console.log("Time diff:", timeDiff, "RX diff:", rxDiff, "TX diff:", txDiff);
                if (rxDiff >= 0 && txDiff >= 0) {
                    downloadSpeed = rxDiff / timeDiff;
                    uploadSpeed = txDiff / timeDiff;
                    console.log("Calculated speeds - Down:", downloadSpeed, "Up:", uploadSpeed);
                }
            }
        }
        // Update previous values
        previousRxBytes = currentRxBytes;
        previousTxBytes = currentTxBytes;
        previousTime = currentTime;
    }

    function formatSpeed(bytesPerSecond) {
        if (bytesPerSecond < 1024)
            return Math.round(bytesPerSecond) + "B/s";
        else if (bytesPerSecond < 1024 * 1024)
            return (bytesPerSecond / 1024).toFixed(1) + "K/s";
        else if (bytesPerSecond < 1024 * 1024 * 1024)
            return (bytesPerSecond / (1024 * 1024)).toFixed(1) + "M/s";
        else
            return (bytesPerSecond / (1024 * 1024 * 1024)).toFixed(1) + "G/s";
    }

    width: networkText.width + 20
    height: 24

    // Read RX bytes
    FileView {
        // onContentChanged: {
        //     console.log("RX file changed:", content);
        //     calculateSpeed();
        // }

        id: rxFile

        path: "/sys/class/net/" + networkInterface + "/statistics/rx_bytes"
    }

    // Read TX bytes
    FileView {
        // onContentChanged: {
        //     console.log("TX file changed:", content);
        //     calculateSpeed();
        // }

        id: txFile

        path: "/sys/class/net/" + networkInterface + "/statistics/tx_bytes"
    }

    // Force refresh every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            console.log("Timer tick - forcing file refresh");
            rxFile.active = false;
            txFile.active = false;
            rxFile.active = true;
            txFile.active = true;
        }
    }

    StyledText {
        id: networkText

        anchors.centerIn: parent
        text: "↑" + formatSpeed(uploadSpeed) + " ↓" + formatSpeed(downloadSpeed)
        color: (uploadSpeed > 0 || downloadSpeed > 0) ? "#4ecdc4" : "#95a5a6"
        font.family: "monospace"
        font.pixelSize: 12
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Reset stats on click
            previousRxBytes = 0;
            previousTxBytes = 0;
            previousTime = 0;
            uploadSpeed = 0;
            downloadSpeed = 0;
        }
    }

}
