// Simple Gowall Wrapper for upscale / scheme processing

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.store
pragma Singleton

Singleton {
    id: root

    property bool isBusy: upscaleProc.running || themeProc.running
    property string inputPath: FileUtils.trimFileProtocol(Mem.states.desktop.bg.currentBg)
    property string current_processed_wall: Directories.gowallCache + Qt.md5(inputPath) + ".png"
    property string upscale_output: FileUtils.trimFileExt(inputPath) + "_upscaled.png"

    function upscaleCurrentWallpaper() {
        upscaleProc.running = true;
        upscaleProc.command = ["gowall", "upscale", inputPath, "--output", upscale_output];
    }

    function convertTheme(themeName) {
        themeProc.command = ["gowall", "convert", "-t", themeName, inputPath, "--output", root.current_processed_wall];
        themeProc.running = true;
    }

    onIsBusyChanged: {
        if (upscaleProc.exited)
            WallpaperService.applyWallpaper(Qt.resolvedUrl(upscale_output));

        if (themeProc.exited)
            WallpaperService.applyWallpaper(Qt.resolvedUrl(current_processed_wall));

    }

    Process {
        id: themeProc

        onExited: (exitCode) => {
            if (exitCode === 0)
                WallpaperService.applyWallpaper(Qt.resolvedUrl(current_processed_wall));

        }
    }

    Process {
        id: upscaleProc

        onExited: (exitCode) => {
            if (exitCode === 0)
                WallpaperService.applyWallpaper(Qt.resolvedUrl(upscale_output));

        }
    }

}
