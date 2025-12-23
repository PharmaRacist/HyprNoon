import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

RowLayout {
    id: root

    property alias title: titleArea.text

    Layout.fillWidth: true
    Layout.preferredHeight: 50
    Layout.margins: Padding.large

    StyledText {
        id: titleArea

        font.pixelSize: Fonts.sizes.subTitle
        color: Colors.colOnLayer2
    }

    Item {
        Layout.fillWidth: true
    }

}
