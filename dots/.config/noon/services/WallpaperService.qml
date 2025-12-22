pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs.modules.common
import qs.modules.common.functions
import qs.services

Singleton {
    id: root

    readonly property string currentWallpaper: Mem.states.desktop.bg.currentBg ?? "root:///assets/images/default_wallpaper.png"
    readonly property string shellMode: Mem.states.desktop.appearance.mode
    readonly property string currentFolderPath: Qt.resolvedUrl(Directories.home + "/" + Mem.states.desktop.bg.currentFolder)
    readonly property FolderListModel wallpaperModel: _wallpaperModel
    property var _thumbnailCache: ({})
    property string thumbnailSize: "large"

    Component.onCompleted: refreshFolderDelayed()
    
    onCurrentWallpaperChanged: Noon.playSound("pressed")
    
    onCurrentFolderPathChanged: {
        refreshFolderDelayed()
        if (_thumbnailCache.length <= 0) generateThumbnailsForCurrentFolder()
    }

    Timer {
        id: folderRefreshTimer
        interval: Mem.options.hacks.arbitraryRaceConditionDelay
        onTriggered: _wallpaperModel.folder = currentFolderPath
    }

    Process {
        id: thumbnailGenerator
        running: false
        onStarted: Noon.notify("Generating Thumbnails")
        onExited: exitcode => {
            if (exitcode === 0) Noon.notify("Thumbnails Done")
        }
        stdout: StdioCollector {
            onStreamFinished: _thumbnailCache = {}
        }
    }

    function generateThumbnails(directory, size, workers, recursive) {
        if (thumbnailGenerator.running) return false

        const cleanDir = FileUtils.trimFileProtocol(directory)
        const cmd = ["python3", Directories.wallpaperSwitchScriptPath, "--gen-thumbnails", cleanDir, "--thumb-size", size, "--thumb-workers", (workers || 4).toString()]
        console.log(cmd)
        if (recursive === false) cmd.push("--thumb-no-recursive")

        thumbnailGenerator.command = cmd
        thumbnailGenerator.running = true
        return true
    }

    function getThumbnailPath(fileUrl, size) {
        if (!fileUrl?.startsWith("file://")) return fileUrl

        const thumbSize = size
        const cacheKey = `${fileUrl}_${thumbSize}`

        if (_thumbnailCache[cacheKey]) return _thumbnailCache[cacheKey]

        let cleanPath = FileUtils.trimFileProtocol(fileUrl)
        if (!cleanPath.startsWith("/")) cleanPath = "/" + cleanPath

        const hash = Qt.md5(`file://${cleanPath}`)
        const thumbnailPath = `${FileUtils.trimFileProtocol(Directories.home)}/.cache/thumbnails/${thumbSize}/${hash}.png`

        _thumbnailCache[cacheKey] = `file://${thumbnailPath}`
        return _thumbnailCache[cacheKey]
    }

    function getFileWithThumbnail(index, useThumbnail) {
        const fileUrl = _wallpaperModel.getFile(index)
        return useThumbnail && fileUrl ? getThumbnailPath(fileUrl, thumbnailSize) : fileUrl
    }

    function generateThumbnailsForCurrentFolder(size) {
        generateThumbnails(FileUtils.trimFileProtocol(currentFolderPath), size || thumbnailSize, 4)
    }

    function clearThumbnailCache() {
        _thumbnailCache = {}
    }

    function updateShellMode(mode) {
        Noon.exec(`python3 ${Directories.wallpaperSwitchScriptPath} --noswitch -f --mode '${mode}'`)
    }

    function toggleShellMode() {
        Noon.exec(`python3 ${Directories.wallpaperSwitchScriptPath} --noswitch -f --mode toggle`)
    }

    function updateScheme(selectedMode) {
        Noon.exec(`python3 ${Directories.wallpaperSwitchScriptPath} --noswitch -f --scheme '${selectedMode}'`)
    }

    function refreshFolderDelayed() {
        _wallpaperModel.refreshFolder()
    }

    function resetWallpaper() {
        applyWallpaper("root:///assets/images/default_wallpaper.png")
    }

    function pickAccentColor() {
        Noon.exec(`python3 ${Directories.wallpaperSwitchScriptPath} --pick`)
    }

    function changeAccentColor(color: string) {
        Noon.exec(`python3 ${Directories.wallpaperSwitchScriptPath} --color ${color}`)
    }

    function applyWallpaper(fileUrl) {
        Noon.exec(`python3 ${Directories.wallpaperSwitchScriptPath} --image '${FileUtils.trimFileProtocol(fileUrl)}'`)
    }

    function applyRandomWallpaper() {
        Noon.exec(`python3 ${Directories.wallpaperSwitchScriptPath} --random-no-recursive -R '${FileUtils.trimFileProtocol(currentFolderPath)}'`)
    }

    function shuffleWallpapers() {
        if (_wallpaperModel.count <= 0) return
        
        let indices = []
        for (let i = 0; i < _wallpaperModel.count; i++) {
            indices.push(i)
        }
        
        // Fisher-Yates shuffle
        for (let i = indices.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [indices[i], indices[j]] = [indices[j], indices[i]]
        }
        
        _wallpaperModel.filteredIndices = indices
        _wallpaperModel.isFiltering = true
        _wallpaperModel.modelUpdated()
    }


    function goBack() {
        const currentDir = Mem.states.desktop.bg.currentFolder
        const parentDir = FileUtils.parentDirectory(currentDir)
        if (parentDir && parentDir !== currentDir)
            Mem.states.desktop.bg.currentFolder = parentDir
    }

    FolderListModel {
        id: _wallpaperModel

        property var filteredIndices: []
        property bool isFiltering: false
        property var _preparedCache: ({})

        signal modelUpdated

        folder: currentFolderPath
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.mp4", "*.mov", "*.m4v", "*.avi", "*.mkv", "*.webm"]
        showDirs: false
        showFiles: true
        sortField: FolderListModel.Name
        caseSensitive: true

        onCountChanged: {
            modelUpdated()
            _preparedCache = {}
        }

        onFolderChanged: modelUpdated()

        function refreshFolder() {
            filteredIndices = []
            isFiltering = false
            _preparedCache = {}
            folder = ""
            folderRefreshTimer.start()
        }

        function isVideo(index) {
            const fileUrl = get(index, "fileUrl")
            if (!fileUrl) return false

            const fileName = fileUrl.toString().toLowerCase()
            const videoExtensions = [".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm"]
            return videoExtensions.some(ext => fileName.endsWith(ext))
        }

        function getFile(index) {
            if (isFiltering && index >= 0 && index < filteredIndices.length)
                return get(filteredIndices[index], "fileUrl")
            return get(index, "fileUrl")
        }

        function prepareTargets() {
            _preparedCache = {}
            for (let i = 0; i < count; i++) {
                const fileName = get(i, "fileName").toString()
                _preparedCache[i] = Fuzzy.prepare(fileName)
            }
        }

        function filterWallpapers(query) {
            if (!query || query.trim() === "") {
                clearFilter()
                return
            }

            if (Object.keys(_preparedCache).length === 0) prepareTargets()

            let targets = []
            for (let i = 0; i < count; i++) {
                targets.push({
                    index: i,
                    prepared: _preparedCache[i]
                })
            }

            const results = Fuzzy.go(query, targets, {
                key: 'prepared',
                threshold: -10000,
                limit: 500,
                all: false
            })

            filteredIndices = results.map(result => result.obj.index)
            isFiltering = true
            modelUpdated()
        }

        function clearFilter() {
            filteredIndices = []
            isFiltering = false
            modelUpdated()
        }
    }
}
