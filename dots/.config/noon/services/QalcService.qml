import QtQuick
import Quickshell
import qs.modules.common.utils
pragma Singleton

Singleton {
    id: root

    property string result: ""
    property bool isBusy: calcProcess.running

    function calculate(expression: string) {
        if (!expression) {
            root.result = "";
            return ;
        }
        calcProcess.running = false;
        calcProcess.command = ["qalc", "-terse", expression];
        calcProcess.running = true;
    }

    Process {
        id: calcProcess

        command: ["qalc", "-terse"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.result = "Error: " + exitCode;

        }

        stdout: SplitParser {
            onRead: (data) => {
                return root.result = data.trim();
            }
        }

    }

}
