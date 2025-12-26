import QtQuick
import Quickshell
import qs.modules.common.utils
pragma Singleton

Singleton {
    id: root

    property string text: ""
    property string author: ""

    function refresh() {
        fetcher.running = false;
        fetcher.running = true;
    }

    Process {
        id: fetcher

        property string output: ""

        command: ["bash", "-c", `${Directories.scriptsDir}/quotes_service.sh`]
        onExited: {
            const line = fetcher.output.trim();
            if (line.length > 0 && line.includes("|")) {
                const parts = line.split("|");
                root.text = parts[0].trim();
                root.author = parts[1].trim();
            }
            fetcher.output = "";
        }

        stdout: SplitParser {
            onRead: (line) => {
                return fetcher.output += line;
            }
        }

    }

}
