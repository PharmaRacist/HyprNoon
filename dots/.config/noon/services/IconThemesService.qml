import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils
pragma Singleton

// Wrapper for the icon_theme_manager.py
Singleton {
    id: root

    // Properties
    property var availableIconThemes: Mem.states.desktop.icons.availableIconThemes ?? []
    property var availableIconThemeNames: availableIconThemes.map((theme) => {
        return theme.name;
    })
    property var availableIconThemeIds: availableIconThemes.map((theme) => {
        return theme.id;
    })
    property string currentQtIconTheme: Mem.states.desktop.icons.currentIconTheme
    property string currentGtkIconTheme: Mem.states.desktop.icons.currentIconTheme
    property bool isLoading: false
    property bool isInitialized: false

    // Public API
    function refresh() {
        listThemes();
        getCurrentTheme();
    }

    function setIconTheme(themeId) {
        if (!themeId)
            return ;

        setThemeProcess.command = ["python3", `${Directories.scriptsDir}/icons_service.py`, "set", themeId];
        setThemeProcess.running = true;
    }

    // Internal functions
    function listThemes() {
        isLoading = true;
        listThemesProcess.running = true;
    }

    function getCurrentTheme() {
        getCurrentThemeProcess.running = true;
    }

    Component.onCompleted: {
        refresh();
        isInitialized = true;
    }

    // Watch for config changes and apply them
    Connections {
        function onCurrentIconThemeChanged() {
            if (!root.isInitialized)
                return ;

            const newTheme = Mem.states.desktop.icons.currentIconTheme;
            if (newTheme && newTheme !== root.currentQtIconTheme && newTheme !== root.currentGtkIconTheme)
                root.setIconTheme(newTheme);

        }

        target: Mem.states.desktop.icons
    }

    // Process: List all available themes
    Process {
        id: listThemesProcess

        command: ["python3", `${Directories.scriptsDir}/icons_service.py`, "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoading = false;
                try {
                    const themes = JSON.parse(this.text.trim());
                    Mem.states.desktop.icons.availableIconThemes = themes;
                } catch (e) {
                    console.error("IconThemeService: Failed to parse themes list:", e);
                    Mem.states.desktop.icons.availableIconThemes = [];
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim())
                    console.error("IconThemeService: List error:", this.text);

            }
        }

    }

    // Process: Get current theme
    Process {
        id: getCurrentThemeProcess

        command: ["python3", `${Directories.scriptsDir}/icons_service.py`, "get"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const current = JSON.parse(this.text.trim());
                    const qtTheme = current.qt || "";
                    const gtkTheme = current.gtk || "";
                    // Update local properties
                    root.currentQtIconTheme = qtTheme;
                    root.currentGtkIconTheme = gtkTheme;
                    // Update config with the current theme
                    Mem.states.desktop.icons.currentIconTheme = qtTheme || gtkTheme;
                } catch (e) {
                    console.error("IconThemeService: Failed to parse current theme:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim())
                    console.error("IconThemeService: Get error:", this.text);

            }
        }

    }

    // Process: Set icon theme
    Process {
        id: setThemeProcess

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(this.text.trim());
                    if (result.success) {
                        console.log("IconThemeService: Theme set successfully:", result.theme);
                        // Update config immediately with the new theme
                        Mem.states.desktop.icons.currentIconTheme = result.theme;
                        // Refresh to get actual current state from system
                        getCurrentThemeProcess.running = true;
                    } else {
                        console.warn("IconThemeService: Failed to set theme:", result);
                    }
                } catch (e) {
                    console.error("IconThemeService: Failed to parse set result:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim())
                    console.error("IconThemeService: Set error:", this.text);

            }
        }

    }

}
