import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ColumnLayout {
    id: controls

    spacing: Padding.normal

    anchors {
        left: parent.left
        bottom: parent.bottom
        leftMargin: -75
        margins: Padding.huge
    }

    RippleButtonWithIcon {
        materialIcon: "power_settings_new"
        implicitSize: 72
        releaseAction: () => {
            Noon.execDetached("systemctl poweroff");
        }
    }

    RippleButtonWithIcon {
        materialIcon: "restart_alt"
        implicitSize: 72
        releaseAction: () => {
            Noon.execDetached("reboot");
        }
    }

    RippleButtonWithIcon {
        materialIcon: "dark_mode"
        implicitSize: 72
        releaseAction: () => {
            Noon.execDetached("systemctl suspend");
        }
    }

    Anim on anchors.leftMargin {
        from: -75
        to: anchors.margins
    }

}
