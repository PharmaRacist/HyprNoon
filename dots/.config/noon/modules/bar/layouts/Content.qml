import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.modules.bar.components
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

RowLayout {
    spacing: Mem.options.bar.spacing ?? 5
    anchors.fill: parent
    anchors.rightMargin: Padding.huge
    anchors.leftMargin: Padding.huge

    Repeater {
        model: Mem.options.bar.hLayout

        Loader {
            id: moduleLoader

            property string moduleName: modelData
            Binding {
                target: moduleLoader.Layout
                property: "margins"
                value: moduleLoader.item?.Layout?.margins ?? false
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
                property: "fillHeight"
                value: moduleLoader.item?.Layout?.fillHeight ?? false
                when: moduleLoader.item !== null
            }

            Binding {
                target: moduleLoader.Layout
                property: "fillWidth"
                value: moduleLoader.item?.Layout?.fillWidth ?? true
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

            Binding {
                target: moduleLoader.Layout
                property: "rightMargin"
                value: moduleLoader.item?.Layout?.rightMargin ?? false
                when: moduleLoader.item !== null
            }

            Binding {
                target: moduleLoader.Layout
                property: "leftMargin"
                value: moduleLoader.item?.Layout?.leftMargin ?? false
                when: moduleLoader.item !== null
            }

            Layout.alignment: Qt.AlignVCenter
            sourceComponent: {
                switch (moduleName) {
                case "spacer":
                    return spacerComponent;
                case "power":
                    return powerComponent;
                case "workspaces":
                    return iiWsComponent;
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
                case "space":
                    return spaceComponent;
                case "utilButtons":
                    return utilButtonsComponent;
                case "title":
                    return titleComponent;
                case "resources":
                    return resourcesComponent;
                case "circBattery":
                    return circBatteryComponent;
                case "weather":
                    return weatherComponent;
                case "media":
                    return mediaComponent;
                case "clock":
                    return clockComponent;
                case "kb":
                    return kbComponent;
                case "logo":
                    return logoComponent;
                case "battery":
                    return batteryComponent;
                    case "separator":
                        return separatorComponent;
                default:
                    return null;
                }
            }

            Component {
                id: circBatteryComponent

                MinimalBattery {}
            }

            Component {
                id: kbComponent

                KeyboardLayout {}
            }

            Component {
                id: materialStatusIconsComponent

                StatusIcons {
                    verticalMode: false
                    commonIconColor: Colors.colOnSecondaryContainer
                }
            }

            Component {
                id: weatherComponent

                WeatherIndicator {}
            }

            Component {
                id: titleComponent

                ActiveWindow {
                    bar: barRoot
                }
            }

            Component {
                id: systemStatusIconsComponent

                SystemStatusIcons {}
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
                    Layout.preferredWidth: 8
                }
            }

            Component {
                id: utilButtonsComponent

                UtilButtons {
                    vertical: false
                }
            }

            Component {
                id: resourcesComponent

                Resources {}
            }

            Component {
                id: mediaComponent

                Media {}
            }

            Component {
                id: batteryComponent

                BatteryIndicator {}
            }

            Component {
                id: progressWsComponent

                ProgressWs {
                    bar: barRoot
                    vertical: false
                }
            }

            Component {
                id: iiWsComponent

                Workspaces {
                    bar: barRoot
                }
            }

            Component {
                id: unicodeWsComponent

                UnicodeWs {
                    bar: barRoot
                    verticalMode: false
                }
            }

            Component {
                id: clockComponent

                ClockWidget {}
            }
            Component {
                id: powerComponent

                PowerIcon {}
            }
            Component {
                id: separatorComponent

                VerticalSeparator {
                    Layout.topMargin: Padding.normal
                    Layout.bottomMargin:Padding.normal
                    Layout.margins:Padding.small
                }
            }

            Component {
                id: logoComponent

                Logo {}
            }
        }
    }
}
