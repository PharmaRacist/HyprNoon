import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.bar.components

StyledRect {
    id: barBackground
    property var barRoot
    readonly property bool isLaptop: UPower.displayDevice.isLaptopBattery
    readonly property bool isLow: isLaptop ? BatteryService.isLow : false
    readonly property int mode: Mem.options.bar.appearance.mode
    readonly property bool bottomMode: Mem.options.bar.behavior.position === "bottom"
    property bool showResources: true
    property bool shownNetworkInfo: true
    property bool showLogo: true
    property string bgColor: isLow ? BatteryService.isCharging ? Colors.m3.m3successContainer : Colors.m3.m3errorContainer : Colors.colLayer0

    color: bgColor
    implicitWidth: Screen.width
    radius: mode !== 0 ? 0 : Rounding.verylarge

    anchors {
        fill: parent
        topMargin: bottomMode && mode === 2 ? Rounding.verylarge : 0
        bottomMargin: !bottomMode && mode === 2 ? Rounding.verylarge : 0
    }

    RoundCorner {
        id: corner1
        visible: mode === 2 && barBackground.height > 0
        size: Rounding.verylarge
        corner: bottomMode ? cornerEnum.bottomLeft : cornerEnum.topLeft
        color: barBackground.color

        anchors.left: parent.left
        anchors.leftMargin: Sizes.frameThickness

        states: [
            State {
                name: "bottom"
                when: bottomMode
                AnchorChanges {
                    target: corner1
                    anchors.bottom: barBackground.top
                    anchors.top: undefined
                }
            },
            State {
                name: "top"
                when: !bottomMode
                AnchorChanges {
                    target: corner1
                    anchors.top: barBackground.bottom
                    anchors.bottom: undefined
                }
            }
        ]

        transitions: Transition {
            AnchorAnimation {
                duration: 200
            }
        }
    }

    RoundCorner {
        id: corner2
        visible: mode === 2 && barBackground.height > 0
        size: Rounding.verylarge
        corner: bottomMode ? cornerEnum.bottomRight : cornerEnum.topRight
        color: barBackground.color

        anchors.right: parent.right
        anchors.rightMargin: Sizes.frameThickness

        states: [
            State {
                name: "bottom"
                when: bottomMode
                AnchorChanges {
                    target: corner2
                    anchors.bottom: barBackground.top
                    anchors.top: undefined
                }
            },
            State {
                name: "top"
                when: !bottomMode
                AnchorChanges {
                    target: corner2
                    anchors.top: barBackground.bottom
                    anchors.bottom: undefined
                }
            }
        ]

        transitions: Transition {
            AnchorAnimation {
                duration: 200
            }
        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.leftMargin: 30
        anchors.rightMargin: 30
        anchors.verticalCenter: parent.verticalCenter
        spacing: 15

        ProgressWs {
            id: workspaces
            bar: barRoot
        }

        InlineWindowTitle {
            id: title
            font.family: Fonts.family.monospace
            bar: barRoot
        }

        Spacer {}

        SysTray {
            bar: barRoot
        }

        Levels {}

        CustomSeparator {
            color: Colors.colOnLayer0
        }

        NetworkInfo {}

        CustomSeparator {
            color: Colors.colOnLayer0
        }

        InlineResources {}

        CustomSeparator {
            color: Colors.colOnLayer0
        }

        GnomeClock {
            id: clock
            font.family: Fonts.family.monospace
        }

        CustomSeparator {
            color: Colors.colOnLayer0
        }

        SystemBattery {
            implicitHeight: 18
        }

        CustomSeparator {
            color: Colors.colOnLayer0
        }

        Logo {
            bordered: false
        }

        SilentHint {}
    }

    Behavior on color {
        ColorAnimation {
            duration: 300
        }
    }

    component Word: StyledText {
        color: Colors.m3.m3onSurfaceVariant
        font.family: Fonts.family.monospace
    }

    component SilentHint: Revealer {
        reveal: Notifications.silent
        MaterialSymbol {
            color: Colors.colOnSecondaryContainer
            visible: Notifications.silent
            text: "notifications_off"
            fill: 1
        }
    }

    component Levels: RowLayout {
        spacing: 10
        property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
        property var brightnessMonitor: BrightnessService.getMonitorForScreen(focusedScreen)

        Resource {
            percentage: AudioService.sink?.audio.volume ?? 0
            iconName: AudioService.sink?.audio.muted ? "volume_off" : "volume_up"
        }

        Resource {
            percentage: brightnessMonitor?.brightness
            iconName: "light_mode"
        }
    }

    component NetworkInfo: MouseArea {
        id: root
        implicitHeight: parent.height
        implicitWidth: row.width
        hoverEnabled: true

        NetworkPopup {
            hoverTarget: root
        }

        RowLayout {
            id: row
            anchors.centerIn: parent

            Resource {
                iconName: NetworkService.materialSymbol
                percentage: NetworkService.networkStrength / 100
                spacing: 5
            }

            Word {
                text: "."
            }

            Word {
                text: `${NetworkService.networkName}`
            }
        }
    }

    component InlineResources: MouseArea {
        id: mouse
        hoverEnabled: true
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        RowLayout {
            id: row
            anchors.fill: parent

            Resource {
                iconName: "memory"
                percentage: ResourcesService.memoryUsedPercentage
            }

            Resource {
                iconName: "swap_horiz"
                percentage: ResourcesService.swapUsedPercentage
                visible: percentage > 0
            }

            Resource {
                iconName: "settings_slow_motion"
                percentage: ResourcesService.cpuUsage
            }

            Resource {
                iconName: "thermometer"
                percentageSymbol: false
                percentage: ResourcesService.avgCpuTemp
            }
        }

        ResourcesPopup {
            hoverTarget: mouse
        }
    }

    component Resource: RowLayout {
        id: root
        property string iconName
        property real percentage
        property bool percentageSymbol: true
        spacing: 5

        MaterialSymbol {
            text: root.iconName
            font.pixelSize: 17
            fill: 1
        }

        Word {
            text: Math.round(100 * root.percentage) + (percentageSymbol ? "%" : "")
        }
    }

    component CustomSeparator: VerticalSeparator {
        Layout.preferredHeight: 13
        Layout.fillHeight: false
    }
}
