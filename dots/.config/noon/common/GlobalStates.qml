import QtQuick
import Quickshell
import qs.common.widgets
import qs.services
pragma Singleton

Singleton {
    id: root

    property bool locked: false
    property bool playlistOpen: false
    property bool oskOpen: false
    property bool superHeld: false
    property bool superReleaseMightTrigger: false
    property bool screenLocked: false
    property bool sidebarOpen: true
    property bool sidebarHovered: false
    property bool exposeView: false
    property bool showOsdValues: false
    property bool showBeam: false
    property bool showAppearanceDialog: false
    property bool showCaffaineDialog: false
    property bool showBluetoothDialog: false
    property bool showWifiDialog: false
    property bool showRecordingDialog: false
    property bool showTransparencyDialog: false
    property bool showTempDialog: false
    property bool showKdeConnectDialog: false

    function handle_init() {
        if (Mem.ready) {
            ColorsService.reload();
            ClipboardService.reload();
            AmbientSoundsService.reload();
            KeyringStorage.reload();
            NightLightService.reload();
            Noon.playSound("device_unlocked");
        }
    }

    onSuperReleaseMightTriggerChanged: superHeld.stop()

    Timer {
        id: superHeldTimer

        interval: Mem.options.hacks.superHeldInterval
        onTriggered: superHeld = true
    }

    CustomShortcut {
        name: "superHeld"
        onPressed: superHeldTimer.start()
        onReleased: {
            superHeldTimer.stop();
            superHeld = false;
        }
    }

}
