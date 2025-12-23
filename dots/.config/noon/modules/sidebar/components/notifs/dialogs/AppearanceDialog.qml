import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

BottomDialog {
    id: root

    collapsedHeight: parent.height * 0.55
    revealOnWheel: false
    enableStagedReveal: false
    onShowChanged: GlobalStates.showAppearanceDialog = show
    finishAction: GlobalStates.showAppearanceDialog = reveal

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Padding.massive
        spacing: Padding.large

        BottomDialogHeader {
            title: "Appearance"
        }

        BottomDialogSeparator {
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Padding.large

            // --- Dark / Light Mode ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: Mem.states.desktop.appearance.mode === "dark" ? "dark_mode" : "light_mode"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Dark Mode")
                    color: Colors.colOnSurfaceVariant
                }

                StyledSwitch {
                    checked: Mem.states.desktop.appearance.mode === "dark"
                    onToggled: {
                        Mem.states.desktop.appearance.mode = checked ? "dark" : "light";
                        WallpaperService.toggleShellMode();
                    }
                }

            }

            // --- Auto Mode ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: "schedule"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Auto Mode (Time-based)")
                    color: Colors.colOnSurfaceVariant
                }

                StyledSwitch {
                    checked: Mem.states.desktop.appearance.autoShellMode
                    onToggled: Mem.states.desktop.appearance.autoShellMode = checked
                }

            }

            BottomDialogSeparator {
            }

            // --- Auto Scheme Selection ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                MaterialSymbol {
                    text: "auto_awesome"
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Auto Color Scheme")
                    color: Colors.colOnSurfaceVariant
                }

                StyledSwitch {
                    checked: Mem.states.desktop.appearance.autoSchemeSelection
                    onToggled: Mem.states.desktop.appearance.autoSchemeSelection = checked
                }

            }

            BottomDialogSeparator {
            }

            // --- Color Intensity (Chroma) ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Padding.small

                    MaterialSymbol {
                        text: "colorize"
                        font.pixelSize: Fonts.sizes.verylarge
                        color: Colors.colOnSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Color Intensity (Chroma)")
                        color: Colors.colOnSurfaceVariant
                    }

                    StyledText {
                        text: Math.round(Mem.states.desktop.Colors.chroma * 100) + "%"
                        color: Colors.colOnSurfaceVariant
                        opacity: 0.7
                    }

                }

                StyledSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 2
                    value: Mem.states.desktop.Colors.chroma
                    onMoved: Mem.states.desktop.Colors.chroma = value
                }

            }

            // --- Tone Adjustment ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Padding.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Padding.small

                    MaterialSymbol {
                        text: "contrast"
                        font.pixelSize: Fonts.sizes.verylarge
                        color: Colors.colOnSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Tone Adjustment")
                        color: Colors.colOnSurfaceVariant
                    }

                    StyledText {
                        text: Math.round(Mem.states.desktop.Colors.tone * 100) + "%"
                        color: Colors.colOnSurfaceVariant
                        opacity: 0.7
                    }

                }

                StyledSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 2
                    value: Mem.states.desktop.Colors.tone
                    onMoved: Mem.states.desktop.Colors.tone = value
                }

            }

            Item {
                Layout.fillHeight: true
            }

        }

        RowLayout {
            Layout.preferredHeight: 50
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            DialogButton {
                buttonText: qsTr("Pick Accent Color")
                onClicked: WallpaperService.pickAccentColor()
            }

            DialogButton {
                buttonText: qsTr("Done")
                onClicked: root.show = false
            }

        }

    }

}
