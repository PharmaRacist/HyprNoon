import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    property bool enabled: false

    buttonIcon: "stadia_controller"
    toggled: enabled
    onClicked: {
        enabled = !enabled;
        if (enabled) {
            Noon.exec(`hyprctl --batch "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword input: sensitivity 0;  keyword decoration:rounding 0; keyword general:allow_tearing 1"`);
            Mem.options.statesManager.setState('dashboard.agressiveLoading', false);
            Mem.options.statesManager.setState('dashboard.hoverReveal', false);
        } else {
            Noon.exec("hyprctl reload");
            Mem.options.statesManager.setState('dashboard.hoverReveal', true);
        }
    }
}
