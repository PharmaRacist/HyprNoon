//@ pragma UseQApplication
//@ pragma RespectSystemStyle
//@ pragma Env QT_AUTO_SCREEN_SCALE_FACTOR=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.modules.view
import qs.modules.bar
import qs.modules.desktop.bg
import qs.modules.common
import qs.modules.common.utils
import qs.modules.dock
import qs.modules.lock
import qs.modules.notificationPopup
import qs.modules.onScreenDisplay
import qs.modules.sidebar
import qs.modules.beam

ShellRoot {
    Component.onCompleted:GlobalStates.handle_init()

    WidgetLoader {
        enabled: Mem.options.desktop.bg.useQs && Mem.states.desktop.bg.currentBg.length > 1 && !ToplevelManager?.activeToplevel?.fullscreen && !Mem.states.desktop.bg.isLive
        Bg {}
    }

    WidgetLoader {
        enabled: Mem.options.desktop.bg.borderMultiplier > 0
        Border {}
    }

    WidgetLoader {
        enabled: true
        Sidebar {}
    }

    WidgetLoader {
        enabled: true
        NotificationPopup {}
    }

    WidgetLoader {
        enabled: Mem.options.dock.enabled
        Dock {}
    }
    WidgetLoader {
        enabled: Mem.options.desktop.lock.enabled
        Lock {}
    }
    WidgetLoader {
        enabled: Mem.options.bar.enabled
        Bar {}
    }
    WidgetLoader {
        enabled: Mem.options.desktop.screenCorners > 0 ?? false
        ScreenCorners {}
    }
    WidgetLoader {
        enabled: Mem.options.osd.enabled
        OSDs {}
    }
    WidgetLoader {
        Hyprview {}
    }
    WidgetLoader {
        Beam {}
    }
    WidgetLoader {
        IPC {}
    }
}
