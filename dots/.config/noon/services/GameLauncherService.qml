pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.utils
import Quickshell
import Qt.labs.platform
import QtQuick

Singleton {
    id: root

    property var filePath: Directories.state + "/user/games.json"
    property var gamesList: []

    // Game status constants
    readonly property int status_not_installed: 0
    readonly property int status_installed: 1
    readonly property int status_playing: 2
    readonly property int status_completed: 3

    readonly property var statusNames: ["Not Installed", "Installed", "Playing", "Completed"]

    function addGame(name, executablePath, useWine = false, coverImage = "", description = "") {
        const game = {
            "id": Date.now() + Math.random(),
            "name": name,
            "executablePath": executablePath,
            "useWine": useWine,
            "coverImage": coverImage,
            "description": description,
            "status": status_installed,
            "lastPlayed": null,
            "playTime": 0,
            "dateAdded": new Date().toISOString()
        };

        gamesList.push(game);
        root.gamesList = gamesList.slice(0);
        saveGames();
    }

    function deleteGame(gameId) {
        const index = gamesList.findIndex(game => game.id === gameId);
        if (index >= 0) {
            gamesList.splice(index, 1);
            root.gamesList = gamesList.slice(0);
            saveGames();
        }
    }

    function updateGameStatus(gameId, newStatus) {
        const game = gamesList.find(g => g.id === gameId);
        if (game && newStatus >= status_not_installed && newStatus <= status_completed) {
            game.status = newStatus;
            root.gamesList = gamesList.slice(0);
            saveGames();
        }
    }

    property var currentGame: null

    function launchGame(gameId) {
        const game = gamesList.find(g => g.id === gameId);
        if (!game) return false;

        game.lastPlayed = new Date().toISOString();
        if (game.status === status_installed) {
            game.status = status_playing;
        }
        root.gamesList = gamesList.slice(0);
        saveGames();

        if (Mem.options.games.launchWithGameMode) {
            hyprctlProcess.running = true;
        }

        Noon.notify("Game Launched");
        currentGame = game;
        gameProcess.running = true;
        return true;
    }

    function saveGames() {
        gameFileView.setText(JSON.stringify(root.gamesList, null, 2));
    }

    function refresh() {
        gameFileView.reload();
    }

    function getGamesByStatus(status) {
        return gamesList.filter(game => game.status === status);
    }

    function getGameCount() {
        return gamesList.length;
    }

    function getRecentlyPlayed(count = 5) {
        return gamesList.filter(game => game.lastPlayed)
            .sort((a, b) => new Date(b.lastPlayed) - new Date(a.lastPlayed))
            .slice(0, count);
    }

    function searchGames(query) {
        const lowerQuery = query.toLowerCase();
        return gamesList.filter(game =>
            game.name.toLowerCase().includes(lowerQuery) ||
            game.description.toLowerCase().includes(lowerQuery)
        );
    }

    Component.onCompleted: {
        refresh();
    }

    Process {
        id: hyprctlProcess
        command: ["hyprctl", "--batch",
            "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword input:sensitivity 0; keyword decoration:rounding 0; keyword general:allow_tearing 1"]
        running: false
    }

    Process {
        id: gameProcess
        command: {
            if (!root.currentGame) return [];

            const gamePath = root.currentGame.executablePath;
            const useWine = root.currentGame.useWine;
            const useGameMode = Mem.options.games.launchWithGameMode;

            if (useWine && useGameMode) {
                return ["gamemoderun", "wine", gamePath];
            } else if (useWine) {
                return ["wine", gamePath];
            } else if (useGameMode) {
                return ["gamemoderun", gamePath];
            } else {
                return [gamePath];
            }
        }
        workingDirectory: {
            if (!root.currentGame) return "";
            const path = root.currentGame.executablePath;
            return path.substring(0, path.lastIndexOf('/'));
        }
        running: false

        Component.onCompleted: {
            gameProcess.environment["__NV_PRIME_RENDER_OFFLOAD"] = "1";
            gameProcess.environment["__GLX_VENDOR_LIBRARY_NAME"] = "nvidia";
        }
    }

    FileView {
        id: gameFileView
        path: Qt.resolvedUrl(root.filePath)

        onLoaded: {
            try {
                const fileContents = gameFileView.text();
                let parsedList = JSON.parse(fileContents);
                root.gamesList = parsedList || [];
            } catch (error) {
                root.gamesList = [];
            }
        }

        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.gamesList = [];
                saveGames();
            }
        }
    }
}
