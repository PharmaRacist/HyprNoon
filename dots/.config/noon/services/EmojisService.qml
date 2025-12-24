pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common.functions
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string emojiScriptPath: Directories.scriptsDir + "/emoji_service.sh"
    property string lineBeforeData: "### DATA ###"
    property list<var> list
    
    readonly property list<var> frequentEmojis: {
        const emojiArray = Mem.states.services.emojis?.frequentEmojies || [];
        const counts = {};
        for (let i = 0; i < emojiArray.length; i++) {
            const emoji = emojiArray[i];
            counts[emoji] = (counts[emoji] || 0) + 1;
        }
        const sorted = Object.entries(counts)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 12)
            .map(([emoji, _]) => emoji);
        return sorted;
    }

    function recordEmojiUse(emoji: string) {
        const emojiChar = emoji.split(' ')[0];
        const newArray = Mem.states.services.emojis.frequentEmojies.slice();
        newArray.push(emojiChar);
        Mem.states.services.emojis.frequentEmojies = newArray;
    }

    function resetUsageStats() {
        if (!Mem.states.services.emojis) {
            Mem.states.services.emojis = {};
        }
        Mem.states.services.emojis.frequentEmojies = {};
    }

    function load() {
        emojiFileView.reload();
    }

    function updateEmojis(fileContent) {
        const lines = fileContent.split("\n");
        const dataIndex = lines.indexOf(root.lineBeforeData);
        if (dataIndex === -1) {
            console.warn("No data section found in emoji script file.");
            return;
        }
        const emojis = lines.slice(dataIndex + 1).filter(line => line.trim() !== "");
        root.list = emojis.map(line => line.trim());
    }

    FileView {
        id: emojiFileView
        path: Qt.resolvedUrl(root.emojiScriptPath)
        onLoadedChanged: {
            const fileContent = emojiFileView.text();
            root.updateEmojis(fileContent);
        }
    }
}