import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    Layout.fillHeight: true
    Layout.fillWidth: true
    spacing: Padding.normal

    property list<var> resourcesList: [
        {
            "icon": "planner_review",
            "name": qsTr("CPU"),
            "history": ResourcesService.cpuUsageHistory,
            "maxAvailableString": ResourcesService.maxAvailableCpuString
        },
        {
            "icon": "memory",
            "name": qsTr("RAM"),
            "history": ResourcesService.memoryUsageHistory,
            "maxAvailableString": ResourcesService.maxAvailableMemoryString
        },
        {
            "icon": "swap_horiz",
            "name": qsTr("Swap"),
            "history": ResourcesService.swapUsageHistory,
            "maxAvailableString": ResourcesService.maxAvailableSwapString
        }
    ]

    Repeater {
        model: resourcesList
        ResourceSummary {
            icon: resourcesList.icon || ""
            name: resourcesList.name || ""
            history: resourcesList.history || []
            maxAvailableString: resourcesList.maxAvailableString || ""
        }
    }

    component ResourceSummary: RowLayout {
        id: resourceSummary
        required property string icon
        required property string name
        required property list<real> history
        required property string maxAvailableString

        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        ColumnLayout {
            spacing: 2
            StyledText {
                text: resourceSummary.name
                font {
                    pixelSize: Fonts.sizes.normal  // Adjust size as needed
                }
                color: Colors.colSubtext
            }
            StyledText {
                text: resourceSummary.history.length > 0 ? (resourceSummary.history[resourceSummary.history.length - 1] * 100).toFixed(1) + "%" : "0%"
                font {
                    family: Fonts.family.monospace
                    variableAxes: Fonts.variableAxes.numbers
                    pixelSize: Fonts.sizes.huge
                }
            }
            StyledText {
                text: resourceSummary.maxAvailableString
                font {
                    pixelSize: Fonts.sizes.small
                }
                color: Colors.colSubtext
            }
            Item {
                Layout.fillHeight: true
            }
        }

        StyledRect {
            id: graphBg
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Rounding.normal
            color: Colors.colLayer1
            clip: true

            Graph {
                anchors.fill: parent
                values: resourceSummary.history
                points: ResourcesService.historyLength
                alignment: Graph.Alignment.Right
            }
        }
    }
}
