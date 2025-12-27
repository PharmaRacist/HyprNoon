import Quickshell
import qs.common
import qs.common.widgets
import qs.services

QuickToggleButton {
    id: nightLightButton

    buttonName: "Night Light"
    buttonIcon: "nightlight"
    toggled: Mem.states.services.nightLight.enabled
    onClicked: {
        Mem.states.services.nightLight.enabled = !Mem.states.services.nightLight.enabled;
    }
    onRequestDialog: GlobalStates.showTempDialog = true
    hasDialog: true
}
