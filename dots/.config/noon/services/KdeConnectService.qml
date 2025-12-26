pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import qs.modules.common
import qs.modules.common.utils
import QtQuick

Singleton {
    id: root

    property var devices: []
    property var availableDevices: []
    property string selectedDeviceId: ""
    property bool isRefreshing: false
    property bool daemonRunning: false

    signal devicesUpdated
    signal devicePaired(string deviceId, string deviceName)
    signal deviceUnpaired(string deviceId)
    signal error(string message)

    FilePicker {
        id: filePicker
        title: "Select file to share via KDE Connect"
        multipleSelection: true
        fileFilters: [filePicker.filterPresets.ALL, filePicker.filterPresets.IMAGES, 
                     filePicker.filterPresets.DOCUMENTS, filePicker.filterPresets.VIDEOS, 
                     filePicker.filterPresets.AUDIO]

        onFileSelected: files => {
            if (!selectedDeviceId) {
                error("No device selected");
                return;
            }

            const fileArray = Array.isArray(files) ? files : [files];
            fileArray.forEach(file => executeCommand(["--device", selectedDeviceId, "--share", file]));
        }

        onError: message => error(message)
    }

    function saveToConfig() {
        if (!Mem.states.services) Mem.states.services = {};
        if (!Mem.states.services.kdeconnect) Mem.states.services.kdeconnect = {};
        Mem.states.services.kdeconnect.selectedDeviceId = selectedDeviceId;
    }

    function loadFromConfig() {
        const saved = Mem.states.services?.kdeconnect?.selectedDeviceId;
        if (saved) selectedDeviceId = saved;
    }

    function executeCommand(args, onSuccess, onError) {
        const proc = processComponent.createObject(root, {
            commandArgs: args,
            successCallback: onSuccess,
            errorCallback: onError
        });
        proc.running = true;
    }

    function parseDeviceList(output) {
        if (!output?.trim()) return [];

        return output.split('\n')
            .filter(line => line.trim())
            .map(line => {
                const spaceIndex = line.indexOf(' ');
                return spaceIndex === -1 
                    ? { id: line, name: line }
                    : { id: line.substring(0, spaceIndex), name: line.substring(spaceIndex + 1).trim() };
            });
    }

    function checkDaemon() {
        executeCommand(["--list-devices"], 
            () => daemonRunning = true,
            () => daemonRunning = false
        );
    }

    function listAllDevices() {
        executeCommand(["--list-devices", "--id-name-only"], output => {
            devices = parseDeviceList(output);
            devicesUpdated();
        });
    }

    function listAvailableDevices() {
        if (isRefreshing) return;

        isRefreshing = true;
        executeCommand(["--list-available", "--id-name-only"], 
            output => {
                isRefreshing = false;
                availableDevices = parseDeviceList(output);
                devicesUpdated();
            },
            () => isRefreshing = false
        );
    }

    function refresh() {
        if (isRefreshing) return;
        
        checkDaemon();
        executeCommand(["--refresh"], () => {
            listAllDevices();
            listAvailableDevices();
        });
    }

    function pairDevice(deviceId) {
        if (!deviceId) {
            error("Device ID is required");
            return;
        }
        executeCommand(["--device", deviceId, "--pair"], () => {
            devicePaired(deviceId, getDeviceName(deviceId));
            refresh();
        });
    }

    function unpairDevice(deviceId) {
        if (!deviceId) {
            error("Device ID is required");
            return;
        }
        executeCommand(["--device", deviceId, "--unpair"], () => {
            deviceUnpaired(deviceId);
            refresh();
        });
    }

    function ringDevice(deviceId = selectedDeviceId) {
        if (!deviceId) {
            error("No device selected");
            return;
        }
        executeCommand(["--device", deviceId, "--ring"]);
    }

    function pingDevice(message = "", deviceId = selectedDeviceId) {
        if (!deviceId) {
            error("No device selected");
            return;
        }

        const args = ["--device", deviceId, message ? "--ping-msg" : "--ping"];
        if (message) args.push(message);
        executeCommand(args);
    }

    function shareFile(path = "", deviceId = selectedDeviceId) {
        if (!deviceId) {
            error("No device selected");
            return;
        }

        if (!path) {
            filePicker.open();
        } else {
            executeCommand(["--device", deviceId, "--share", path]);
            Noon.notify("Sharing..");
        }
    }

    function shareText(text, deviceId = selectedDeviceId) {
        if (!deviceId || !text) {
            error("Device ID and text required");
            return;
        }
        executeCommand(["--device", deviceId, "--share-text", text]);
    }

    function sendClipboard(deviceId = selectedDeviceId) {
        if (!deviceId) {
            error("No device selected");
            return;
        }
        executeCommand(["--device", deviceId, "--send-clipboard"]);
    }

    function lockDevice(deviceId = selectedDeviceId) {
        if (!deviceId) {
            error("No device selected");
            return;
        }
        executeCommand(["--device", deviceId, "--lock"]);
    }

    function sendSMS(phoneNumber, message, attachments = [], deviceId = selectedDeviceId) {
        if (!deviceId || !phoneNumber || !message) {
            error("Device ID, phone number, and message required");
            return;
        }

        const args = ["--device", deviceId, "--send-sms", message, "--destination", phoneNumber];
        attachments.forEach(attachment => {
            args.push("--attachment", attachment);
        });

        executeCommand(args);
    }

    function getEncryptionInfo(deviceId = selectedDeviceId) {
        if (!deviceId) {
            error("No device selected");
            return;
        }
        executeCommand(["--device", deviceId, "--encryption-info"]);
    }

    function getDeviceName(deviceId) {
        const device = availableDevices.find(d => d.id === deviceId) 
                    || devices.find(d => d.id === deviceId);
        return device?.name || deviceId;
    }

    function getFirstAvailableDevice() {
        return availableDevices[0] || null;
    }

    function isDeviceAvailable(deviceId) {
        return availableDevices.some(d => d.id === deviceId);
    }

    function selectDevice(deviceId) {
        selectedDeviceId = deviceId;
        saveToConfig();
    }

    function togglePower(deviceId = selectedDeviceId) {
        if (!deviceId) {
            error("No device selected");
            return;
        }
        executeCommand(["--device", deviceId, "--toggle-connectivity"]);
    }

    Component.onCompleted: {
        loadFromConfig();
        checkDaemon();
        refresh();
    }

    Component {
        id: processComponent

        Process {
            property var commandArgs: []
            property var successCallback: null
            property var errorCallback: null
            property string outputBuffer: ""
            property string errorBuffer: ""

            command: ["kdeconnect-cli"].concat(commandArgs)
            running: false

            stdout: SplitParser {
                onRead: line => outputBuffer += line + "\n"
            }

            stderr: SplitParser {
                onRead: line => errorBuffer += line + "\n"
            }

            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0 && successCallback) {
                    successCallback(outputBuffer.trim());
                } else if (exitCode !== 0) {
                    const err = errorBuffer.trim();
                    if (errorCallback) errorCallback(err);
                    if (err) error(err);
                }
            }
        }
    }
}
