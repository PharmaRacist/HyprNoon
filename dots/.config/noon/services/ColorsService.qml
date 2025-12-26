import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils
import qs.store
pragma Singleton

Singleton {
    id: root

    property string filePath: currentThemePreset !== "auto" ? 'root:/store/colorPresets/' + currentThemePreset + '.json' : Directories.generatedMaterialThemePath
    property string currentThemePreset: Mem.options.appearance.colors.palatteName
    property var customColors: ({
    })

    function applyColors(fileContent) {
        var json = JSON.parse(fileContent);
        var colors = Colors.m3;
        var key, camelCase, m3Key;
        for (key in json) {
            camelCase = key.replace(/_([a-z])/g, function(g) {
                return g[1].toUpperCase();
            });
            m3Key = 'm3' + camelCase;
            colors[m3Key] = customColors.hasOwnProperty(key) ? customColors[key] : json[key];
        }
        for (key in customColors) {
            if (!json.hasOwnProperty(key)) {
                camelCase = key.replace(/_([a-z])/g, function(g) {
                    return g[1].toUpperCase();
                });
                colors['m3' + camelCase] = customColors[key];
            }
        }
        WallpaperService.changeAccentColor(colors.m3primaryFixed);
        colors.darkmode = (colors.m3background.hslLightness < 0.5);
    }

    function relaod() {
        themeFileView.reload();
    }

    Timer {
        id: delayedFileRead

        interval: 50
        onTriggered: root.applyColors(themeFileView.text())
    }

    FileView {
        id: themeFileView

        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            reload();
            delayedFileRead.restart();
        }
        onLoadedChanged: {
            if (loaded)
                delayedFileRead.restart();

        }
    }

}
