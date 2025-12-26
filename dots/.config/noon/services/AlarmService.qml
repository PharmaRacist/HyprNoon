import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils
pragma Singleton

Singleton {
    id: root

    property string dbPath: Directories.shellConfigs + "alarms.json"
    property string binary: Directories.scriptsDir + "/alarm_service.py"
    property var alarms: []
    property bool hasAlarms: alarms.length > 0
    property int timeUntilNext: -1
    property bool isUpdating: false

    function reload() {
        fileView.reload();
    }

    function addTimer(timeStr, message, remindInterval) {
        let cmd = [root.binary, "add", timeStr, message];
        if (remindInterval !== undefined && remindInterval !== null)
            cmd.push(remindInterval.toString());

        Quickshell.execDetached(cmd);
    }

    function toggleAlarm(timerId, setActive) {
        Quickshell.execDetached([root.binary, "toggle", timerId, setActive.toString()]);
    }

    function formatTime(isoTime) {
        let date = new Date(isoTime);
        let h = date.getHours() % 12 || 12;
        let m = date.getMinutes() < 10 ? "0" + date.getMinutes() : date.getMinutes();
        return `${h}:${m} ${date.getHours() >= 12 ? "PM" : "AM"}`;
    }

    function clearAll() {
        Quickshell.execDetached([root.binary, "clear"]);
    }

    function getTimeUntil() {
        let now = new Date();
        let active = root.alarms.filter((a) => {
            return a.active && !a.ringed && new Date(a.time) > now;
        });
        if (active.length === 0)
            return -1;

        let next = active.reduce((n, a) => {
            return new Date(a.time) < new Date(n.time) ? a : n;
        });
        return Math.floor((new Date(next.time) - now) / 1000);
    }

    function formatUntil(seconds) {
        if (seconds < 0)
            return "Passed";

        if (seconds < 60)
            return `${seconds}s`;

        let min = Math.floor(seconds / 60);
        if (min < 60)
            return `${min}min`;

        return `${Math.floor(min / 60)}h ${min % 60}min`;
    }

    FileView {
        id: fileView

        function parseContent() {
            let content = fileView.text();
            if (!content || content.trim() === "") {
                root.alarms = [];
                root.timeUntilNext = -1;
                return ;
            }
            try {
                root.alarms = JSON.parse(content);
                root.timeUntilNext = root.getTimeUntil();
                console.log("Parsed", root.alarms.length, "alarms");
            } catch (e) {
                console.error("JSON parse error:", e);
                root.alarms = [];
                root.timeUntilNext = -1;
            }
        }

        path: root.dbPath
        watchChanges: true
        onTextChanged: {
            if (!root.isUpdating)
                parseContent();

        }
        Component.onCompleted: parseContent()
    }

}
