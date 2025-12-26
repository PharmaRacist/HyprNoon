import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.store

StyledRect {
    id: searchBar

    property alias searchText: searchInput.text
    property alias searchInput: searchInput
    property var searchBehavior

    Layout.fillWidth: true
    Layout.preferredHeight: 40
    radius: Rounding.normal
    color: ColorUtils.transparentize(Colors.colLayer0, 0.9)

    RowLayout {
        anchors.fill: parent
        anchors.rightMargin: Padding.large
        anchors.leftMargin: Padding.large
        spacing: Padding.small

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: 20
            text: "search"
            color: searchInput.activeFocus ? Colors.colPrimary : Colors.m3.m3onSurfaceVariant
            opacity: 0.6
        }

        TextField {
            id: searchInput

            Layout.fillWidth: true
            Layout.fillHeight: true
            objectName: "searchInput"
            text: searchText
            placeholderText: "Search..."
            background: null
            selectionColor: Colors.colSecondaryContainer
            selectedTextColor: Colors.m3.m3onSecondaryContainer
            color: Colors.m3.m3onSurfaceVariant
            placeholderTextColor: Colors.m3.m3outline
            selectByMouse: true
            onTextChanged: searchBar.searchBehavior

            font {
                family: Fonts.family.main
                pixelSize: Fonts.sizes.small
            }

        }

        RippleButton {
            buttonRadius: 12
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            visible: searchInput.text.length > 0
            colBackground: "transparent"
            releaseAction: () => {
                searchInput.clear();
                if (!isAux)
                    Qt.callLater(() => {
                    return searchInput.forceActiveFocus();
                });

            }

            MaterialSymbol {
                anchors.centerIn: parent
                font.pixelSize: 16
                text: "close"
                color: Colors.m3.m3onSurfaceVariant
            }

        }

    }

    Behavior on Layout.preferredHeight {
        Anim {
        }

    }

}
