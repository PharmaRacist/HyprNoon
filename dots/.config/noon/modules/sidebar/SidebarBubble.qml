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
    property var bubbles: [{
        "cat": "Walls",
        "bubbles": [{
            "key": "pickColor",
            "icon": "colorize",
            "enabled": true,
            "action": function() {
                WallpaperService.pickAccentColor();
            }
        }, {
            "key": "shuffle",
            "icon": "shuffle",
            "enabled": true,
            "action": function() {
                WallpaperService.shuffleWallpapers();
            }
        }, {
            "key": "upscale",
            "icon": GowallService.isBusy ? "hourglass" : "auto_fix_high",
            "enabled": !GowallService.isBusy,
            "action": function() {
                GowallService.upscaleCurrentWallpaper();
            }
        }, {
            "key": "depthWall",
            "enabled": !RemBgService.isBusy,
            "icon": RemBgService.isBusy ? "hourglass" : "content_cut",
            "action": function() {
                RemBgService.process_current_bg();
            }
        }, {
            "key": "cache",
            "icon": WallpaperService._generatingThumbnails ? "hourglass" : "restart_alt",
            "enabled": !WallpaperService._generatingThumbnails,
            "action": function() {
                WallpaperService.generateThumbnailsForCurrentFolder();
            }
        }]
    }, {
        "cat": "API",
        "bubbles": [{
            "key": "clear",
            "icon": "clear_all",
            "action": function() {
                Ai.clearMessages();
            }
        }, {
            "key": "regenerate",
            "icon": "restart_alt",
            "action": function() {
                Ai.regenerate(Ai.messageIDs.length - 1);
            }
        }, {
            "key": "save",
            "icon": "save",
            "action": function() {
                Ai.saveChat("lastSession");
            }
        }, {
            "key": "load",
            "icon": "upload",
            "action": function() {
                Ai.loadChat("lastSession");
            }
        }]
    }, {
        "cat": "History",
        "bubbles": [{
            "key": "clear_history",
            "icon": "clear_all",
            "action": function() {
                ClipboardService.wipe();
            }
        }]
    }]

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
        // RippleButtonWithIcon {
        //     toggled: Mem.states.sidebar.behavior.pinned
        //     materialIcon: "push_pin"
        //     releaseAction: () => {
        //         Mem.states.sidebar.behavior.pinned = !Mem.states.sidebar.behavior.pinned;
        //     }
        // }

        id: content

        spacing: Padding.verysmall
        anchors.centerIn: parent

        Repeater {
            model: root.bubbles

            ColumnLayout {
                spacing: parent.spacing
                visible: modelData.cat === root.selectedCategory

                ColumnLayout {
                    spacing: parent.spacing

                    Repeater {
                        model: modelData.bubbles

                        RippleButtonWithIcon {
                            Layout.fillWidth: true
                            enabled: modelData.enabled !== undefined ? modelData.enabled : true
                            materialIcon: modelData.icon
                            releaseAction: modelData.action
                        }

                    }

                }

                Separator {
                    visible: modelData.cat === root.selectedCategory
                }

            }

        }

        RippleButtonWithIcon {
            materialIcon: !root.rightMode && Mem.states.sidebar.behavior.expanded ? "keyboard_double_arrow_left" : "keyboard_double_arrow_right"
            releaseAction: () => {
                Mem.states.sidebar.behavior.expanded = !Mem.states.sidebar.behavior.expanded;
            }
        }

    }

}
