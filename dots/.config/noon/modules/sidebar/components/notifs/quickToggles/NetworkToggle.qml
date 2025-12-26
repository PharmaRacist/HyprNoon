import qs.modules.common
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    property bool showWifiDialog: false

    hasDialog: true
    buttonName: `${NetworkService.networkName} `
    toggled: NetworkService.networkName.length > 0 && NetworkService.networkName != "lo"
    buttonIcon: NetworkService.materialSymbol
    onRequestDialog: GlobalStates.showWifiDialog = true
    onClicked: NetworkService.toggleWifi()
}
