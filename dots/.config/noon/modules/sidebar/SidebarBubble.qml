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
    property var bubbles: [{
        "cat": "Walls",
        "bubbles": [{
            "icon": "colorize",
            "enabled": true,
            "action": function() {
                WallpaperService.pickAccentColor();
            }
        }, {
            "icon": "shuffle",
            "enabled": true,
            "action": function() {
                WallpaperService.shuffleWallpapers();
            }
        }, {
            "icon": GowallService.isBusy ? "hourglass" : "auto_fix_high",
            "enabled": !GowallService.isBusy,
            "action": function() {
                GowallService.upscaleCurrentWallpaper();
            }
        }, {
            "enabled": !RemBgService.isBusy,
            "icon": RemBgService.isBusy ? "hourglass" : "content_cut",
            "action": function() {
                RemBgService.process_current_bg();
            }
        }, {
            "icon": WallpaperService._generatingThumbnails ? "hourglass" : "restart_alt",
            "enabled": !WallpaperService._generatingThumbnails,
            "action": function() {
                WallpaperService.generateThumbnailsForCurrentFolder();
            }
        }]
    }, {
        "cat": "API",
        "extraVisibleCondition": Mem.states.sidebar.apis.selectedTab === 0,
        "bubbles": [{
            "icon": "clear_all",
            "action": function() {
                Ai.clearMessages();
            }
        }, {
            "icon": "restart_alt",
            "action": function() {
                Ai.regenerate(Ai.messageIDs.length - 1);
            }
        }, {
            "icon": "save",
            "action": function() {
                Ai.saveChat("lastSession");
            }
        }, {
            "icon": "upload",
            "action": function() {
                Ai.loadChat("lastSession");
            }
        }]
    }, {
        "cat": "History",
        "bubbles": [{
            "icon": "clear_all",
            "action": function() {
                ClipboardService.wipe();
            }
        }]
    }, {
        "cat": "Tasks",
        "bubbles": [{
            "icon": TodoService.SyncState.Offline ? "cloud_off" : TodoService.SyncState.Error ? "error" : "sync",
            "action": function() {
                TodoService.syncWithTodoist();
            }
        }]
    }, {
        "cat": "Beats",
        "bubbles": [{
            "icon": "download",
            "extraVisibleCondition": !BeatsService.isCurrentPlayer(),
            "action": function() {
                BeatsService.downloadCurrentSong();
            }
        }, {
            "icon": "close",
            "extraVisibleCondition": BeatsService.isCurrentPlayer(),
            "action": function() {
                BeatsService.stopPlayer();
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
                            visible: modelData.extraVisibleCondition
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
