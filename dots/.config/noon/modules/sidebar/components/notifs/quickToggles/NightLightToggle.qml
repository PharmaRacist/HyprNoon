import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    id: nightLightButton

    buttonName: "Night Light"
    buttonIcon: "nightlight"
    toggled: NightLightService.enabled
    onClicked: NightLightService.toggle()
    onRequestDialog: GlobalStates.showTempDialog = true
    hasDialog: true
}
