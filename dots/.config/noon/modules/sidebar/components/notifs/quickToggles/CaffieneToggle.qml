import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    id: root

    hasDialog: true
    onRequestDialog: GlobalStates.showCaffaineDialog = true
    showButtonName: false
    toggled: IdleService.inhibited
    buttonIcon: "coffee"
    buttonName: toggled ? "Awake" : "Sleepy"
    onClicked: IdleService.toggleInhibit()
    altAction: () => {
        return GlobalStates.showCaffaineDialog = true;
    }
}
