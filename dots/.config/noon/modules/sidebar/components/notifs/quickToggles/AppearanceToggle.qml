import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    toggled: Mem.states.desktop.appearance.mode === "dark"
    buttonIcon: toggled ? "dark_mode" : "light_mode"
    buttonName: toggled ? "Dark" : "Light"
    onClicked: WallpaperService.toggleShellMode()
    hasDialog: true
    onRequestDialog: GlobalStates.showAppearanceDialog = true
}
