import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions

import Quickshell

Item {
    id: root
    anchors {
        fill: parent
        rightMargin: Padding.normal
        leftMargin: Padding.normal
    }
    property alias active: cavaProcess.running
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: mode === "crystal" ? 1000 : 2000
    property int visualizerSmoothing: 3
    property string mode: "filled"
    property color visualizerColor: ColorUtils.transparentize(Colors.colPrimary, 0.35)
    Process {
        id: cavaProcess
        
        onRunningChanged: {
            if (!running) {
                root.visualizerPoints = [];
                cavaProcess.exited(0, "stopped cava");
            }
        }
        command: ["cava", "-p", `${Directories.scriptsDir}/cava/raw_output_config.txt`]

        stdout: SplitParser {
            onRead: data => {
                const points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }
    WaveVisualizer {
        anchors.fill: parent
        z: 0
        visualizerType: mode
        points: root.visualizerPoints
        maxVisualizerValue: root.maxVisualizerValue
        smoothing: root.visualizerSmoothing
        color: root.visualizerColor
    }
}
