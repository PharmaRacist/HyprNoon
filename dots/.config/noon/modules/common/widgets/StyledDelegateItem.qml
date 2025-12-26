import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import qs.modules.sidebar

RippleButton {
    id: root
    property alias shapePadding:m3shape.padding
    property alias shape:m3shape.shape
    property color colActiveColor:Colors.colPrimaryContainer
    property color colActiveItemColor:Colors.colPrimary
    property alias title: title.text
    property alias subtext: subtext.text  // Fixed: was pointing to title.text
    property color colSubtext: Colors.colSubtext
    property color colTitle: Colors.colOnLayer2
    property string materialIcon: "music_note"
    width: parent?.width
    implicitHeight: 64
    colBackground: Colors.colLayer2
    buttonRadius: Rounding.large
    MaterialShapeWrappedMaterialSymbol {
        id:m3shape
        anchors {
            left: parent.left
            leftMargin:Padding.huge
            verticalCenter:parent.verticalCenter

        }
        shape:MaterialShape.Cookie6Sided
        padding:Padding.large
        iconSize:parent.height / 2.5
        colSymbol:colActiveItemColor
        text:root.materialIcon
    }
    
    // Wrapper Item to handle anchors
    Item {
        anchors {
            left: m3shape.right
            leftMargin: Padding.large
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: Padding.normal
        }

        RowLayout {
            anchors.fill: parent
            spacing: Padding.verylarge

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Padding.small

                StyledText {
                    id: title
                    maximumLineCount: 1
                    Layout.preferredWidth:240
                    horizontalAlignment:Text.AlignLeft
                    font.pixelSize: Fonts.sizes.normal
                    color: root.colTitle
                    elide: Text.ElideRight
                }

                StyledText {
                    id: subtext
                    Layout.fillWidth: true
                    horizontalAlignment:Text.AlignLeft
                    font.pixelSize: Fonts.sizes.small
                    color: root.colSubtext
                    visible: text !== ""
                }
            }
        }
    }
}
