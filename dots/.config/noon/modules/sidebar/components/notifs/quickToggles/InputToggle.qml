import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    property bool enabled: false

    buttonIcon: "mouse"
    toggled: enabled
    onClicked: {
        enabled = !enabled;
        if (enabled)
            Noon.exec(`hyprctl keyword input:force_no_accel ${enabled ? 1 : 0}`);
        else
            Noon.exec(`hyprctl keyword input:force_no_accel ${enabled ? 1 : 0}`);
    }
}
