import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

MouseArea {
    id: root

    property int fWeight: 500

    implicitWidth: BarData.currentBarExclusiveSize
    implicitHeight: 60
    hoverEnabled: true

    StyledText {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: root.implicitWidth / 2.3
        color: Colors.colOnLayer1
        text: DateTime.verticalDate
        font.weight: root.fWeight
    }

}
