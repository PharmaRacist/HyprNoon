import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

MaterialShapeWrappedMaterialSymbol {
    visible: BatteryService.available
    text: PowerService.icon
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
        onPressed: (event) => {
            if (event.button === Qt.RightButton)
                PowerService.cycleMode(true);
            else
                PowerService.cycleMode();
        }
    }

}
