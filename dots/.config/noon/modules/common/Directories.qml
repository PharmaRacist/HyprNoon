import Qt.labs.platform
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common.functions
pragma Singleton

Singleton {
    id: root

    // XDG Dirs, with "file://"
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: home + "/.local/state/noon"
    readonly property string cache: home + "/.cache/noon" // StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    readonly property string music: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
    readonly property string documents: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
    readonly property string videos: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
    readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    // Other dirs used by the shell, without "file://"
    // readonly property string shellStates: FileUtils.trimFileProtocol(`${root.state}/noon/`)
    readonly property string shellPath: FileUtils.trimFileProtocol(`${root.config}/noon/`)
    readonly property string shellConfigs: FileUtils.trimFileProtocol(`${root.config}/HyprNoon/`)
    readonly property string assets: FileUtils.trimFileProtocol(`${root.config}/noon/assets`)
    readonly property string scriptsDir: FileUtils.trimFileProtocol(`${root.config}/noon/scripts`)
    readonly property string kittyConfPath: FileUtils.trimFileProtocol(`${root.config}/kitty/`)
    readonly property string hyprlandConfPath: FileUtils.trimFileProtocol(`${root.config}/noon/hyprland/`)
    readonly property string venv: state + "/.venv"
    readonly property string sounds: FileUtils.trimFileProtocol(`${assets}/sounds/`)
    readonly property string aiChats: FileUtils.trimFileProtocol(`${state}/user/generated/ai`)
    readonly property string generatedMaterialThemePath: FileUtils.trimFileProtocol(`${state}/user/generated/colors.json`)
    readonly property string depthCache: FileUtils.trimFileProtocol(`${cache}/user/generated/depth/`)
    readonly property string gowallCache: FileUtils.trimFileProtocol(`${cache}/user/generated/gowall/`)
    readonly property string favicons: FileUtils.trimFileProtocol(`${cache}/media/favicons`)
    readonly property string coverArt: FileUtils.trimFileProtocol(`${cache}/media/coverart`)
    readonly property string latexOutput: FileUtils.trimFileProtocol(`${cache}/media/latex`)
    readonly property string cliphistDecode: FileUtils.trimFileProtocol(`/tmp/noon/media/cliphist`)
    readonly property string notificationsPath: FileUtils.trimFileProtocol(`${cache}/notifications/notifications.json`)
    readonly property string wallpapers: FileUtils.trimFileProtocol(`${pictures}/Wallpapers/`)
    readonly property string gallery: FileUtils.trimFileProtocol(`${pictures}/Gallary/`)
    readonly property string lyrics: FileUtils.trimFileProtocol(`${music}/lyrics`)
    readonly property string notes: FileUtils.trimFileProtocol(`${documents}/Notes/`)
    readonly property string todoPath: FileUtils.trimFileProtocol(`${shellConfigs}/todo.json`)
    readonly property string recordScriptPath: FileUtils.trimFileProtocol(`${scriptsDir}/record_service.sh`)
    readonly property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${scriptsDir}/appearance_service.py`)

    // Cleanup on init
    Component.onCompleted: {
        Noon.execDetached(`mkdir -p '${aiChats}'`);
        Noon.execDetached(`mkdir -p '${lyrics}'`);
        Noon.execDetached(`mkdir -p '${gallery}'`);
        Noon.execDetached(`mkdir -p '${notes}'`);
        Noon.execDetached(`mkdir -p '${favicons}'`);
        Noon.execDetached(`mkdir -p '${coverArt}'`);
        Noon.execDetached(`mkdir -p '${latexOutput}'`);
        Noon.execDetached(`mkdir -p '${cliphistDecode}'`);
        Noon.execDetached(`mkdir -p '${gowallCache}'`);
        Noon.execDetached(`mkdir -p '${depthCache}'`);
    }
}
