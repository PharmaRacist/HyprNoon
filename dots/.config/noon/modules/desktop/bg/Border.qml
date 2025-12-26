import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets

StyledPanel {
    id: root

    property int frameThickness: Sizes.frameThickness

    name: "border"
    color: "transparent"
    visible: true
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        bottom: true
        right: true
    }
    // Main container

    Item {
        id: container

        anchors.fill: parent

        // Inner glow using RectangularGlow approach
        Rectangle {
            id: glowSource

            anchors.fill: parent
            color: "transparent"
            radius: Rounding.verylarge

            Rectangle {
                id: glowRect

                anchors.fill: parent
                radius: Rounding.verylarge
                color: "transparent"
                border.width: 10
                border.color: Colors.m3.m3surface
                opacity: 1
                layer.enabled: true

                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1
                    blurMax: 60
                    blurMultiplier: 1
                }

            }

        }

        // Background with masked border effect
        Rectangle {
            anchors.fill: parent
            color: Colors.colLayer0
            layer.enabled: true

            layer.effect: MultiEffect {
                maskSource: maskLayer
                maskEnabled: true
                maskInverted: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

        }

        // Mask layer (invisible, used for effect)
        Item {
            id: maskLayer

            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                id: innerMask

                radius: Rounding.verylarge

                anchors {
                    fill: parent
                    // margins: root.frameThickness
                    leftMargin: Mem.options.bar.enabled && Mem.options.bar.behavior.position === "left" ? 0 : root.frameThickness
                    rightMargin: Mem.options.bar.enabled && Mem.options.bar.behavior.position === "right" ? 0 : root.frameThickness
                    topMargin: Mem.options.bar.enabled && Mem.options.bar.behavior.position === "top" ? 0 : root.frameThickness
                    bottomMargin: Mem.options.bar.enabled && Mem.options.bar.behavior.position === "bottom" ? 0 : root.frameThickness
                }

            }

        }

    }
    // Mask configuration for border effect

    mask: Region {
        item: container
        intersection: Intersection.Xor
    }

}
