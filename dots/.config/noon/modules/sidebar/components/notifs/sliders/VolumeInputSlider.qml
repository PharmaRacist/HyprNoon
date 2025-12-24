import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    visible:Mem.options.sidebar.appearance.showVolumeInputSlider ?? false
    Layout.fillWidth: true
    Layout.preferredHeight: 40

    property var source: AudioService.source
    property real maxValue: 1

    MaterialSymbol {
        z: 2
        text: {
            if (volumeSlider.value <= 0.01) return "mic_off"
            if (volumeSlider.value < 0.5) return "mic"
            return "mic"
        }
        animateChange:true
        color: Colors.m3.m3onPrimary
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
        to: root.maxValue
        stepSize: 0.01
        z: 1
        highlightColor: Colors.colPrimary
        trackColor: Colors.colSecondaryContainer
        handleColor: Colors.m3.m3onSecondaryContainer
        value: source?.audio?.volume ?? 0
        onValueChanged: {
            if (source?.audio) source.audio.volume = value
        }
    }
}
