import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ColumnLayout {
    property bool showDate: true
    property bool showTime: true
    property string timeFont: Fonts.family.main
    property int fontWeight: 500
    property real fontScale: 1.1

    spacing: 0

    StyledText {
        id: timeText

        visible: showTime
        font.family: timeFont
        font.weight: fontWeight
        font.pixelSize: Fonts.sizes.small * fontScale
        color: Colors.colOnLayer1
        text: DateTimeService.time
    }

    StyledText {
        id: dateText

        visible: showDate
        font.family: timeFont
        font.weight: fontWeight
        font.pixelSize: Fonts.sizes.verysmall * fontScale
        color: Colors.colSubtext
        text: DateTimeService.date
    }

}
