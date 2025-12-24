import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledText {
    property bool verticalMode: false
    property real commonIconSize: Fonts.sizes.verylarge
    property color commonIconColor: Colors.colOnLayer1
    readonly property string currentLayout: HyprlandService.keyboardLayoutShortName

    text: currentLayout
    color: commonIconColor
    font.pixelSize: Fonts.sizes.small
    animateChange: true
    font.variableAxes: Fonts.variableAxes.title

    MouseArea {
        anchors.fill: parent
        onClicked: HyprlandService.switchKeyboardLayout()
    }

}
