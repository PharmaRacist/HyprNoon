pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions


Singleton {
    id: root

    enum State {
        Idle,
        Loading,
        HasSyncedLyrics,
        HasPlainLyrics,
        NoLyricsFound,
        NetworkError
    }

    property int state: LyricsService.Idle
    property string lyrics: ""
    property var onlineLyricsData: null
    
    readonly property string cacheDir: Directories.lyrics
    readonly property string userAgent: Mem.options.networking.userAgent

    property string _currentArtist: ""
    property string _currentTitle: ""

    function normalizeTitle(str) {
        return str ? str.replace(/\s*[\(\[].*?[\)\]]\s*/g, ' ')
            .replace(/\s*-\s*(Official|Lyric|Audio|Video|Music Video|Visualizer|Remaster(?:ed)?)\s*$/gi, '')
            .replace(/\s+/g, ' ')
            .trim()
            .toLowerCase() : "";
    }

    function normalizeArtist(str) {
        return str ? str.replace(/\s+(?:feat\.|featuring|ft\.|with|x|&)\s+.*/gi, '')
            .replace(/\s*[\(\[].*?[\)\]]\s*/g, ' ')
            .replace(/\s+/g, ' ')
            .trim()
            .toLowerCase() : "";
    }

    function sanitizeFilename(str) {
        return str.replace(/[\/\\:*?"<>|]/g, '_').replace(/\s+/g, '_').toLowerCase();
    }

    function getCacheFilePath(artist, title) {
        const sanitizedArtist = sanitizeFilename(normalizeArtist(artist));
        const sanitizedTitle = sanitizeFilename(normalizeTitle(title));
        return `${cacheDir}/${sanitizedTitle}_${sanitizedArtist}.json`;
    }

    function loadLyrics(data) {
        onlineLyricsData = data;
        
        if (data.syncedLyrics) {
            state = LyricsService.HasSyncedLyrics;
            lyrics = "Synced lyrics ready";
        } else if (data.plainLyrics) {
            state = LyricsService.HasPlainLyrics;
            lyrics = data.plainLyrics;
        } else {
            state = LyricsService.NoLyricsFound;
            lyrics = "No lyrics found for this song";
        }
    }

    function saveToCache(artist, title, data) {
        const filePath = getCacheFilePath(artist, title);
        const jsonString = JSON.stringify(data);
        
        shellExec.execute(
            `mkdir -p ${JSON.stringify(cacheDir)} && printf '%s' ${JSON.stringify(jsonString)} > ${JSON.stringify(filePath)}`
        );
    }

    function fetchLyrics(artist, title) {
        if (!artist || !title) {
            state = LyricsService.Idle;
            lyrics = "";
            return;
        }

        _currentArtist = artist;
        _currentTitle = title;
        state = LyricsService.Loading;
        lyrics = "Loading";

        const exactPath = getCacheFilePath(artist, title);
        shellExec.execute(
            `cat ${JSON.stringify(exactPath)} 2>/dev/null`,
            (output) => {
                if (output?.trim()) {
                    try {
                        loadLyrics(JSON.parse(output));
                        return;
                    } catch (e) {}
                }
                fetchFromAPI();
            }
        );
    }

    function fetchFromAPI() {
        const normalizedArtist = normalizeArtist(_currentArtist);
        const normalizedTitle = normalizeTitle(_currentTitle);
        const url = `https://lrclib.net/api/search?artist_name=${encodeURI(normalizedArtist)}&track_name=${encodeURI(normalizedTitle)}`;
        
        shellExec.execute(
            `curl -s -A ${JSON.stringify(userAgent)} -S ${JSON.stringify(url)}`,
            (output) => {
                try {
                    const data = JSON.parse(output);
                    
                    if (data.statusCode) {
                        state = LyricsService.NetworkError;
                        lyrics = "Failed to connect to lyrics service";
                        onlineLyricsData = null;
                    } else if (Array.isArray(data)) {
                        if (data.length > 0) {
                            saveToCache(_currentArtist, _currentTitle, data[0]);
                            loadLyrics(data[0]);
                        } else {
                            state = LyricsService.NoLyricsFound;
                            lyrics = "No lyrics found for this song";
                            onlineLyricsData = null;
                        }
                    } else {
                        saveToCache(_currentArtist, _currentTitle, data);
                        loadLyrics(data);
                    }
                } catch (e) {
                    state = LyricsService.NetworkError;
                    lyrics = "Failed to retrieve lyrics";
                    onlineLyricsData = null;
                }
            },
            () => {
                state = LyricsService.NetworkError;
                lyrics = "Network error occurred";
                onlineLyricsData = null;
            }
        );
    }

    function getSyncedLyrics(position) {
        if (state !== LyricsService.HasSyncedLyrics || !onlineLyricsData?.syncedLyrics) {
            return "";
        }

        const lines = onlineLyricsData.syncedLyrics.split('\n');
        let currentLine = "";

        for (const line of lines) {
            const match = line.match(/\[(\d+):(\d+\.\d+)\](.*)/);
            if (match) {
                const timestamp = parseInt(match[1]) * 60 + parseFloat(match[2]);
                if (timestamp <= position) {
                    currentLine = match[3].trim();
                } else {
                    break;
                }
            }
        }

        return currentLine;
    }

    QtObject {
        id: shellExec
        
        property var queue: []
        property bool busy: false

        function execute(command, onSuccess, onError) {
            queue.push({ command, onSuccess, onError });
            processQueue();
        }

        function processQueue() {
            if (busy || queue.length === 0) return;
            
            busy = true;
            const task = queue.shift();
            
            proc.command = ["sh", "-c", task.command];
            proc.userData = task;
            proc.running = true;
        }
    }

    Process {
        id: proc
        running: false
        property var userData: null

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (proc.userData?.onSuccess) {
                    proc.userData.onSuccess(text);
                }
                shellExec.busy = false;
                Qt.callLater(shellExec.processQueue);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text?.trim() && proc.userData?.onError) {
                    proc.userData.onError(text);
                }
                shellExec.busy = false;
                Qt.callLater(shellExec.processQueue);
            }
        }
    }

    Timer {
        id: fetchDelayTimer
        interval: 50
        onTriggered: fetchLyrics(BeatsService.artist || "", BeatsService.title || "")
    }

    Connections {
        target: BeatsService
        
        function onTitleChanged() {
            if (BeatsService?.title) {
                fetchDelayTimer.restart();
            }
        }

        function onCurrentTrackProgressChanged() {
            if (state === LyricsService.HasSyncedLyrics) {
                const syncedLine = getSyncedLyrics(BeatsService.currentTrackProgress);
                if (syncedLine && syncedLine !== lyrics) {
                    lyrics = syncedLine;
                }
            }
        }
    }

    Component.onCompleted: {
        if (BeatsService?.title) {
            fetchLyrics(BeatsService.artist || "", BeatsService.title || "");
        }
    }
}
