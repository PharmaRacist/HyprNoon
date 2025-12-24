import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.bar.components
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.store

GridLayout {
    id: root

    property bool centerClock: Mem.states.desktop.clock.center
    property bool verticalClock: Mem.options.desktop.clock.verticalMode ?? false

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    z: 999
    rowSpacing: -20
    columns: 1

    anchors {
        bottom: centerClock ? undefined : parent.bottom
        left: centerClock ? undefined : parent.left
        leftMargin: Mem.options.bar.behavior.position === "left" ? BarData.currentBarSize + Sizes.elevationMargin + Sizes.hyprlandGapsOut : Sizes.hyprlandGapsOut
        bottomMargin: Sizes.elevationMargin + (Mem.options.bar.behavior.position === "bottom" ? BarData.currentBarSize : 0)
    }

    Loader {
        Layout.row: verticalClock ? 0 : 2
        Layout.fillWidth: true
        sourceComponent: root.verticalClock ? verticalClockComponent : horizontalClockComponent
    }

    // Media indicator
    MediaIndicator {
        visible: !verticalClock
        Layout.row: verticalClock ? 1 : 0
    }

    // Date text - only visible in vertical mode
    StyledText {
        visible: root.verticalClock && !root.centerClock
        Layout.row: 3
        Layout.leftMargin: 3
        font.family: Fonts.family.variable
        font.variableAxes: Fonts.variableAxes.display
        color: Colors.colOnLayer0
        font.pixelSize: 40 * Mem.states.desktop.clock.scale
        opacity: 0.75
        text: DateTime.date
        renderType: Text.NativeRendering
    }

    Component {
        id: verticalClockComponent

        VerticalClockComponent {
        }

    }

    Component {
        id: horizontalClockComponent

        HorizontalClockComponent {
        }

    }

    Behavior on anchors.leftMargin {
        Anim {
        }

    }

    Behavior on anchors.bottomMargin {
        Anim {
        }

    }

    transitions: Transition {
        Anim {
            properties: "x,y"
            easing.type: Easing.InOutQuad
        }

    }
    // Clock loader

    component VerticalClockComponent: Column {
        spacing: -25

        StyledText {
            font.variableAxes: Fonts.variableAxes.display
            font.pixelSize: 100 * Mem.states.desktop.clock.scale
            color: Colors.colOnLayer0
            text: DateTime.cleanHour
        }

        StyledText {
            font.pixelSize: 100 * Mem.states.desktop.clock.scale
            font.variableAxes: Fonts.variableAxes.display
            color: Colors.colOnLayer0
            text: DateTime.cleanMinute
        }

    }

    component HorizontalClockComponent: ColumnLayout {
        spacing: -18

        StyledText {
            id: clockText

            font.family: Fonts.family.variable
            font.variableAxes: Fonts.variableAxes.display
            color: Colors.colOnLayer0
            font.pixelSize: 100 * Mem.states.desktop.clock.scale
            text: DateTime.time
        }

        StyledText {
            Layout.leftMargin: 3
            font.family: Fonts.family.variable
            font.variableAxes: Fonts.variableAxes.display
            color: clockText.color
            font.pixelSize: 40 * Mem.states.desktop.clock.scale
            opacity: 0.75
            text: DateTime.date
            renderType: Text.NativeRendering
        }

    }

    component MediaIndicator: RowLayout {
        visible: opacity > 0.1
        opacity: BeatsService.activePlayer ? 1 : 0
        spacing: Padding.huge
        Layout.leftMargin: 5
        Layout.preferredHeight: 120

        MusicCoverArt {
            Layout.preferredHeight: 75
            Layout.preferredWidth: 75
        }

        Column {
            spacing: -Padding.verysmall

            StyledText {
                width: 340
                font.weight: 600
                font.pixelSize: 33
                font.family: Fonts.family.variable
                font.variableAxes: Fonts.variableAxes.display
                color: Colors.colOnLayer0
                text: BeatsService.title
                elide: Text.ElideRight
                animateChange: true

                MouseArea {
                    id: titleMouse

                    anchors.fill: parent
                    onPressed: Noon.callIpc("sidebar_launcher Beats")
                    cursorShape: Qt.PointingHandCursor
                }

            }

            StyledText {
                font.weight: 500
                color: Colors.colSubtext
                width: 200
                font.family: Fonts.family.variable
                font.variableAxes: Fonts.variableAxes.display
                font.pixelSize: 20
                text: BeatsService.artist
                elide: Text.ElideRight
                animateChange: true
            }

        }

        Spacer {
        }

        Behavior on opacity {
            Anim {
            }

        }

    }

}
