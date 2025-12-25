import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.modules.bar.components as Components
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    property var barRoot
    property bool bordered: false
    property int chunkWidth: 350
    property int chunkHeight: parent.height
    property real commonRadius: Rounding.verylarge
    property real borderWidth: 1
    property color borderColor: bordered ? Colors.colSecondary : "transparent"
    readonly property bool shouldShow: Screen.width > 1080 ?? false

    anchors.fill: parent
    anchors.rightMargin: Padding.huge

    RowLayout {
        spacing: 10
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20

        Components.MinimalBattery {
            id: battery

            visible: UPower.displayDevice.isLaptopBattery
        }

        Rectangle {
            id: wsChunk

            Layout.preferredWidth: workspaces.width + 16
            Layout.preferredHeight: chunkHeight
            color: Colors.colLayer0
            radius: commonRadius
            border.color: borderColor
            border.width: borderWidth

            RectangularShadow {
                visible: !Mem.options.appearance.transparency
                anchors.fill: wsChunk
                radius: commonRadius
                blur: 1.2 * Sizes.elevationMargin
                spread: 2
                color: Colors.colShadow
            }

            MouseArea {
                width: wsChunk.width
                height: wsChunk.height
                acceptedButtons: Qt.RightButton
                onClicked: (event) => {
                    if (event.button === Qt.RightButton)
                        Noon.callIpc("sidebar reveal View");

                }
            }

            RowLayout {
                width: parent.width
                height: parent.height

                Components.GnomeWs {
                    id: workspaces

                    activeColor: Colors.colPrimary
                    Layout.alignment: Qt.AlignCenter
                    bar: barRoot
                }

            }

        }

        Rectangle {
            id: waveContainer

            border.color: borderColor
            border.width: borderWidth
            visible: shouldShow
            height: chunkHeight
            width: 250
            radius: commonRadius
            color: Colors.colLayer0
            clip: true

            StyledRectangularShadow {
                target: waveContainer
                radius: commonRadius
            }

            Visualizer {
                id: visualizer

                mode: "atom"
                anchors.fill: parent
            }

            Lyrics {
                z: 99
                implicitHeight: parent.height
                implicitWidth: parent.width
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onPressed: {
                    visualizer.active = !visualizer.active;
                }
            }

        }

        Rectangle {
            visible: false
            height: chunkHeight
            width: 200
            radius: commonRadius
            color: Colors.colLayer0
            clip: true
            border.color: borderColor
            border.width: borderWidth

            Components.InlineWindowTitle {
                bar: barRoot
                anchors.fill: parent
            }

        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            id: rightChunk

            width: indicatorsAreaRow.width + 50
            height: chunkHeight
            color: Colors.colLayer0
            radius: commonRadius
            border.color: borderColor
            border.width: borderWidth

            RectangularShadow {
                visible: !Mem.options.appearance.transparency
                anchors.fill: parent
                radius: parent.radius
                blur: 1.2 * Sizes.elevationMargin
                spread: 2
                color: Colors.colShadow
            }

            RowLayout {
                id: indicatorsAreaRow

                spacing: 10
                anchors.centerIn: parent
                Layout.fillWidth: true

                Components.SysTray {
                    bar: barRoot
                    Layout.fillWidth: true
                    visible: SystemTray.items.values.length > 0
                }

                Components.StatusIcons {
                }

                Components.Logo {
                }

            }

        }

    }

    Rectangle {
        id: centerChunk

        width: 320
        color: Colors.colLayer0
        height: chunkHeight
        radius: commonRadius
        border.color: borderColor
        border.width: borderWidth
        anchors.centerIn: parent

        RectangularShadow {
            visible: !Mem.options.appearance.transparency
            anchors.fill: parent
            radius: parent.radius
            blur: 1.2 * Sizes.elevationMargin
            spread: 2
            color: Colors.colShadow
        }

        RowLayout {
            anchors.fill: parent
            spacing: 20
            anchors.rightMargin: 16
            anchors.leftMargin: 16

            Components.Weather {
                Layout.preferredHeight: 18
                Layout.preferredWidth: 40
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Colors.colOutline
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                Layout.alignment: Qt.AlignHCenter
            }

            Components.GnomeClock {
                id: clock

                Layout.alignment: Qt.AlignHCenter
            }

        }

    }

}
