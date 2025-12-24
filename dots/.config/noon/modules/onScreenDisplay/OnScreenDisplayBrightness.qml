import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool showOsdValues: false
    property bool userInteracting: false
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property var brightnessMonitor: BrightnessService.getMonitorForScreen(focusedScreen)

    function triggerOsd() {
        showOsdValues = true;
        if (!userInteracting) {
            osdTimeout.restart();
        }
    }

    function restartTimeoutIfNotInteracting() {
        if (!userInteracting && showOsdValues) {
            osdTimeout.restart();
        }
    }

    Binding {
        target: GlobalStates
        property: "showOsdValues"
        value: showOsdValues
    }
    Timer {
        id: osdTimeout
        interval: Mem.options.osd.timeout
        repeat: false
        running: false

        onTriggered: {
            if (!userInteracting) {
                root.showOsdValues = false;
            } else {
                restart();
            }
        }
    }

    Connections {
        target: BrightnessService
        function onBrightnessChanged() {
            if (!root.brightnessMonitor.ready)
                return;
            root.triggerOsd();
        }
    }

    Loader {
        id: osdLoader
        active: showOsdValues

        sourceComponent: StyledPanel {
            id: osdRoot
            name: "osd"

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    osdRoot.screen = root.focusedScreen;
                }
            }

            anchors.bottom: true
            margins: Sizes.elevationMargin * 4

            mask: Region {
                item: content
            }

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight + Sizes.elevationMargin * 2
            visible: osdLoader.active

            OsdValueIndicator {
                id: content
                anchors.centerIn: parent
                implicitWidth: Sizes.osdWidth
                implicitHeight: Sizes.osdHeight
                value: root.brightnessMonitor?.brightness ?? 50
                icon: BrightnessService.iconMaterial

                // If interaction for brightness is added later (e.g. scroll/drag)
                onInteractionStarted: {
                    root.userInteracting = true;
                    osdTimeout.stop();
                }

                onInteractionEnded: {
                    root.userInteracting = false;
                    root.restartTimeoutIfNotInteracting();
                }
            }
        }
    }

    IpcHandler {
        target: "osdBrightness"

        function trigger() {
            root.triggerOsd();
        }

        function hide() {
            showOsdValues = false;
        }

        function toggle() {
            showOsdValues = !showOsdValues;
        }
    }
}
