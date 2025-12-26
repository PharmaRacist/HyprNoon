import QtQuick
import Quickshell
import qs.modules.common.utils
pragma Singleton

Singleton {
    id: root

    property bool isBusy: mainProc.running

    signal screenshotCompleted()

    function takeScreenShot() {
        if (!isBusy)
            mainProc.running = true;

    }

    Process {
        id: mainProc

        command: ["hyprshot", "--freeze", "--clipboard-only", "--mode", "region", "--silent"]
        onExited: (exitCode) => {
            if (exitCode === 0)
                root.screenshotCompleted();

        }
    }

}
