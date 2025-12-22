import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 40
    width: 200
    height: 40

    property var sink: Audio.sink
    property var audioReady: Audio.ready && !!sink?.audio
    property real maxValue: 1
    property bool pressed: false
    property color primaryColor: Colors.m3.m3onPrimary
    property color highlightColor: Colors.colPrimary
    property color trackColor: Colors.colSecondaryContainer
    property color handleColor: Colors.m3.m3onSecondaryContainer

    MaterialSymbol {
        z: 2
        text: {
            if (volumeSlider.value <= 0.01)
                return "volume_off";
            else if (volumeSlider.value < 0.5)
                return "volume_down";
            else
                return "volume_up";
        }
        color: primaryColor
        font.pixelSize: Fonts.sizes.huge - 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: volumeSlider.left
        anchors.leftMargin: 10
        fill: 1
    }

    StyledSlider {
        id: volumeSlider
        anchors.fill: parent
        from: 0
        to: maxValue
        stepSize: 0.01
        z: 1
        highlightColor: root.highlightColor
        trackColor: root.trackColor
        handleColor: root.handleColor

        // Initial value fallback to 0 if audio is not ready
        value: sink?.audio?.volume ?? 0

        function onVolumeChanged() {
            if (sink?.audio && Math.abs(volumeSlider.value - sink.audio.volume) > 0.005) {
                volumeSlider.value = sink.audio.volume;
            }
        }
        onValueChanged: {
            sink.audio.volume = value
        }
    }
}
