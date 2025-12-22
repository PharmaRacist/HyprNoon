import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 40

    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)
    StyledSlider {
        id: brightnessSlider
        anchors.fill: parent
        from: 0
        to: 1
        stepSize: 0.01

        // Initialize value
        value: brightnessMonitor?.brightness ?? 0

        onValueChanged: {
            if ( brightnessMonitor) {
                brightnessMonitor.setBrightness(value);
            }
        }

        Connections {
            target: brightnessMonitor ? brightnessMonitor : null
            ignoreUnknownSignals: true

            function onBrightnessChanged() {
                if ( brightnessMonitor)
                    brightnessSlider.value = brightnessMonitor.brightness;
            }
        }
    }

    MaterialSymbol {
        z: 2
        text: brightnessSlider.value > 0.5 ? "light_mode" : "dark_mode"
        color: Colors.m3.m3onPrimary
        font.pixelSize: Fonts.sizes.huge - 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: brightnessSlider.left
        anchors.leftMargin: 10
        fill: 1
        animateChange:true

    }
}
