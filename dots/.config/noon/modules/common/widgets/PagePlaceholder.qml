import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property bool shown: true
    property alias icon: shapeWidget.text
    property alias title: widgetNameText.text
    property alias description: widgetDescriptionText.text
    property alias shape: shapeWidget.shape
    property alias descriptionHorizontalAlignment: widgetDescriptionText.horizontalAlignment
    property alias iconSize: shapeWidget.iconSize
    property alias colBackground: shapeWidget.color
    property alias colOnBackground: shapeWidget.colSymbol

    opacity: shown ? 1 : 0
    visible: opacity > 0

    anchors {
        fill: parent
        topMargin: -30 * (1 - opacity)
        bottomMargin: 30 * (1 - opacity)
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Padding.large

        MaterialShapeWrappedMaterialSymbol {
            id: shapeWidget

            Layout.alignment: Qt.AlignHCenter
            padding: 12
            iconSize: 90
            rotation: -30 * (1 - root.opacity)
        }

        StyledText {
            id: widgetNameText

            visible: text !== ""
            Layout.alignment: Qt.AlignHCenter
            color: Colors.m3.m3outline
            horizontalAlignment: Text.AlignHCenter

            font {
                family: Fonts.family.main
                pixelSize: Fonts.sizes.verylarge
                variableAxes: Fonts.variableAxes.title
            }

        }

        StyledText {
            id: widgetDescriptionText

            visible: description !== ""
            Layout.fillWidth: true
            font.pixelSize: Fonts.sizes.small
            color: root.colOnBackground
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.Wrap
        }

    }

    Behavior on opacity {
        Anim {
        }

    }

}
