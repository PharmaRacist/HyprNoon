import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils
pragma Singleton

// Wrapper for the firefox bookmarks script
Singleton {
    id: root

    // Properties
    property var bookmarks: Mem.states.services.bookmarks.firefoxBookmarks ?? []
    property var bookmarkTitles: bookmarks.map((b) => {
        return b.title;
    })
    property var bookmarkUrls: bookmarks.map((b) => {
        return b.url;
    })
    property bool isLoading: false
    property string error: ""
    property bool autoRefresh: true
    property int refreshInterval: 6e+06 // 10 minutes in milliseconds
    readonly property string scriptPath: Directories.scriptsDir + "/bookmarks_service.py"

    // Public API
    function refresh() {
        loadBookmarks();
        fetchFavicons();
    }

    function fetchFavicons() {
        fetchFaviconsProcess.running = true;
    }

    function refreshFavicons() {
        fetchFavicons();
    }

    function removeBookmark(bookmarkId) {
        if (!bookmarkId)
            return ;

        Quickshell.execDetached(["python3", scriptPath, "remove", bookmarkId.toString()]);
    }

    function openUrl(url) {
        if (!url)
            return ;

        Quickshell.execDetached(["python3", scriptPath, "open", url]);
    }

    function searchBookmarks(query) {
        const q = (query || "").toLowerCase();
        return bookmarks.filter((b) => {
            return (b.title && b.title.toLowerCase().includes(q)) || (b.url && b.url.toLowerCase().includes(q));
        });
    }

    // Internal functions
    function loadBookmarks() {
        isLoading = true;
        error = "";
        loadBookmarksProcess.running = true;
    }

    Component.onCompleted: {
        refresh();
        Qt.callLater(fetchFavicons);
        if (autoRefresh)
            refreshTimer.start();

    }
    // Watch for autoRefresh changes
    onAutoRefreshChanged: {
        if (autoRefresh)
            refreshTimer.start();
        else
            refreshTimer.stop();
    }
    // Watch for interval changes
    onRefreshIntervalChanged: {
        if (refreshTimer.running)
            refreshTimer.restart();

    }

    Timer {
        id: refreshTimer

        interval: root.refreshInterval
        repeat: true
        running: false
        onTriggered: root.loadBookmarks()
    }

    // Process: Load all bookmarks
    Process {
        id: loadBookmarksProcess

        command: ["python3", root.scriptPath, "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoading = false;
                try {
                    const result = JSON.parse(this.text.trim());
                    if (result.error) {
                        console.error("FirefoxBookmarksService: Error from script:", result.error);
                        root.error = result.error;
                        Mem.states.services.bookmarks.firefoxBookmarks = [];
                    } else {
                        console.log("FirefoxBookmarksService: Loaded", result.length, "bookmarks");
                        Mem.states.services.bookmarks.firefoxBookmarks = result;
                        root.error = "";
                    }
                } catch (e) {
                    console.error("FirefoxBookmarksService: Failed to parse bookmarks:", e, this.text);
                    Mem.states.services.bookmarks.firefoxBookmarks = [];
                    root.error = "Failed to parse bookmarks";
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim())
                    console.error("FirefoxBookmarksService: stderr:", this.text);

            }
        }

    }

    // Process: Fetch all favicons
    Process {
        id: fetchFaviconsProcess

        command: ["python3", root.scriptPath, "fetch-favicons"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(this.text.trim());
                    if (result.downloaded > 0)
                        loadBookmarks();

                } catch (e) {
                    console.error("FirefoxBookmarksService: Failed to parse favicon fetch result:", e);
                }
            }
        }

        stderr: StdioCollector {
        }

    }

}
