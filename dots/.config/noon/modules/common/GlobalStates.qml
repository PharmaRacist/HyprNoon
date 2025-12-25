pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

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
    property bool showOsdValues:false
    property bool showBeam:false
    property string beamState:""
    property bool showAppearanceDialog: false
    property bool showCaffaineDialog: false
    property bool showBluetoothDialog: false
    property bool showWifiDialog: false
    property bool showRecordingDialog: false
    property bool showTransparencyDialog: false
    property bool showTempDialog: false
    property bool showKdeConnectDialog: false
    
    onSuperReleaseMightTriggerChanged: superHeld.stop()
    Timer {
        id: superHeldTimer
        interval: Mem.options.hacks.superHeldInterval
        repeat: false
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
    function handle_init() {
        ColorsService.themeFileView.reload();
        NightLightService.applyTemperature();
        KeyringStorage.fetchKeyringData();
        ClipboardService.refresh()
        Noon.playSound("device_unlocked");
    }
}
