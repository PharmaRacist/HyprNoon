import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: thumbContainer

    property var hWin: null
    property var wHandle:null

    property string winKey: ''

    property real thumbW: -1
    property real thumbH: -1

    property var clientInfo: {}
    property bool hovered: false

    property real targetX: -1000
    property real targetY: -1000

    property bool moveCursorToActiveWindow: false

    width: thumbW
    height: thumbH

    x: 0
    y: 0

    visible: !!wHandle

    Anim {
        id: animX
        target: thumbContainer
        property: "x"
    }
    Anim {
        id: animY
        target: thumbContainer
        property: "y"
    }

    function updateLastPos() {
        var lp = root.lastPositions || ({})
        var prev = lp[winKey] || ({})
        prev.x = x
        prev.y = y
        lp[winKey] = prev
        root.lastPositions = lp
    }

    onTargetXChanged: {
        if (!root.animateWindows) {
            x = targetX
            updateLastPos()
            return
        }

        var lp = root.lastPositions || ({})
        var prev = lp[winKey]
        var startX = (prev && prev.x !== undefined) ? prev.x : targetX

        if (startX === targetX) {
            x = targetX
            updateLastPos()
            return
        }

        animX.stop()
        animX.from = startX
        animX.to = targetX
        animX.start()
    }

    onTargetYChanged: {
        if (!root.animateWindows) {
            y = targetY
            updateLastPos()
            return
        }

        var lp = root.lastPositions || ({})
        var prev = lp[winKey]
        var startY = (prev && prev.y !== undefined) ? prev.y : targetY

        if (startY === targetY) {
            y = targetY
            updateLastPos()
            return
        }

        animY.stop()
        animY.from = startY
        animY.to = targetY
        animY.start()
    }

    onXChanged: updateLastPos()
    onYChanged: updateLastPos()

    Component.onCompleted: {
        if (!root.animateWindows) {
            x = targetX
            y = targetY
            updateLastPos()
        }
    }

    function activateWindow() {
        if (!hWin) return

        var targetIsSpecial = (hWin?.workspace ?? 0) < 0 || (hWin?.workspace?.name ?? "").startsWith("special")

        if (root.specialActive && !targetIsSpecial) {
            Hyprland.dispatch("togglespecialworkspace")
        }

        if (hWin.workspace) {
            hWin.workspace.activate()
        }

        root.toggleExpose()
        Hyprland.dispatch("focuswindow address:0x" + hWin.address)
        Hyprland.dispatch("alterzorder top")
        if (thumbContainer.moveCursorToActiveWindow) {
          var cx = clientInfo.at[0] + (clientInfo.size[0]/2)
          var cy = clientInfo.at[1] + (clientInfo.size[1]/2)
        Hyprland.dispatch("movecursor " + cx + " " + cy)

        }
    }

    function closeWindow() {
        if (!hWin) return
        Hyprland.dispatch("closewindow address:0x" + hWin.address)
    }

    function refreshThumb() {
        if (thumbLoader.item) {
            thumbLoader.item.captureFrame()
        }
    }

    Item {
        id: card
        anchors.fill: parent

        scale: thumbContainer.hovered ? 1.05 : 0.95
        transformOrigin: Item.Center

        Behavior on scale {
            Anim { }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

            onEntered: {
                exposeArea.currentIndex = index
            }
            onClicked: event => {
                exposeArea.currentIndex = index

                if (event.button === Qt.LeftButton) {
                    thumbContainer.activateWindow()
                }
                if (event.button === Qt.MiddleButton) {
                    thumbContainer.closeWindow()
                }
            }
        }

        RectangularShadow {
            anchors.fill: parent
            radius: Rounding.verylarge
            blur: 24
            spread: 10
            color: "#55000000"
            cached: true
        }

        Loader {
            id: thumbLoader
            anchors.fill: parent
            active: root.isActive && !!thumbContainer.wHandle
            sourceComponent: ScreencopyView {
                id: thumb
                anchors.fill: parent
                captureSource: thumbContainer.wHandle
                live: root.liveCapture && root.isActive
                paintCursor: false
                visible: root.isActive && thumbContainer.wHandle && hasContent

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: thumb.width
                        height: thumb.height
                        radius: Rounding.verylarge
                    }
                }

                StyledRect {
                    anchors.fill: parent
                    border.width : thumbContainer.hovered ? 3 : 1
                    border.color : thumbContainer.hovered ? Colors.colPrimary : Colors.colOutline
                    color: thumbContainer.hovered ? "transparent": "#33000000"
                    radius: Rounding.verylarge
                }
            }
        }

        StyledRect {
            id: badge
            z: 100
            width: Math.min(titleText.implicitWidth + 24, thumbContainer.thumbW * 0.75)
            height: titleText.implicitHeight + 12

            x: (card.width - width) / 2
            y: card.height - height - (card.height * 0.08)

            radius: Rounding.normal
            color: thumbContainer.hovered ? Colors.colLayer0 : Colors.colLayer0Hover
            enableBorders:true


            Text {
                id: titleText
                anchors.centerIn: parent
                width: parent.width - 16
                text: hWin.title
                color: Colors.colOnLayer0
                font.pixelSize: thumbContainer.hovered ? 13 : 12
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
