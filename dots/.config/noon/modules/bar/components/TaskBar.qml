import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root

    property Item lastHoveredButton
    property bool buttonHovered: false
    Layout.fillHeight: true
    implicitWidth: listView.implicitWidth
    StyledListView {
        id: listView
        spacing: 4
        orientation: ListView.Horizontal
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        implicitWidth: contentWidth
        Behavior on implicitWidth {
            FAnim {}
        }

        model: ScriptModel {
            objectProp: "appId"
            values: {
                const pinned = Mem.states.dock.pinnedApps ?? [];
                const values = [];
                const pinnedSet = new Set();

                // Add pinned apps
                for (const appId of pinned) {
                    const id = appId.toLowerCase();
                    pinnedSet.add(id);
                    values.push({
                        appId: id,
                        pinned: true,
                        toplevels: ToplevelManager.toplevels.values.filter(t => t.appId.toLowerCase() === id)
                    });
                }

                // Check if there are unpinned open apps
                const unpinnedApps = ToplevelManager.toplevels.values.filter(t => !pinnedSet.has(t.appId.toLowerCase()));

                if (pinned.length > 0 && unpinnedApps.length > 0) {
                    values.push({
                        appId: "SEPARATOR",
                        pinned: false,
                        toplevels: []
                    });
                }

                // Add unpinned open apps
                const seen = new Set();
                for (const toplevel of unpinnedApps) {
                    const id = toplevel.appId.toLowerCase();
                    if (!seen.has(id)) {
                        seen.add(id);
                        values.push({
                            appId: id,
                            pinned: false,
                            toplevels: unpinnedApps.filter(t => t.appId.toLowerCase() === id)
                        });
                    }
                }

                return values;
            }
        }

        delegate: RippleButton {
            id: root
            implicitWidth: implicitHeight - topInset - bottomInset
            buttonRadius: Rounding.normal
            topInset: Sizes.hyprlandGapsOut - 15
            bottomInset: Sizes.hyprlandGapsOut - 15
            property var appToplevel
            property var appListRoot
            property int lastFocused: -1
            property real iconSize: 30
            property real countDotWidth: 10
            property real countDotHeight: 1
            property bool appIsActive: appToplevel.toplevels.find(t => (t.activated == true)) !== undefined

            property bool isSeparator: appToplevel.appId === "SEPARATOR"
            property bool isVerticalMode: appToplevel.appId === "VERTICALSEPARATOR"
            property var desktopEntry: DesktopEntries.byId(appToplevel.appId)
            enabled: !isSeparator
            width: isSeparator ? 1 : 40 // - topInset - bottomInset
            height: 40

            Loader {
                active: isSeparator
                sourceComponent: isVerticalMode ? horizontalSeparator : separator
                Component {
                    id: horizontalSeparator
                    Separator {
                        anchors {
                            fill: parent
                            right: parent.right
                            left: parent.left
                        }
                    }
                }
                Component {
                    id: separator
                    VerticalSeparator {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            topMargin: 8
                            bottomMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            Loader {
                active: appToplevel.toplevels.length > 0
                sourceComponent: MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        appListRoot.lastHoveredButton = root;
                        appListRoot.buttonHovered = true;
                        lastFocused = appToplevel.toplevels.length - 1;
                    }
                    onExited: {
                        if (appListRoot.lastHoveredButton === root) {
                            appListRoot.buttonHovered = false;
                        }
                    }
                }
            }

            onClicked: {
                if (appToplevel.toplevels.length === 0) {
                    root.desktopEntry?.execute();
                    return;
                }
                lastFocused = (lastFocused + 1) % appToplevel.toplevels.length;
                appToplevel.toplevels[lastFocused].activate();
            }

            middleClickAction: () => {
                root.desktopEntry?.execute();
            }

            contentItem: Loader {
                active: !isSeparator
                sourceComponent: Item {

                    Loader {
                        id: iconImageLoader
                        anchors {
                            centerIn: parent
                        }
                        active: !root.isSeparator
                        sourceComponent: IconImage {
                            source: Noon.iconPath(AppSearch.guessIcon(appToplevel.appId))
                            implicitSize: root.iconSize
                        }
                    }

                    RowLayout {
                        spacing: 3
                        anchors {
                            top: iconImageLoader.bottom
                            topMargin: 2
                            horizontalCenter: parent.horizontalCenter
                        }
                        Repeater {
                            model: Math.min(appToplevel.toplevels.length, 3)
                            delegate: Rectangle {
                                required property int index
                                radius: Rounding.full
                                implicitWidth: (appToplevel.toplevels.length <= 3) ? root.countDotWidth : root.countDotHeight // Circles when too many
                                implicitHeight: root.countDotHeight
                                color: appIsActive ? Colors.colPrimary : ColorUtils.transparentize(Colors.colOnLayer0, 0.4)
                            }
                        }
                    }
                }
            }

            anchors.verticalCenter: parent.verticalCenter
            required property var modelData
            appToplevel: modelData
            appListRoot: root
        }
    }
}
