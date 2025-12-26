pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    property string icon: "eco"
    property string modeName: "Power Saver"
    property string controller: Mem.states.services?.power?.controller || ""
    property var modes: Mem.states.services?.power?.modes || []
    property string currentMode: Mem.states.services?.power?.mode || "power-saver"

    function cycleMode(reverse) { 
        if (!controller || !modes.length)
            return
        
        const currentIndex = modes.indexOf(currentMode)
        const next = modes[(currentIndex + 1) % modes.length]
        const previous = modes[(currentIndex - 1 + modes.length) % modes.length]
        const mode = reverse ? previous : next
        
        Noon.exec(`${Directories.scriptsDir}/power_service.sh set ${mode}`)
    }

    function getModeDisplayName(mode) {
        return { "bat": "Power Saver", "power-saver": "Power Saver", "balanced": "Balanced", "ac": "Performance", "performance": "Performance" }[mode] || mode
    }

    function getModeIcon(mode) {
        return { "bat": "eco", "power-saver": "eco", "balanced": "balance", "ac": "bolt", "performance": "bolt" }[mode] || "eco"
    }

    onCurrentModeChanged: {
        modeName = getModeDisplayName(currentMode)
        icon = getModeIcon(currentMode)
    }
}
