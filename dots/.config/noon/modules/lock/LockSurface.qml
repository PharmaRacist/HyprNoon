import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.desktop.bg
import qs.services
import qs.store

Item {
    id: root

    required property LockContext context
    property alias blurredArt: backgroundImage

    Image {
        id: backgroundImage

        z: -1
        anchors.fill: parent
        source: WallpaperService.currentWallpaper
        fillMode: Image.PreserveAspectCrop

        Anim on opacity {
            from: 0
            to: 1
        }

    }

    LockQuotes {
    }

    LockContentArea {
    }

    LockControls {
    }

    LockBeam {
    }

}
