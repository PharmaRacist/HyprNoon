import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
pragma Singleton
/* 
    Power Service for tlp , powerprofiles-daemon (non-native) , auto-cpufreq 
*/
Singleton {
    id: root

    property string icon: "eco"
    property string modeName: "Power Saver"
    property string controller: Mem.states.services?.power?.controller || ""
    property var modes: Mem.states.services?.power?.modes || []
    property string currentMode: Mem.states.services?.power?.mode || "power-saver"

    function cycleMode() {
        if (!controller || modes.length === 0)
            return;

        const currentIndex = modes.indexOf(currentMode);
        const nextIndex = (currentIndex + 1) % modes.length;
        const newMode = modes[nextIndex];
        
        const cmd = ["bash", "-c", `${Directories.scriptsDir}/power_service.sh set ${newMode}`];
        Noon.execDetached(cmd);
    }

    function getModeDisplayName(mode) {
        switch (mode) {
        case "bat":
        case "power-saver":
            return "Power Saver";
        case "balanced":
            return "Balanced";
        case "ac":
        case "performance":
            return "Performance";
        default:
            return mode;
        }
    }

    function getModeIcon(mode) {
        switch (mode) {
        case "bat":
        case "power-saver":
            return "eco";
        case "balanced":
            return "balance";
        case "ac":
        case "performance":
            return "bolt";
        default:
            return "eco";
        }
    }

    onCurrentModeChanged: {
        modeName = getModeDisplayName(currentMode);
        icon = getModeIcon(currentMode);
    }
}
