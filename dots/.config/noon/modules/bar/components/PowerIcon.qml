import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

MaterialShapeWrappedMaterialSymbol {
    // StyledToolTip {
    //     extraVisibleCondition: mouse.containsMouse
    //     content: PowerService.modeName
    // }

    visible: BatteryService.available
    text: PowerService.icon
    // Cycle through shapes based on mode
    shape: {
        switch (PowerService.modeName) {
        case "Power Saver":
            return MaterialShape.Cookie4Sided;
        case "Balanced":
            return MaterialShape.Cookie6Sided;
        case "Performance":
            return MaterialShape.Cookie9Sided;
        default:
            return MaterialShape.Cookie6Sided;
        }
    }
    fill: 1
    color: {
        switch (PowerService.modeName) {
        case "Power Saver":
            return Colors.colLayer2;
        case "Balanced":
            return Colors.colTertiaryActive;
        case "Performance":
            return Colors.colSecondaryActive;
        default:
            return Colors.colLayer2;
        }
    }
    colSymbol: {
        switch (PowerService.modeName) {
        case "Power Saver":
            return Colors.colOnLayer2;
        case "Balanced":
            return Colors.colTertiary;
        case "Performance":
            return Colors.colSecondary;
        default:
            return Colors.colOnLayer2;
        }
    }
    iconSize: parent.width / 2.4

    MouseArea {
        id: mouse

        hoverEnabled: true
        anchors.fill: parent
        onClicked: PowerService.cycleMode()
    }

}
