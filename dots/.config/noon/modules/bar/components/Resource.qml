import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

Item {
    required property string iconName
    required property double percentage
    property bool shown: true

    clip: true
    visible: width > 0 && height > 0
    implicitWidth: resourceRowLayout.x < 0 ? 0 : childrenRect.width
    implicitHeight: childrenRect.height
    Layout.fillWidth: true

    RowLayout {
        id: resourceRowLayout

        spacing: 4
        x: shown ? 0 : -resourceRowLayout.width

        CircularProgress {
            Layout.alignment: Qt.AlignVCenter
            lineWidth: 2
            value: percentage
            size: 26
            secondaryColor: Colors.colSecondaryContainer
            primaryColor: Colors.m3.m3onSecondaryContainer

            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: iconName
                iconSize: Fonts.sizes.normal
                color: Colors.m3.m3onSecondaryContainer
            }

        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.colOnLayer1
            text: `${Math.round(percentage * 100)}`
        }

        Behavior on x {
            Anim {
            }

        }

    }

    Behavior on implicitWidth {
        Anim {
        }

    }

}
