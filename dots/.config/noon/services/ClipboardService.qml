pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property list<string> entries: []
    readonly property string currentEntry: entries[0] ?? ""
    readonly property var imageRegex: /^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/
    property int maxEntries: 50

    signal entriesRefreshed
    signal imageDecoded(string path)

    function entryIsImage(entry) {
        return imageRegex.test(entry);
    }

    function getEntryNumber(entry) {
        return entry.split("\t")[0];
    }

    function getCurrentEntry() {
        return entryIsImage(currentEntry) ? decodeImageEntry(currentEntry) : currentEntry.trim();
    }

    function getLatestImage() {
        for (var i = 0; i < entries.length; i++) {
            if (entryIsImage(entries[i])) {
                decodeImageEntryAsync(entries[i]);
                return;
            }
        }
        root.imageDecoded("");
    }

    function reload() {
        if (listProc.running) return;
        listProc.buffer = [];
        listProc.running = true;
    }

    function decodeImageEntry(entry) {
        var num = getEntryNumber(entry);
        var path = '/tmp/cliphist-' + num + '.png';
        Noon.execDetached('cliphist decode ' + num + " > '" + path + "'");
        return path;
    }

    function decodeImageEntryAsync(entry) {
        var num = getEntryNumber(entry);
        decodeProc.targetPath = '/tmp/cliphist-' + num + '.png';
        decodeProc.command = ['bash', '-c', 'cliphist decode ' + num + " > '" + decodeProc.targetPath + "'"];
        decodeProc.running = true;
    }

    function copy(entry) {
        copyProc.command = ['bash', '-c', "printf '" + StringUtils.shellSingleQuoteEscape(entry) + "' | cliphist decode | wl-copy"];
        copyProc.running = true;
    }

    function deleteEntry(entry) {
        deleteProc.command = ['bash', '-c', "printf '" + StringUtils.shellSingleQuoteEscape(entry) + "' | cliphist delete"];
        deleteProc.running = true;
    }

    function wipe() {
        wipeProc.running = true;
    }

    Process {
        id: copyProc
    }

    Process {
        id: decodeProc
        property string targetPath: ""
        onExited: function(exitCode) { root.imageDecoded(exitCode === 0 ? targetPath : "") }
    }

    Process {
        id: deleteProc
        onExited: function() { refreshTimer.restart() }
    }

    Process {
        id: wipeProc
        command: ['cliphist', 'wipe']
        onExited: function() { refreshTimer.restart() }
    }

    Process {
        id: listProc
        property list<string> buffer: []
        property int lineCount: 0
        command: ['cliphist', 'list']
        stdout: SplitParser {
            onRead: function(line) {
                if (listProc.lineCount < root.maxEntries) {
                    listProc.buffer.push(line);
                    listProc.lineCount++;
                }
            }
        }
        onStarted: function() { lineCount = 0 }
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.entries = listProc.buffer;
                root.entriesRefreshed();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
