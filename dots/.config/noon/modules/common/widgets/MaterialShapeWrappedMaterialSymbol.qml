import QtQuick
import qs.modules.common
import qs.modules.common.widgets

MaterialShape {
    id: root

    property alias text: symbol.text
    property alias iconSize: symbol.iconSize
    property alias font: symbol.font
    property alias colSymbol: symbol.color
    property alias fill: symbol.fill
    property real padding: 6

    color: Colors.colSecondaryContainer
    colSymbol: Colors.colOnSecondaryContainer
    shape: MaterialShape.Shape.Clover4Leaf
    implicitSize: Math.max(symbol.implicitWidth, symbol.implicitHeight) + padding * 2

    MaterialSymbol {
        id: symbol

        anchors.centerIn: parent
        color: root.colSymbol
    }

    Behavior on colSymbol {
        CAnim {
        }

    }

    Behavior on color {
        CAnim {
        }

    }

}
