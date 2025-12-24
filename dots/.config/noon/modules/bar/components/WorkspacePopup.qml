import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

StyledPopup {
    id: popup
    active: HyprlandService.isHyprland && hoverTarget && hoverTarget.containsMouse
    Item {
        id: root
        clip: true
        anchors.fill: parent

        property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
        property var focusedWindow: Hyprland.focusedWindow
        property var toplevel: focusedWindow?.address ? Hyprland.toplevelForAddress(focusedWindow.address) : null
        readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

        property var iconToScreenRatio: 0.13
        // Get appId from the active window via ToplevelManager
        property string windowAppId: (activeWindow?.activated && activeWindow?.appId) ? activeWindow.appId : ""
        property var iconPath: Noon.iconPath(AppSearch.guessIcon(windowAppId))

        implicitHeight: preview.implicitHeight
        implicitWidth: preview.implicitWidth
        visible: preview.hasContent
        Loader {
            active: HyprlandService.isHyprland
            anchors {
                fill: parent
                margins: 9
                topMargin: 3
                bottomMargin: 3
            }

            StyledScreencopyView {
                id: preview
                anchors.fill: parent
                constraintSize: Qt.size(432, 242)
                captureSource: root?.focusedScreen ?? null
                clip: true
                smooth: true
                radius: Rounding.verylarge

                IconImage {
                    id: appIcon
                    property var iconSize: Math.min(preview.width, preview.height) * root.iconToScreenRatio

                    mipmap: true
                    source: root.iconPath
                    width: iconSize
                    height: iconSize
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                        margins: 18
                    }

                    Behavior on width {
                        Anim {}
                    }

                    Behavior on height {
                        Anim {}
                    }
                }
            }
        }
    }
}
