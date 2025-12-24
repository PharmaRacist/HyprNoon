import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: clockContainer

    property string font: Mem.options.desktop.clock.font
    property var weatherData: WeatherService.weatherData
    property bool arabicDayMode: true

    z: 1
    x: screen.width * Mem.options.desktop.clock.x
    y: screen.height * Mem.options.desktop.clock.y

    PersistentProperties {
        id: states

        property bool editMode: false

        reloadableId: "depthClock"
    }

    MouseArea {
        anchors.fill: clockItem
        enabled: true
        drag.target: states.editMode ? clockContainer : null
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0
        drag.maximumX: screen.width - clockItem.width
        drag.minimumY: 0
        drag.maximumY: screen.height - clockItem.height
        onPositionChanged: {
            if (drag.active) {
                Mem.options.desktop.clock.x = clockContainer.x / screen.width;
                Mem.options.desktop.clock.y = clockContainer.y / screen.height;
            }
        }
        onDoubleClicked: Mem.options.desktop.clock.states.editMode = !states.editMode
        cursorShape: states.editMode ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
    }

    Rectangle {
        anchors.fill: clockItem
        anchors.margins: -5
        border.color: clockText.color
        border.width: 2
        color: "transparent"
        radius: 120 * Mem.options.desktop.clock.scale
        visible: states.editMode
    }

    ColumnLayout {
        id: clockItem

        width: screen.width * Mem.options.desktop.clock.scale
        height: implicitHeight
        spacing: Mem.options.desktop.clock.spacingMultiplier * 100

        RowLayout {
            Layout.maximumHeight: clockText.font.pixelSize / 7.5
            Layout.fillWidth: true
            Layout.alignment: arabicDayMode ? Qt.AlignLeft : Qt.AlignHCenter
            opacity: 0.6
            spacing: clockText.font.pixelSize * 0.01

            StyledText {
                id: dateText

                Layout.leftMargin: 125 * Mem.options.desktop.clock.scale
                text: arabicDayMode ? `${DateTimeService.hour}:${DateTimeService.minute}` : DateTimeService.date
                font.weight: 600
                font.pixelSize: clockText.font.pixelSize / 4
                font.family: clockContainer.font
                color: clockText.color
            }

            RowLayout {
                MaterialSymbol {
                    text: weatherData.currentEmoji
                    font.pixelSize: dateText.font.pixelSize * 0.85
                    color: dateText.color
                    fill: 1
                }

                StyledText {
                    text: weatherData.currentTemp
                    font.pixelSize: dateText.font.pixelSize
                    font.family: dateText.font.family
                    font.weight: 600
                    color: dateText.color
                }

            }

        }

        StyledText {
            id: clockText

            Layout.maximumHeight: font.pixelSize / 1.75
            Layout.alignment: Qt.AlignHCenter
            font.family: clockContainer.font
            font.weight: 700
            font.pixelSize: clockItem.width / 4
            color: Colors.colOnBackground
            text: arabicDayMode ? DateTimeService.arabicDayName : `${DateTimeService.hour}:${DateTimeService.minute}`

            Behavior on color {
                CAnim {
                }

            }

        }

        Behavior on spacing {
            Anim {
            }

        }

    }

}
