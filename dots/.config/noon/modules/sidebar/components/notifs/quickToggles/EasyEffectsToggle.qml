import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    id: root

    toggled: Mem.options.services.easyEffects
    buttonName: ""
    buttonIcon: "graphic_eq"
    onClicked: {
        if (toggled) {
            toggled = !toggled;
            Noon.exec("pkill", "easyeffects");
        } else {
            toggled = !toggled;
            Noon.exec("easyeffects", "--gapplication-service");
        }
    }

    Process {
        id: fetchAvailability

        running: true
        command: ["bash", "-c", "command -v easyeffects"]
        onExited: (exitCode, exitStatus) => {
            root.visible = exitCode === 0;
        }
    }

    Process {
        id: fetchActiveState

        running: true
        command: ["pidof", "easyeffects"]
        onExited: (exitCode, exitStatus) => {
            root.toggled = exitCode === 0;
        }
    }

}
