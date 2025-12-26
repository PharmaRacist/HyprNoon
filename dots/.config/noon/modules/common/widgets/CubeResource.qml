import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

Item {
    required property string iconName
    required property double percentage
    property bool showText: true
    property string toolTipName: ""
    property int circWidth: 5
    property int circSize: 60

    clip: true
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
    }

    ColumnLayout {
        id: resourceRowLayout

        spacing: 4
        x: 0

        CircularProgress {
            Layout.alignment: Qt.AlignVCenter
            lineWidth: circWidth
            value: percentage
            size: circSize
            secondaryColor: Colors.colSecondaryContainer
            primaryColor: Colors.m3.m3onSecondaryContainer

            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: iconName
                font.pixelSize: parent.size / 3
                color: Colors.m3.m3onSecondaryContainer
            }

        }

        StyledText {
            visible: showText
            Layout.alignment: Qt.AlignHCenter
            color: Colors.colOnLayer1
            font.weight: 700
            text: `${Math.round(percentage * 100)} %`
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 20
        }

    }

}
