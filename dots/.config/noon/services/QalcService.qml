pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id:root    
    property string result: ""
    property string lastQuery: ""
    property bool isBusy: false
    
    Process {
        id: calcProcess
        command: ["qalc", "-terse"]
        
        stdout: SplitParser {
            onRead: (data) => {
                root.result = data.trim()
                root.isBusy = false
            }
        }
        
        onStarted: (pid) => {
            root.isBusy = true
        }
        
        onExited: (exitCode, exitStatus) => {
            root.isBusy = false
            if (exitCode !== 0) {
                root.result = "Error: " + exitCode
            }
        }
    }
    
    function calculate(expression: string) {
        if (!expression?.trim()) {
            root.result = ""
            return
        }
        
        root.lastQuery = expression.trim()
        calcProcess.running = false  // Stop previous
        calcProcess.command = ["qalc", "-terse", root.lastQuery]
        calcProcess.running = true   // Start new
    }
}