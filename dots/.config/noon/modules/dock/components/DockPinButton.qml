import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.dock
import qs.services

Item {
    id: root

    property bool pinned
    property bool hovered: false
    property int radius: bg.radius

    implicitWidth: implicitHeight * 2
    implicitHeight: bg.implicitHeight

    StyledRect {
        implicitHeight: parent.implicitHeight
        width: hovered ? implicitHeight * 2 : implicitHeight
        anchors.right: parent.right
        border.color: Colors.colOutline
        color: Colors.colLayer0
        clip: true
        radius: parent.radius
        enableShadows: true

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: Mem.states.dock.pinned = !Mem.states.dock.pinned
            onEntered: parent.parent.hovered = true
            onExited: parent.parent.hovered = false
        }

        Item {
            anchors.margins: Padding.normal
            anchors.fill: parent

            RippleButton {
                id: pinButton

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: height
                buttonRadius: parent.parent.radius - Padding.normal
                hoverEnabled: false
                toggled: root.pinned
                onPressed: Mem.options.dock.pinned = !toggled

                StyledIconImage {
                    id: distroIcon

                    colorize: true
                    smooth: true
                    anchors.centerIn: parent
                    width: parent.width / 2
                    height: parent.height / 2
                    source: Qt.resolvedUrl(Quickshell.shellPath("assets/icons")) + "/" + SysInfoService.distroIcon
                }

            }

            Revealer {
                id: revealer

                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Padding.normal
                anchors.left: pinButton.right
                reveal: root.hovered

                StyledText {
                    visible: parent.reveal
                    color: Colors.colOnLayer1
                    text: "Pin \nDock"
                }

            }

        }

        Behavior on width {
            Anim {
            }

        }

    }

}
