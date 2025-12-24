import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

MouseArea {
    id: root
    property bool verticalMode: false
    property bool expanded: false
    property bool userInteracting: false
    property bool autoRevealed: false
    property int lastScrollX: 0
    property int lastScrollY: 0
    property bool trackingScroll: false
    hoverEnabled: true
    implicitHeight: verticalMode ? content.implicitHeight + 5 : BarData.currentBarExclusiveSize
    implicitWidth: verticalMode ? BarData.currentBarExclusiveSize : content.implicitWidth

    Timer {
        id: autoHideTimer
        interval: Mem.options.osd.timeout
        repeat: false
        running: false
        onTriggered: {
            if (!root.userInteracting && root.autoRevealed) {
                root.expanded = false
                root.autoRevealed = false
            } else {
                restart()
            }
        }
    }

    function triggerAutoReveal() {
        root.expanded = true
        root.autoRevealed = true
        if (!userInteracting) {
            autoHideTimer.restart()
        }
    }

    function restartTimeoutIfNotInteracting() {
        if (!userInteracting && autoRevealed) {
            autoHideTimer.restart()
        }
    }

    onContainsMouseChanged: {
        userInteracting = containsMouse
        if (containsMouse) {
            autoHideTimer.stop()
        } else {
            restartTimeoutIfNotInteracting()
        }
    }

    onClicked: expanded = !expanded

    WheelHandler {
        onWheel: (event) => {
            const currentVolume = AudioService.value
            const step = currentVolume < 0.1 ? 0.01 : 0.02
            if (event.angleDelta.y < 0)
                AudioService.sink.audio.volume -= step
            else if (event.angleDelta.y > 0)
                AudioService.sink.audio.volume = Math.min(1, AudioService.sink.audio.volume + step)
            root.lastScrollX = event.x
            root.lastScrollY = event.y
            root.trackingScroll = true
            root.userInteracting = true
            root.triggerAutoReveal()
            autoHideTimer.stop()
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    Connections {
        target: AudioService.sink?.audio ?? null
        function onVolumeChanged() {
            if (!AudioService.ready) return
            root.triggerAutoReveal()
        }
        function onMutedChanged() {
            if (!AudioService.ready) return
            root.triggerAutoReveal()
        }
    }

    GridLayout {
        id: content
        anchors.fill: parent
        rows: verticalMode ? 2 : 1
        columns: verticalMode ? 1 : 2

        Revealer {
            id: revealer
            reveal: root.containsMouse || root.expanded
            vertical: root.verticalMode
            Layout.alignment: Qt.AlignHCenter

                ClippedProgressBar {
                visible: parent.reveal
                anchors.centerIn: parent

                    vertical: root.verticalMode
                    value: AudioService.sink?.audio.volume ?? 0
                    valueBarHeight: 50
                    valueBarWidth: (BarData.currentBarExclusiveSize * 0.55) * BarData.barPadding
                    text: ""
                    font {
                        pixelSize: 13
                        weight: Font.DemiBold
                    }
                    Behavior on value {
                        Anim {}
                    }
                }

        }
                MaterialSymbol {
                    fill:1
                    font.family: revealer.reveal ?Fonts.family.main  :Fonts.family.iconMaterial
                    text:revealer.reveal ?  Math.round(100 * AudioService.sink?.audio.volume) : AudioService.sink?.audio.muted ? "volume_off" : "volume_up"
                    font.pixelSize: revealer.reveal ? verticalMode ? Fonts.sizes.small : Fonts.sizes.normal : BarData.currentBarExclusiveSize / 2
                    color: Colors.colOnLayer1
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
               }


    }
}
