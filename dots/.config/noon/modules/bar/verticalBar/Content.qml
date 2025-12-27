import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.modules.bar.components
import qs.common
import qs.common.widgets
import qs.services
import qs.store

ColumnLayout {
    spacing: Padding.normal

    anchors {
        fill: parent
        topMargin: Padding.huge
        bottomMargin: Padding.huge
        horizontalCenter: parent.horizontalCenter
    }

    PersistentProperties {
        id: persist
        reloadableId: "persistedStates"

        property bool expandRes: false
        property bool expandMedia: false
        property bool expandWeather: false
    }

    Repeater {
        model: Mem.options.bar.vLayout

        Loader {
            id: moduleLoader

            property string moduleName: modelData

            // Automatically bind all Layout attached properties
            Binding {
                target: moduleLoader.Layout
                property: "fillHeight"
                value: moduleLoader.item?.Layout?.fillHeight ?? false
                when: moduleLoader.item !== null
            }
            Binding {
                target: moduleLoader.Layout
                property: "topMargin"
                value: moduleLoader.item?.Layout?.topMargin ?? false
                when: moduleLoader.item !== null
            }
            Binding {
                target: moduleLoader.Layout
                property: "bottomMargin"
                value: moduleLoader.item?.Layout?.bottomMargin ?? false
                when: moduleLoader.item !== null
            }

            Binding {
                target: moduleLoader.Layout
                property: "fillWidth"
                value: moduleLoader.item?.Layout?.fillWidth ?? false
                when: moduleLoader.item !== null
            }

            Binding {
                target: moduleLoader.Layout
                property: "preferredHeight"
                value: moduleLoader.item?.Layout?.preferredHeight ?? moduleLoader.item?.implicitHeight ?? 0
                when: moduleLoader.item !== null
            }

            Binding {
                target: moduleLoader.Layout
                property: "preferredWidth"
                value: moduleLoader.item?.Layout?.preferredWidth ?? moduleLoader.item?.implicitWidth ?? 0
                when: moduleLoader.item !== null
            }

            Layout.alignment: Qt.AlignHCenter

            sourceComponent: {
                switch (moduleName) {
                case "spacer":
                    return spacerComponent;
                case "power":
                    return powerComponent;
                case "workspaces":
                    return iiWsComponent;
                case "date":
                    return dateComponent;
                case "volume":
                    return volumeComponent;
                case "brightness":
                    return brightnessComponent;
                case "unicodeWs":
                    return unicodeWsComponent;
                case "progressWs":
                    return progressWsComponent;
                case "systemStatusIcons":
                    return systemStatusIconsComponent;
                case "materialStatusIcons":
                    return materialStatusIconsComponent;
                case "sysTray":
                    return sysTrayComponent;
                case "separator":
                    return separatorComponent;
                case "space":
                    return spaceComponent;
                case "weather":
                    return weatherComponent;
                case "utilButtons":
                    return utilButtonsComponent;
                case "battery":
                    return batteryComponent;
                case "title":
                    return titleComponent;
                case "resources":
                    return resourcesComponent;
                case "media":
                    return mediaComponent;
                case "circBattery":
                    return circBatteryComponent;
                case "clock":
                    return clockComponent;
                case "keyboard":
                    return kbComponent;
                case "logo":
                    return logoComponent;
                default:
                    return null;
                }
            }
            Component {
                id: circBatteryComponent
                MinimalBattery {}
            }
            Component {
                id: weatherComponent

                WeatherIndicator {
                    verticalMode: true
                    expanded: persist.expandWeather
                }
            }

            Component {
                id: kbComponent

                KeyboardLayout {
                }
            }

            Component {
                id: batteryComponent

                BatteryIndicator {
                    verticalMode: true
                }
            }

            Component {
                id: materialStatusIconsComponent

                StatusIcons {
                    verticalMode: true
                    commonIconColor: Colors.colOnSecondaryContainer
                }
            }

            Component {
                id: titleComponent

                CombinedTitle {
                    bar: barRoot
                }
            }

            Component {
                id: systemStatusIconsComponent

                SystemStatusIcons {}
            }

            Component {
                id: separatorComponent

                HorizontalSeparator {
                    visible: opacity > 0
                    opacity: Mem.options.bar.appearance.enableSeparators ? 1 : 0
                }
            }

            Component {
                id: spacerComponent

                Spacer {}
            }

            Component {
                id: sysTrayComponent

                SysTray {
                    bar: barRoot
                }
            }

            Component {
                id: spaceComponent

                Item {
                    Layout.preferredHeight: 8
                }
            }

            Component {
                id: utilButtonsComponent

                UtilButtons {
                    vertical: true
                }
            }

            Component {
                id: resourcesComponent

                Resources {
                    verticalMode: true
                }
            }

            Component {
                id: volumeComponent

                VolumeIndicator {
                    verticalMode: true
                }
            }

            Component {
                id: brightnessComponent

                BrightnessIndicator {
                    verticalMode: true
                }
            }

            Component {
                id: mediaComponent

                IIMedia {}
            }

            Component {
                id: progressWsComponent

                ProgressWs {
                    bar: barRoot
                    vertical: true
                }
            }

            Component {
                id: iiWsComponent

                VWorkspaces {
                    bar: barRoot
                }
            }

            Component {
                id: unicodeWsComponent

                UnicodeWs {
                    bar: barRoot
                    verticalMode: true
                }
            }
            Component {
                id: dateComponent

                DateWidget {}
            }

            Component {
                id: clockComponent

                VClockWidget {}
            }
            Component {
                id: powerComponent

                PowerIcon {}
            }
            Component {
                id: logoComponent

                Logo {
                    bg: false
                }
            }
        }
    }
}
