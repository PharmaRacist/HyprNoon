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
    property string protectionMessage: ""
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    Binding {
        target:GlobalStates
        property: "showOsdValues"
        value:showOsdValues
    }

    function triggerOsd() {
        showOsdValues = true;
        if (!userInteracting)
            osdTimeout.restart();
    }

    function restartTimeoutIfNotInteracting() {
        if (showOsdValues && !userInteracting)
            osdTimeout.restart();
    }

    Timer {
        id: osdTimeout
        interval: Mem.options.osd.timeout
        repeat: false

        onTriggered: {
            if (!userInteracting) {
                root.showOsdValues = false;
                root.protectionMessage = "";
            } else {
                restart();
            }
        }
    }

    Connections {
        target: BrightnessService
        function onBrightnessChanged() {
            showOsdValues = false;
        }
    }

    Connections {
        target: AudioService.sink?.audio ?? null

        function onVolumeChanged() {
            if (AudioService.ready)
                root.triggerOsd();
        }

        function onMutedChanged() {
            if (AudioService.ready)
                root.triggerOsd();
        }
    }

    Connections {
        target: AudioService
        function onSinkProtectionTriggered(reason) {
            root.protectionMessage = reason;
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

            mask: Region { item: content }

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight + Sizes.elevationMargin * 2

            visible: osdLoader.active

            OsdValueIndicator {
                id: content
                anchors.centerIn: parent
                implicitWidth: Sizes.osdWidth
                implicitHeight: Sizes.osdHeight

                value: AudioService.sink?.audio.volume ?? 0
                icon: AudioService.sink?.audio.muted ? "volume_off" : "volume_up"

                onValueModified: {
                    if (AudioService.sink?.audio)
                        AudioService.sink.audio.volume = newValue;
                }

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
        target: "osdVolume"

        function trigger() { root.triggerOsd(); }
        function hide()    { root.showOsdValues = false; }
        function toggle()  { root.showOsdValues = !root.showOsdValues; }
    }
}
