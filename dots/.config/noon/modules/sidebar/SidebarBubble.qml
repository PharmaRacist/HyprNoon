import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledRect {
    id: root

    property bool show
    property bool rightMode
    property string selectedCategory
    property alias containsMouse: mouse.containsMouse

    visible: width > 0 && !Mem.states.sidebar.behavior.pinned
    enableShadows: true
    radius: Rounding.verylarge
    color: Colors.m3.m3surface
    height: content.implicitHeight + 2 * Padding.large
    width: show ? 55 : 0
    clip: true

    MouseArea {
        id: mouse

        acceptedButtons: Qt.NoButton
        anchors.fill: parent
        propagateComposedEvents: false
        hoverEnabled: true
    }

    ColumnLayout {
        id: content

        spacing: Padding.verysmall

        anchors {
            centerIn: parent
        }

        ColumnLayout {
            visible: root.selectedCategory === "Walls"
            spacing: parent.spacing

            RippleButtonWithIcon {
                materialIcon: "shuffle"
                releaseAction: () => {
                    return WallpaperService.shuffleWallpapers();
                }
            }

            RippleButtonWithIcon {
                materialIcon: "colorize"
                releaseAction: () => {
                    return WallpaperService.pickAccentColor();
                }
            }

            RippleButtonWithIcon {
                materialIcon: "auto_fix_high"
                releaseAction: () => {
                    return WallpaperService.upscaleCurrentWallpaper();
                }
            }

            RippleButtonWithIcon {
                enabled: !RemBgService.isBusy
                materialIcon: RemBgService.isBusy ? "hourglass" : "content_cut"
                releaseAction: () => {
                    return RemBgService.process_current_bg();
                }
            }

            RippleButtonWithIcon {
                materialIcon: "palette"
                releaseAction: () => {
                    return Mem.options.appearance.colors.palatte = !Mem.options.appearance.colors.palatte;
                }
            }

            RippleButtonWithIcon {
                enabled: !WallpaperService._generatingThumbnails
                materialIcon: "restart_alt"
                releaseAction: () => {
                    return WallpaperService.generateThumbnailsForCurrentFolder();
                }
            }

            Separator {
            }

        }

        RippleButtonWithIcon {
            toggled: Mem.states.sidebar.behavior.pinned
            materialIcon: "push_pin"
            releaseAction: () => {
                return Mem.states.sidebar.behavior.pinned = !Mem.states.sidebar.behavior.pinned;
            }
        }

        RippleButtonWithIcon {
            materialIcon: !visualContainer.rightMode && Mem.states.sidebar.behavior.expanded ? "keyboard_double_arrow_left" : "keyboard_double_arrow_right"
            releaseAction: () => {
                return Mem.states.sidebar.behavior.expanded = !Mem.states.sidebar.behavior.expanded;
            }
        }

    }

}
