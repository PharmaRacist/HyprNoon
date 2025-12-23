import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

BottomDialog {
    id: root

    property bool expanded: parent.expanded
    property int comboWidth: 140

    function findIndex(array, value, valueRole) {
        for (let i = 0; i < array.length; i++) {
            if (array[i][valueRole] === value)
                return i;

        }
        return 0;
    }

    enableStagedReveal: false
    bottomAreaReveal: true
    hoverHeight: 180
    collapsedHeight: 120
    expand: true
    clip: true

    bgAnchors {
        leftMargin: expanded ? 500 : undefined
        rightMargin: expanded ? 500 : undefined
    }

    anchors {
        rightMargin: Padding.normal
        leftMargin: Padding.normal
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Padding.verylarge
        spacing: Padding.large

        RowLayout {
            Layout.fillWidth: true
            spacing: Padding.large

            StyledComboBox {
                Layout.preferredHeight: 40
                Layout.fillWidth: true
                model: ThemeData.themes
                textRole: "name"
                valueRole: "value"
                currentIndex: root.findIndex(ThemeData.themes, Mem.states.desktop.appearance.theme, "value")
                onActivated: (index) => {
                    if (index >= 0 && index < ThemeData.themes.length)
                        GowallService.convertTheme(ThemeData.themes[index].value);

                }
            }

            StyledComboBox {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                model: ThemeData.modes
                textRole: "name"
                valueRole: "value"
                currentIndex: root.findIndex(ThemeData.modes, Mem.states.desktop.appearance.scheme, "value")
                onActivated: (index) => {
                    if (index >= 0 && index < ThemeData.modes.length)
                        WallpaperService.updateScheme(ThemeData.modes[index].value);

                }
            }

            StyledComboBox {
                visible: Mem.options.appearance.colors.palatte
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                model: ThemeData.palettes
                textRole: "name"
                valueRole: "name"
                displayText: Mem.options.appearance.colors.palatteName
                onActivated: (index) => {
                    if (index >= 0 && index < ThemeData.palettes.length)
                        Mem.options.appearance.colors.palatteName = ThemeData.palettes[index];

                }
            }

        }

        StyledTextField {
            Layout.preferredHeight: 40
            Layout.fillWidth: true
            text: Mem.states.desktop.bg.currentFolder
            placeholderText: "Wallpaper folder path..."
            placeholderTextColor: Colors.colOnLayer1
            color: Colors.colOnLayer1
            Keys.onEscapePressed: focus = false
            onAccepted: Mem.states.desktop.bg.currentFolder = text
        }

    }

}
