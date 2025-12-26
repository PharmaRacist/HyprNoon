import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    property int currentLevel: 0
    property string deviceName: ""
    property bool deviceFound: false

    function parseBrightness(output) {
        const trimmed = output.trim();
        const match = trimmed.match(/Current brightness:\s*(\d+)/);
        if (match && match[1]) {
            const val = parseInt(match[1]);
            return isNaN(val) ? 0 : val;
        }
        const num = parseInt(trimmed);
        return isNaN(num) ? 0 : num;
    }

    function initializeDevice() {
        const storedDevice = Mem.options.services.backlightDevice;
        if (storedDevice && storedDevice.length > 1) {
            deviceName = storedDevice;
            deviceFound = true;
            getProc.running = true;
        } else {
            listProc.running = true;
        }
    }

    showButtonName: false
    toggled: currentLevel > 0
    buttonIcon: {
        switch (currentLevel) {
        case 0:
            return "backlight_high_off";
        case 1:
            return "backlight_low";
        case 2:
            return "backlight_high";
        default:
            return "backlight_low";
        }
    }
    onDeviceFoundChanged: {
        if (parent)
            parent.visible = deviceFound;

    }
    Component.onCompleted: initializeDevice()
    onClicked: {
        if (!deviceFound)
            return ;

        const nextLevel = (currentLevel + 1) % 3;
        setProc.command = ["brightnessctl", "-d", deviceName, "set", nextLevel.toString()];
        setProc.running = true;
    }

    Process {
        id: listProc

        property string accumulatedOutput: ""

        command: ["brightnessctl", "--list"]
        onRunningChanged: {
            if (!running && accumulatedOutput) {
                const match = accumulatedOutput.match(/Device '([^']+)' of class 'leds':/);
                if (match && match[1] && match[1].includes("kbd")) {
                    deviceName = match[1];
                    deviceFound = true;
                    const storedDevice = Mem.options.services.backlightDevice;
                    if (!storedDevice || storedDevice.length <= 1)
                        Mem.options.services.backlightDevice = deviceName;

                    getProc.running = true;
                } else {
                    deviceFound = false;
                }
                accumulatedOutput = "";
            }
        }

        stdout: SplitParser {
            onRead: (data) => {
                return listProc.accumulatedOutput += data.toString();
            }
        }

    }

    Process {
        id: getProc

        command: deviceName ? ["brightnessctl", "-d", deviceName, "get"] : []

        stdout: SplitParser {
            onRead: (data) => {
                return currentLevel = parseBrightness(data.toString().trim());
            }
        }

    }

    Process {
        id: setProc

        property string accumulatedOutput: ""

        command: []
        onRunningChanged: {
            if (!running && accumulatedOutput) {
                currentLevel = parseBrightness(accumulatedOutput);
                accumulatedOutput = "";
            }
        }

        stdout: SplitParser {
            onRead: (data) => {
                return setProc.accumulatedOutput += data.toString();
            }
        }

    }

}
