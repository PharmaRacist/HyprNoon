import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledRect {
    id: root

    Layout.preferredHeight: 160
    Layout.fillWidth: true
    Layout.margins: Padding.normal
    enableBorders: true
    enableShadows: true
    color: Colors.colLayer1
    radius: Rounding.verylarge

    ColumnLayout {
        id: columnLayout

        spacing: 8

        anchors {
            fill: parent
            margins: Padding.verylarge
        }

        Row {
            spacing: 6

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: WeatherService.weatherData.currentEmoji
                fill: 1
                font.pixelSize: Fonts.sizes.large
                color: Colors.m3.m3onSurfaceVariant
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledText {
                    text: WeatherService.currentCity
                    color: Colors.m3.m3onSurfaceVariant

                    font {
                        weight: Font.Medium
                        pixelSize: Fonts.sizes.normal
                    }

                }

                StyledText {
                    text: WeatherService.weatherData.currentCondition
                    color: Colors.m3.m3onSurfaceVariant
                    opacity: 0.8

                    font {
                        pixelSize: Fonts.sizes.small
                    }

                }

            }

        }

        // Current Temperature
        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            MaterialSymbol {
                text: "thermostat"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Temperature:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: WeatherService.weatherData.currentTemp
                font.weight: Font.Medium
            }

        }

        // Feels Like
        RowLayout {
            spacing: 5
            Layout.fillWidth: true
            visible: WeatherService.weatherData.feelsLike !== ""

            MaterialSymbol {
                text: "sentiment_satisfied"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Feels like:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: WeatherService.weatherData.feelsLike
            }

        }

        // Humidity
        RowLayout {
            spacing: 5
            Layout.fillWidth: true
            visible: WeatherService.weatherData.humidity !== ""

            MaterialSymbol {
                text: "water_drop"
                color: Colors.m3.m3onSurfaceVariant
                font.pixelSize: Fonts.sizes.large
            }

            StyledText {
                text: qsTr("Humidity:")
                color: Colors.m3.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                color: Colors.m3.m3onSurfaceVariant
                text: WeatherService.weatherData.humidity
            }

        }

    }

}
