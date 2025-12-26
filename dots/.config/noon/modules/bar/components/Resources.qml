import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

BarGroup {
    id: root

    property bool verticalMode: false
    readonly property bool isCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
    property bool revealAll: false
    property int itemSize: Math.min(BarData.currentBarExclusiveSize, 35) * 0.75

    implicitWidth: content.implicitWidth + (verticalMode ? 0 : revealAll ? 20 : 0)
    implicitHeight: content.implicitHeight + (verticalMode ? revealAll ? 20 : 0 : 0)
    clip: false

    MouseArea {
        id: mouse

        anchors.fill: parent
        onPressed: revealAll = !revealAll
        hoverEnabled: true
    }

    ResourcesPopup {
        hoverTarget: mouse
    }

    GridLayout {
        id: content

        property bool verticalMode: root.verticalMode

        anchors.centerIn: parent
        rowSpacing: Padding.normal
        columnSpacing: Padding.normal
        rows: !verticalMode ? 1 : -1
        columns: verticalMode ? 1 : -1

        Resource {
            iconName: "memory"
            collapsed: !root.revealAll
            percentage: (ResourcesService.stats.mem_total - ResourcesService.stats.mem_available) / ResourcesService.stats.mem_total
            itemSize: root.itemSize
        }

        Resource {
            iconName: "swap_horiz"
            collapsed: !root.revealAll
            percentage: (ResourcesService.stats.swap_total - ResourcesService.stats.swap_free) / ResourcesService.stats.swap_total
            // visible: percentage > 0
            itemSize: root.itemSize
        }

        Resource {
            collapsed: !root.revealAll
            iconName: "settings_slow_motion"
            percentage: ResourcesService.stats.cpu_percent / 100
            itemSize: root.itemSize
        }

        Resource {
            collapsed: !root.revealAll
            iconName: "thermometer"
            percentage: ResourcesService.stats.cpu_temp / 100
            itemSize: root.itemSize
        }

    }

    component Resource: Item {
        id: root

        required property string iconName
        required property double percentage
        property bool verticalMode: parent.verticalMode
        property bool shown: true
        property bool collapsed: false
        property int itemSize: 2

        clip: true
        visible: width > 0 && height > 0
        implicitWidth: resourceLayout.x < 0 ? 0 : childrenRect.width
        implicitHeight: childrenRect.height
        Layout.fillWidth: true

        GridLayout {
            id: resourceLayout

            rowSpacing: 4
            columnSpacing: 4
            x: shown ? 0 : -resourceLayout.width
            columns: verticalMode ? 1 : 2

            ClippedFilledCircularProgress {
                Layout.alignment: Qt.AlignVCenter
                value: percentage
                implicitSize: root.itemSize
                colSecondary: Colors.colSecondaryContainer
                colPrimary: Colors.m3.m3onSecondaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: iconName
                    font.pixelSize: root.itemSize * BarData.barPadding
                    color: Colors.m3.m3onSecondaryContainer
                }

            }

            Revealer {
                reveal: !collapsed
                Layout.alignment: Qt.AlignCenter
                vertical: root.verticalMode

                StyledText {
                    visible: parent.reveal
                    anchors.centerIn: parent
                    color: Colors.colOnLayer1
                    text: `${Math.round(percentage * 100)}`
                }

            }

        }

        Behavior on implicitWidth {
            Anim {
            }

        }

    }

}
