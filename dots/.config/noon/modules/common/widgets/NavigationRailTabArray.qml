import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property int currentIndex: 0
    property bool expanded: false
    default property alias data: tabBarColumn.data

    implicitHeight: tabBarColumn.implicitHeight
    implicitWidth: tabBarColumn.implicitWidth

    Rectangle {
        property real itemHeight: tabBarColumn.children[0].baseSize
        property real baseHighlightHeight: tabBarColumn.children[0].baseHighlightHeight

        visible: false
        radius: Rounding.full
        color: Colors.colSecondaryContainer
        implicitHeight: root.expanded ? itemHeight : baseHighlightHeight
        implicitWidth: tabBarColumn.children[root.currentIndex].visualWidth

        anchors {
            // topMargin: root.currentIndex * (itemHeight + spacing) + (root.expanded ? 0 : ((itemHeight - baseHighlightHeight) / 2))

            top: tabBarColumn.top
            left: tabBarColumn.left
        }

        Behavior on anchors.topMargin {
            Anim {
            }

        }

    }

    ColumnLayout {
        id: tabBarColumn

        anchors.fill: parent
        spacing: 10
    }

}
