import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
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

    BlurImage {
        id: backgroundImage

        z: -1
        anchors.fill: parent
        source: WallpaperService.currentWallpaper
        fillMode: Image.PreserveAspectCrop
        blur: true
        tint: false

        layer.effect: MultiEffect {
            source: backgroundImage
            blurEnabled: true
            blurMax: 40
            blur: 1
        }

        Anim on opacity {
            from: 0
            to: 1
        }

    }

    LockRightArea {
    }

    LockControls {
    }

    LockBeam {
    }

}
