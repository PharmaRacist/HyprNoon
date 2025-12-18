pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Qt.labs.folderlistmodel

Singleton {
    id: musicPlayerService

    // Player management
    property int selectedPlayerIndex: Mem.states.services.mediaPlayer.selectedPlayerIndex
    property bool hasPlasmaIntegration: true
    property bool filterPlayersEnabled: false
    readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)

    readonly property var realPlayers: {
        let players = Mpris.players?.values ?? [];
        return filterPlayersEnabled ? players.filter(player => isRealPlayer(player)) : players;
    }

    readonly property MprisPlayer player: {
        if (!meaningfulPlayers || meaningfulPlayers.length === 0)
            return null;
        const validIndex = Math.max(0, Math.min(selectedPlayerIndex, meaningfulPlayers.length - 1));
        return meaningfulPlayers[validIndex];
    }

    // Track management
    property string currentTrackPath: ""
    readonly property string musicDirectory: Directories.music
    readonly property string isolatedDirectory: FileUtils.trimFileProtocol(musicDirectory) + "/IsolatedTracks"
    readonly property string downloadDir: FileUtils.trimFileProtocol(Directories.music)

    // Filter & search state
    property var filteredIndices: []
    property var shuffledIndices: []
    property bool shuffleEnabled: false
    property string currentSearchText: ""

    // Exposed for UI binding
    readonly property int filteredTracksCount: filteredIndices.length

    // Player info
    readonly property MprisPlayer activePlayer: player
    readonly property real currentTrackProgressRatio: {
        const pos = player?.position ?? 0;
        const len = player?.length ?? 0;
        if (len <= 0)
            return 0.0;
        return Math.max(0.0, Math.min(1.0, pos / len));
    }

    readonly property string artUrl: player ? player.trackArtUrl : ""
    readonly property string title: player?.trackTitle ? StringUtils.cleanMusicTitle(player.trackTitle) : ""
    readonly property string artist: player?.trackArtist ? StringUtils.cleanMusicTitle(player.trackArtist) : ""

    readonly property string cleanedTitle: {
        if (!player)
            return "";
        const titlePart = player.trackTitle ?? "";
        const artistPart = player.trackArtist ?? "";
        return StringUtils.cleanMusicTitle(titlePart + " " + artistPart);
    }

    readonly property real currentTrackProgress: player?.position ?? 0

    // Tracks model
    property alias tracksModel: tracksModel

    FolderListModel {
        id: tracksModel
        folder: musicDirectory
        nameFilters: ["*.mp3", "*.flac", "*.ogg", "*.wav", "*.m4a", "*.aac", "*.wma", "*.opus"]
        showDirs: false
        showFiles: true
        sortField: FolderListModel.Name

        onCountChanged: updateFilter()
    }

    // Player management functions
    onSelectedPlayerIndexChanged: {
        if (Mem.states.services.mediaPlayer.selectedPlayerIndex !== selectedPlayerIndex) {
            Mem.states.services.mediaPlayer.selectedPlayerIndex = selectedPlayerIndex;
        }
    }

    onMeaningfulPlayersChanged: {
        if (meaningfulPlayers && meaningfulPlayers.length > 0) {
            if (selectedPlayerIndex >= meaningfulPlayers.length) {
                selectedPlayerIndex = 0;
            }
        }
    }

    function isRealPlayer(player) {
        if (!player || !player.dbusName)
            return false;

        if (!player.dbusName.startsWith("org.mpris.MediaPlayer2."))
            return false;

        if (!filterPlayersEnabled)
            return true;

        if (player.dbusName.indexOf("kdeconnect") !== -1)
            return false;

        if (hasPlasmaIntegration && (player.dbusName.startsWith("org.mpris.MediaPlayer2.firefox") || player.dbusName.startsWith("org.mpris.MediaPlayer2.chromium")))
            return false;

        if (player.dbusName.startsWith("org.mpris.MediaPlayer2.playerctld"))
            return false;

        if (player.dbusName.endsWith(".mpd") && !player.dbusName.endsWith("MediaPlayer2.mpd"))
            return false;

        return true;
    }

    function filterDuplicatePlayers(players) {
        if (!players || players.length === 0)
            return [];
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue;

            let p1 = players[i];
            let group = [i];

            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
                if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle))) {
                    group.push(j);
                }
            }

            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(players[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    // Track info functions
    function getTrackInfo(index) {
        if (index < 0 || index >= tracksModel.count) {
            return {
                name: "",
                path: "",
                fileUrl: "",
                extension: "",
                fileName: ""
            };
        }

        try {
            const fileName = tracksModel.get(index, "fileName") || "";
            const fileUrl = tracksModel.get(index, "fileUrl") || "";
            const baseName = tracksModel.get(index, "baseName") || "";

            let extension = fileName.includes('.') ? fileName.split('.').pop().toUpperCase() : "";
            let filePath = fileUrl.toString().startsWith("file://") ? decodeURIComponent(fileUrl.toString().replace("file://", "")) : fileUrl.toString();

            return {
                name: baseName || fileName.replace(/\.[^/.]+$/, "") || "Unknown Track",
                path: filePath,
                fileUrl,
                extension,
                fileName
            };
        } catch (e) {
            return {
                name: "Unknown Track",
                path: "",
                fileUrl: "",
                extension: "",
                fileName: ""
            };
        }
    }

    function getFilteredTrackInfo(filteredIndex) {
        if (filteredIndex < 0 || filteredIndex >= filteredIndices.length) {
            return {
                name: "Unknown Track",
                path: "",
                fileUrl: "",
                extension: "",
                fileName: ""
            };
        }
        const originalIndex = filteredIndices[filteredIndex];
        return getTrackInfo(originalIndex);
    }

    // Filter and search functions
    function initializeTracks() {
        shuffleTracks();
    }

    function updateFilter() {
        filteredIndices = [];

        for (let i = 0; i < tracksModel.count; i++) {
            let trackInfo = getTrackInfo(i);
            if (currentSearchText === "" || trackInfo.name.toLowerCase().includes(currentSearchText.toLowerCase())) {
                filteredIndices.push(i);
            }
        }

        if (shuffleEnabled) {
            shuffleCurrentIndices();
        }
    }

    function updateSearchFilter(searchText) {
        currentSearchText = searchText;
        updateFilter();
    }

    function shuffleCurrentIndices() {
        shuffledIndices = filteredIndices.slice();
        for (let i = shuffledIndices.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [shuffledIndices[i], shuffledIndices[j]] = [shuffledIndices[j], shuffledIndices[i]];
        }
        filteredIndices = shuffledIndices;
    }

    function shuffleTracks() {
        shuffleEnabled = true;
        updateFilter();
    }

    function unshuffleTracks() {
        shuffleEnabled = false;
        updateFilter();
    }

    // Playback functions
    function playTrackByPath(filePath) {
        if (!filePath || tracksModel.count === 0)
            return;

        const cleanFilePath = FileUtils.trimFileProtocol(filePath);
        Mem.states.mediaPlayer.currentTrackPath = filePath;

        const allPaths = [];
        for (let i = 0; i < filteredIndices.length; ++i) {
            const url = tracksModel.get(filteredIndices[i], "fileUrl");
            if (url && url.toString().startsWith("file://")) {
                allPaths.push(decodeURIComponent(url.toString().substring(7)));
            }
        }

        const startIndex = allPaths.indexOf(cleanFilePath);
        if (startIndex === -1)
            return;

        const reordered = allPaths.slice(startIndex).concat(allPaths.slice(0, startIndex));
        const joined = reordered.map(p => `'${p.replace(/'/g, `'\\''`)}'`).join(" ");
        Quickshell.execDetached(["bash", "-c", `killall -9 vlc && sleep 1 && vlc --intf dummy --no-video '${joined}'`]);
    }

    function playFirstFilteredTrack() {
        if (filteredIndices.length > 0) {
            const info = getFilteredTrackInfo(0);
            if (info?.path)
                playTrackByPath(info.path);
        }
    }

    function isolateTrack(filePath) {
        if (!filePath)
            return;

        const cleanPath = FileUtils.trimFileProtocol(filePath);
        const path = `'${cleanPath.replace(/'/g, `'\\''`)}'`;
        Noon.exec(`mv ${path} "${isolatedDirectory}"`);

        // Remove from filtered indices
        const indexToRemove = filteredIndices.findIndex(idx => {
            const info = getTrackInfo(idx);
            return info.path === cleanPath;
        });

        if (indexToRemove !== -1) {
            filteredIndices.splice(indexToRemove, 1);
            filteredIndices = filteredIndices; // Trigger property change
        }
    }

    function cycleRepeat() {
        const p = musicPlayerService.player;
        if (!p?.canControl)
            return;

        let nextState;
        switch (p.loopState || MprisLoopState.None) {
        case MprisLoopState.None:
            nextState = MprisLoopState.Playlist;
            break;
        case MprisLoopState.Playlist:
            nextState = MprisLoopState.Track;
            break;
        case MprisLoopState.Track:
            nextState = MprisLoopState.None;
            break;
        default:
            nextState = MprisLoopState.None;
        }
        p.loopState = nextState;
    }

    // YouTube integration functions
    function formatTimeSeconds(seconds) {
        if (!seconds || seconds < 0)
            return "0:00";
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${mins}:${secs < 10 ? "0" + secs : secs}`;
    }

    function downloadCurrentSong() {
        if (cleanedTitle)
            downloadSong(cleanedTitle);
    }

    function playVideo(query) {
        Noon.execDetached(`xdg-open https://www.youtube.com/results?search_query=${encodeURIComponent(query)}`);
    }

    function isCurrentPlayer() {
        return player && player.desktopEntry && player.desktopEntry.toLowerCase() === "vlc";
    }

    function stopPlayer() {
        Noon.execDetached("killall vlc");
    }

    function playSong(query) {
        Noon.execDetached(`
            pkill vlc;
            vlc --intf dummy --extraintf http --http-password vlcremote --no-video --audio-filter mpris2 "https://www.youtube.com/results?search_query=${encodeURIComponent(query)}" &
        `);
    }

    function downloadSong(query) {
        Noon.execDetached(`
            notify-send "YouTube Music Downloader" "Downloading: ${query}...";
            cd "${downloadDir}";
            yt-dlp -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "ytsearch1:${query}" &&
            notify-send "YouTube Music Downloader" "Downloaded: ${query}"
        `);
    }

    function downloadVideo(query) {
        Noon.execDetached(`
            notify-send "YouTube Video Downloader" "Downloading: ${query}...";
            yt-dlp -f "best[height<=720]" --embed-subs --add-metadata "ytsearch1:${query}" &&
            notify-send "YouTube Video Downloader" "Downloaded: ${query}"
        `);
    }

    Timer {
        id: positionTimer
        interval: 100
        repeat: true
        running: musicPlayerService.player && player.playbackState === MprisPlaybackState.Playing
        onTriggered: musicPlayerService.player.positionChanged()
    }
}
