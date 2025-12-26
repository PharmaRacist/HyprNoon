import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

RippleButton {
    id: root

    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: Mem.options.dock.appearance.iconSize
    property real countDotWidth: 10
    property real countDotHeight: 3
    property bool appIsActive: appToplevel.toplevels.find(t => (t.activated == true)) !== undefined

    property bool isSeparator: appToplevel.appId === "SEPARATOR"
    property var desktopEntry: DesktopEntries.byId(appToplevel.appId)
    enabled: !isSeparator
    implicitHeight: iconSize
    implicitWidth: isSeparator ? 1 : implicitHeight
    Layout.fillHeight: true
    buttonRadius: Rounding.normal

    Loader {
        active: isSeparator
        anchors {
            fill: parent
            topMargin: 6
            bottomMargin: 6
        }
        sourceComponent: DockSeparator {}
    }

    Loader {
        anchors.fill: parent
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
            if (root.desktopEntry) {
                return root.desktopEntry.execute();
            } else {
                return Noon.exec("gtk-launch", [appToplevel.appId]);
            }
            return;
        }
    }

    middleClickAction: () => {
        root.desktopEntry?.execute();
    }
    altAction: () => {
        if (Mem.states.dock.pinnedApps.indexOf(appToplevel.appId) !== -1) {
            Mem.states.dock.pinnedApps = Mem.states.dock.pinnedApps.filter(id => id !== appToplevel.appId);
        } else {
            Mem.states.dock.pinnedApps = Mem.states.dock.pinnedApps.concat([appToplevel.appId]);
        }
    }
    contentItem: Loader {
        active: !isSeparator
        sourceComponent: Item {
            Loader {
                id: iconImageLoader
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                active: !root.isSeparator
                sourceComponent: StyledIconImage {
                    id: iconImage
                    source: Noon.iconPath(root.desktopEntry ? (root.desktopEntry.icon || root.desktopEntry.genericIcon || "applications-system") : appToplevel.appId)
                    implicitSize: root.iconSize - Padding.small
                    implicitWidth: root.iconSize - Padding.small
                    implicitHeight: root.iconSize - Padding.small
                    colorize: Mem.options.appearance.icons.tint
                }
            }

            RowLayout {
                spacing: 1
                height: countDotHeight
                width: countDotWidth * Math.min(appToplevel.toplevels.length, 2)

                anchors {
                    top: iconImageLoader.bottom
                    topMargin: -countDotHeight
                    horizontalCenter: iconImageLoader.horizontalCenter
                }
                Repeater {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    model: Math.min(appToplevel.toplevels.length, 3)
                    delegate: Rectangle {
                        required property int index
                        radius: Rounding.full
                        implicitWidth: (appToplevel.toplevels.length <= 3) ? root.countDotWidth : root.countDotHeight
                        implicitHeight: root.countDotHeight
                        color: appIsActive ? Colors.colPrimary : ColorUtils.transparentize(Colors.colOnLayer0, 0.4)
                        Behavior on implicitWidth {
                            Anim {}
                        }
                        Behavior on color {
                            CAnim {}
                        }
                    }
                }
            }
        }
    }
}
