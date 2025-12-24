import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 40

    property var sink: AudioService.sink
    property real maxValue: 1

    MaterialSymbol {
        z: 2
        text: {
            if (volumeSlider.value <= 0.01) return "volume_off"
            if (volumeSlider.value < 0.5) return "volume_down"
            return "volume_up"
        }
        color: Colors.m3.m3onPrimary
        font.pixelSize: Fonts.sizes.huge - 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: volumeSlider.left
        anchors.leftMargin: 10
        fill: 1
        animateChange:true

    }

    StyledSlider {
        id: volumeSlider
        anchors.fill: parent
        from: 0
        to: root.maxValue
        stepSize: 0.01
        z: 1
        highlightColor: Colors.colPrimary
        trackColor: Colors.colSecondaryContainer
        handleColor: Colors.m3.m3onSecondaryContainer
        value: sink?.audio?.volume ?? 0
        onValueChanged: {
            if (sink?.audio) sink.audio.volume = value
        }
    }
}
