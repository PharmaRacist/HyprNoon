import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.bar.components
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    property bool vertical: false

    implicitWidth: !vertical ? 130 : parent.width
    implicitHeight: vertical ? 130 : parent.height
    color: Mem.options.bar.appearance.modulesBg ? Colors.colLayer1 : "transparent"
    radius: Rounding.small

    GridLayout {
        id: columnLayout

        rows: !vertical ? 1 : 4
        columns: vertical ? 1 : 4
        columnSpacing: 4
        rowSpacing: 4
        anchors.centerIn: parent

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Noon.exec("hyprpicker -a -q")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 1
                text: "colorize"
                font.pixelSize: Fonts.sizes.large
                color: Colors.colOnLayer1
            }

        }

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Noon.exec("hyprshot --freeze --clipboard-only --mode region --silent")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 1
                text: "screenshot_region"
                font.pixelSize: Fonts.sizes.large
                color: Colors.colOnLayer1
            }

        }

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            onClicked: Noon.callIpc("sidebar reveal Walls")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 1
                text: "dashboard"
                font.pixelSize: Fonts.sizes.normal
                color: Colors.colOnLayer1
            }

        }

    }

    component CircleUtilButton: RippleButton {
        id: button

        required default property Item content
        property bool extraActiveCondition: false

        implicitHeight: Math.max(content.implicitHeight, 26, content.implicitHeight)
        implicitWidth: Math.max(content.implicitHeight, 26, content.implicitWidth)
        contentItem: content

        PointingHandInteraction {
        }

    }

}
