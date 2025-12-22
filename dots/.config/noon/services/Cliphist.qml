pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string cliphistBinary: "cliphist"
    property real pasteDelay: 0.05
    property string pressPasteCommand: "ydotool key -d 1 29:1 47:1 47:0 29:0"
    property list<string> entries: []
    readonly property var currentEntry: entries[0]

    signal entriesRefreshed
    signal imageDecoded(string path)

    function entryIsImage(entry) {
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry));
    }

    function getCurrentEntry() {
        if (Cliphist.entryIsImage(currentEntry)) {
            const result = decodeImageEntry(currentEntry);
            return result;
        } else {
            return currentEntry.trim();
        }
    }

    function getLatestImage() {
        for (let i = 0; i < entries.length; i++) {
            if (entryIsImage(entries[i])) {
                decodeImageEntryAsync(entries[i]);
                return;
            }
        }
        root.imageDecoded("");
    }

    function refresh() {
        readProc.buffer = [];
        readProc.running = true;
    }

    function decodeImageEntry(entry) {
        const entryNumber = entry.split("\t")[0];
        const tmpPath = `/tmp/cliphist-${entryNumber}.png`;
        Noon.execDetached(`${Cliphist.cliphistBinary} decode ${entryNumber} > '${tmpPath}' && while [ ! -s '${tmpPath}' ]; do sleep 0.01; done`);
        return tmpPath.trim();
    }

    function decodeImageEntryAsync(entry) {
        const entryNumber = entry.split("\t")[0];
        decodeProc.targetPath = `/tmp/cliphist-${entryNumber}.png`;
        decodeProc.command = ["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} > '${decodeProc.targetPath}'`];
        decodeProc.running = true;
    }

    Process {
        id: decodeProc
        property string targetPath: ""

        onExited: exitCode => {
            if (exitCode === 0 && targetPath) {
                root.imageDecoded(targetPath);
            } else {
                root.imageDecoded("");
            }
        }
    }

    function copy(entry) {
        if (root.cliphistBinary.includes("cliphist"))
            Noon.execDetached(`printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy`);
        else {
            const entryNumber = entry.split("\t")[0];
            Noon.execDetached(`${root.cliphistBinary} decode ${entryNumber} | wl-copy`);
        }
    }

    function paste(entry) {
        if (root.cliphistBinary.includes("cliphist"))
            Noon.execDetached(`printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && wl-paste`);
        else {
            const entryNumber = entry.split("\t")[0];
            Noon.execDetached(`${root.cliphistBinary} decode ${entryNumber} | wl-copy; ${root.pressPasteCommand}`);
        }
    }

    function superpaste(count, isImage = false) {
        const targetEntries = entries.filter(entry => {
            if (!isImage) return true;
            return entryIsImage(entry);
        }).slice(0, count);
        const pasteCommands = [...targetEntries].reverse().map(entry => 
            `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`
        );
        Noon.execDetached(pasteCommands.join(` && sleep ${root.pasteDelay} && `));
    }

    Process {
        id: deleteProc
        property string entry: ""
        command: ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(deleteProc.entry)}' | ${root.cliphistBinary} delete`]
        function deleteEntry(entry) {
            deleteProc.entry = entry;
            deleteProc.running = true;
            deleteProc.entry = "";
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function deleteEntry(entry) {
        deleteProc.deleteEntry(entry);
    }

    Process {
        id: wipeProc
        command: [root.cliphistBinary, "wipe"]
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function wipe() {
        wipeProc.running = true;
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            delayedUpdateTimer.restart();
        }
    }

    Timer {
        id: delayedUpdateTimer
        interval: Mem.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: readProc
        property list<string> buffer: []
        command: [root.cliphistBinary, "list"]
        stdout: SplitParser {
            onRead: line => readProc.buffer.push(line)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer;
                root.entriesRefreshed();
            }
        }
    }
}