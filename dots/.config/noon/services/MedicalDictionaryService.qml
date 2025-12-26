pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.common.utils

Singleton {
    id: root

    readonly property string baseEndpoint: "https://www.dictionaryapi.com/api/v3/references/medical/json"

    property var results: []
    property bool isSearching: false
    property string lastSearchTerm: ""
    property string pendingSearchTerm: ""

    property string apiKey: KeyringStorage.keyringData?.apiKeys?.medicalApiKey ?? ""
    readonly property bool hasApiKey: apiKey.length > 0

    Component.onCompleted: {
        if (!hasApiKey) {
            console.log("Get API key at: https://dictionaryapi.com/register/index");
        }
    }

    // Debounce timer
    Timer {
        id: searchDebounce
        interval: 200
        repeat: false
        onTriggered: performSearch(root.pendingSearchTerm)
    }

    function setApiKey(key) {
        if (key && key.length > 0) {
            KeyringStorage.setNestedField(["apiKeys", "medicalApiKey"], key.trim());
        }
    }

    function clear() {
        root.results = [];
        root.lastSearchTerm = "";
        root.pendingSearchTerm = "";
        searchDebounce.stop();
    }

    // Public search function with debounce
    function search(term) {
        const trimmed = term?.trim() ?? "";

        if (trimmed.length === 0) {
            clear();
            return;
        }

        root.pendingSearchTerm = trimmed;
        searchDebounce.restart();
    }

    // Internal search function without debounce
    function performSearch(term) {
        if (term === lastSearchTerm) return;

        lastSearchTerm = term;
        isSearching = true;
        requester.makeRequest(term);
    }

    // Get current result without triggering search
    function getResult(term) {
        const trimmed = term?.trim() ?? "";
        if (!trimmed || trimmed !== lastSearchTerm) return "";

        if (results.length === 0) return "";

        const firstResult = results[0];
        if (firstResult.suggestions) {
            return `${firstResult.suggestions.slice(0, 3).join(", ")}`;
        }

        if (firstResult.definitions && firstResult.definitions.length > 0) {
            return firstResult.definitions[0];
        }

        return "";
    }

    function cleanText(text) {
        if (!text) return "";
        return text.replace(/\{[^}]*\}/g, '').replace(/^\s*:\s*/, '').trim();
    }

    function extractDefinitions(entry) {
        // Try shortdef first
        if (entry.shortdef && Array.isArray(entry.shortdef)) {
            return entry.shortdef.filter(def => def?.trim().length > 0);
        }

        // Try detailed structure
        let definitions = [];
        if (entry.def && Array.isArray(entry.def)) {
            entry.def.forEach(defSection => {
                if (!defSection.sseq || !Array.isArray(defSection.sseq)) return;

                defSection.sseq.forEach(sense => {
                    if (!Array.isArray(sense)) return;

                    sense.forEach(item => {
                        if (!Array.isArray(item) || item[0] !== 'sense') return;

                        const senseData = item[1];
                        if (!senseData?.dt || !Array.isArray(senseData.dt)) return;

                        senseData.dt.forEach(dtItem => {
                            if (Array.isArray(dtItem) && dtItem[0] === 'text') {
                                const cleaned = cleanText(dtItem[1]);
                                if (cleaned) definitions.push(cleaned);
                            }
                        });
                    });
                });
            });
        }

        return definitions;
    }

    function parseEntry(entry, searchTerm) {
        return {
            word: (entry.meta?.id || entry.hwi?.hw || searchTerm).replace(/\*/g, ''),
            partOfSpeech: entry.fl || '',
            pronunciation: entry.hwi?.prs?.[0]?.mw || '',
            definitions: extractDefinitions(entry)
        };
    }

    Process {
        id: requester
        property string searchTerm: ""
        property string buffer: ""

        function makeRequest(term) {
            if (!root.hasApiKey) {
                root.isSearching = false;
                return;
            }

            searchTerm = term.toLowerCase().trim();
            const endpoint = `${root.baseEndpoint}/${encodeURIComponent(searchTerm)}?key=${root.apiKey}`;
            command = ["curl", "-s", endpoint];
            buffer = "";
            running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                requester.buffer += data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.isSearching = false;

            if (exitCode !== 0 || !buffer) {
                root.results = [];
                return;
            }

            try {
                // Extract all JSON arrays from response
                let jsonArrays = [];
                let depth = 0;
                let start = -1;

                for (let i = 0; i < buffer.length; i++) {
                    if (buffer[i] === '[') {
                        if (depth === 0) start = i;
                        depth++;
                    } else if (buffer[i] === ']') {
                        depth--;
                        if (depth === 0 && start !== -1) {
                            try {
                                jsonArrays.push(JSON.parse(buffer.substring(start, i + 1)));
                            } catch (e) {}
                            start = -1;
                        }
                    }
                }

                if (jsonArrays.length === 0) {
                    root.results = [];
                    return;
                }

                // Use last array (actual results)
                const response = jsonArrays[jsonArrays.length - 1];

                if (!Array.isArray(response) || response.length === 0) {
                    root.results = [];
                    return;
                }

                // Handle suggestions
                if (typeof response[0] === 'string') {
                    root.results = [{
                        word: "Did you mean",
                        suggestions: response,
                        definitions: [],
                        partOfSpeech: "",
                        pronunciation: ""
                    }];
                    return;
                }

                // Parse definitions
                root.results = response.map(entry => root.parseEntry(entry, searchTerm));

            } catch (e) {
                console.error("Parse error:", e);
                root.results = [];
            }
        }
    }
}
