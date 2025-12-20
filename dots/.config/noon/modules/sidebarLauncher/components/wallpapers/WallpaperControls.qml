import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.store

StyledRect {
    id: root

    property var themes: ThemeData.themes ?? []
    property var modes: ThemeData.modes ?? []
    property var palettes: ThemeData.availableColorPalettes ?? []
    property bool expanded: false
    property string currentTheme: "dracula"
    property string currentMode: Mem.states.desktop.appearance.scheme
    property int comboWidth: 160

    signal browserOpened()

    radius: Rounding.verylarge
    color: Colors.m3.m3surfaceContainerLowest
    implicitWidth: content.implicitWidth + 36
    implicitHeight: content.implicitHeight + 36
    enableShadows: true
    enableBorders: true

    anchors {
        bottom: parent.bottom
        margins: Sizes.elevationMargin
        horizontalCenter: parent.horizontalCenter
    }

    ColumnLayout {
        id: content

        anchors.centerIn: parent
        spacing: 8

        GridLayout {
            id: gridContent

            Layout.fillWidth: true
            rowSpacing: 8
            columnSpacing: 10
            columns: root.expanded ? 7 : 3

            // === Theme Combo ===
            StyledComboBox {
                id: themeCombo

                Layout.preferredHeight: 40
                Layout.preferredWidth: root.comboWidth
                model: root.themes
                textRole: "name"
                valueRole: "value"
                currentIndex: {
                    for (let i = 0; i < root.themes.length; i++) {
                        if (root.themes[i].value === root.currentTheme)
                            return i;

                    }
                    return 0;
                }
                onActivated: (index) => {
                    if (index >= 0 && index < root.themes.length)
                        GowallService.convertTheme(root.themes[index].value);

                }
            }

            // === Depth Button ===
            RippleButton {
                id: depthBtn

                enabled: !RemBgService.isBusy
                implicitHeight: 40
                implicitWidth: 40
                onClicked: RemBgService.process_current_bg()

                StyledToolTip {
                    content: RemBgService.isBusy ? "Processing..." : "Create Depth Wallpaper"
                }

                contentItem: MaterialSymbol {
                    text: RemBgService.isBusy ? "hourglass" : "content_cut"
                    font.pixelSize: 24
                }

            }

            // === Toggle Preset Button ===
            RippleButton {
                id: togglePresetBtn

                implicitHeight: 40
                implicitWidth: 40
                onClicked: Mem.options.appearance.colors.palatte = !Mem.options.appearance.colors.palatte

                StyledToolTip {
                    content: "Toggle theme presets"
                }

                contentItem: MaterialSymbol {
                    text: "palette"
                    font.pixelSize: 24
                }

            }

            // === Mode Combo ===
            StyledComboBox {
                id: modeCombo

                Layout.preferredWidth: root.comboWidth
                model: root.modes
                textRole: "name"
                valueRole: "value"
                currentIndex: {
                    for (let i = 0; i < root.modes.length; i++) {
                        if (root.modes[i].value === root.currentMode)
                            return i;

                    }
                    return 0;
                }
                onActivated: (index) => {
                    if (index >= 0 && index < root.modes.length)
                        WallpaperService.updateScheme(root.modes[index].value);

                }
            }

            // === Accent Color Button ===
            RippleButton {
                id: accentColorBtn

                implicitHeight: 40
                implicitWidth: 40
                onClicked: WallpaperService.pickAccentColor()

                StyledToolTip {
                    content: "Set Custom Accent Color"
                }

                contentItem: MaterialSymbol {
                    text: "colorize"
                    font.pixelSize: 24
                }

            }

            // === Upscale Button ===
            RippleButton {
                id: upscaleBtn

                enabled: !GowallService.isBusy
                implicitHeight: 40
                implicitWidth: 40
                onClicked: GowallService.upscaleCurrentWallpaper()

                StyledToolTip {
                    content: "Upscale current wallpaper (Permanent)"
                }

                contentItem: MaterialSymbol {
                    text: "auto_fix_high"
                    font.pixelSize: 24
                }

            }

            // === Palette Combo ===
            StyledComboBox {
                id: paletteCombo

                visible: Mem.options.appearance.colors.palatte
                Layout.preferredWidth: root.comboWidth
                model: root.palettes
                textRole: "name"
                valueRole: "name"
                displayText: Mem.options.appearance.colors.palatteName
                onActivated: (index) => {
                    if (index >= 0 && index < root.palettes.length)
                        Mem.options.appearance.colors.palatteName = root.palettes[index];

                }
            }

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 8

            StyledTextField {
                Layout.preferredHeight: 40
                Layout.fillWidth: true
                implicitWidth: 0
                text: Mem.states.desktop.bg.currentFolder
                placeholderText: "Wallpaper folder path..."
                placeholderTextColor: color
                color: Colors.colOnLayer1
                Keys.onEscapePressed: focus = false
                onAccepted: Mem.states.desktop.bg.currentFolder = text
            }

            RippleButton {
                Layout.preferredHeight: 40
                Layout.preferredWidth: pressed ? 60 : 40
                releaseAction: () => {
                    return WallpaperService.generateThumbnailsForCurrentFolder();
                }

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    font.pixelSize: 25
                    text: "restart_alt"
                }

            }

            RippleButton {
                visible: false
                Layout.preferredHeight: 40
                Layout.preferredWidth: pressed ? 60 : 40
                releaseAction: () => {
                    return WallpaperService.goBack();
                }

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    font.pixelSize: 25
                    text: "keyboard_arrow_up"
                }

            }

        }

    }

    Behavior on implicitHeight {
        Anim {
        }

    }

    Behavior on implicitWidth {
        Anim {
        }

    }

}
