import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.dock.components
import qs.modules.dock.components.osk
import qs.modules.dock
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool pinned: Mem.states.dock.pinned ?? false
    property bool showOsk: GlobalStates.oskOpen

    Variants {
        model: [Quickshell.screens[0]]

        StyledPanel {
            id: dockRoot
            required property var modelData

            screen: modelData
            name: "dock"
            anchors.bottom: true

            property real mainRounding: 2 * Rounding.verylarge * Mem.options.dock.appearance.iconSizeMultiplier
            property int dockHeight: root.showOsk ? 340 : mainLoader.implicitHeight + Sizes.elevationMargin
            property bool reveal: root.showOsk || GlobalStates.superHeld || root.pinned || dockMouseArea.containsMouse || (!ToplevelManager.activeToplevel?.activated && !Mem.states.sidebar.behavior.expanded)
            exclusiveZone: root.pinned ? mainLoader.implicitHeight + Sizes.elevationMargin : -1

            implicitWidth: content.implicitWidth + 10 * mainRounding
            implicitHeight: dockHeight

            WlrLayershell.layer: WlrLayer.Top

            mask: Region {
                item: dockMouseArea
            }

            MouseArea {
                id: dockMouseArea

                z: 99
                hoverEnabled: true
                height: parent.height

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    topMargin: dockRoot.reveal && !GlobalStates.showBeam && !GlobalStates.showOsdValues ? 2 : dockRoot.dockHeight - 1
                    Behavior on topMargin {
                        FAnim {}
                    }
                }

                RowLayout {
                    id: content

                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: Sizes.elevationMargin
                    }

                    Loader {
                        id: mainLoader
                        active: true
                        sourceComponent: root.showOsk ? oskComponent : dockComponent

                        Component {
                            id: oskComponent
                            OnScreenKeyboardDock {}
                        }

                        Component {
                            id: dockComponent
                            RowLayout {
                                spacing: Padding.small
                                DockPinButton {
                                    id: pinBtn
                                    pinned: root.pinned
                                }
                                DockMedia {}
                                DockContent {
                                    id: bg
                                }
                                DockTimerIndicator {}
                            }
                        }
                    }
                }
            }
        }
    }

    component OnScreenKeyboardDock: StyledRect {
        implicitWidth: oskLayout.implicitWidth + 40
        implicitHeight: oskLayout.implicitHeight + 40

        color: Colors.colLayer0
        radius: dockRoot.mainRounding
        enableShadows: true
        enableBorders: true

        RowLayout {
            id: oskLayout
            anchors.centerIn: parent
            spacing: 5

            VerticalButtonGroup {
                GroupButton {
                    baseWidth: 40
                    baseHeight: 40
                    clickedWidth: baseWidth
                    clickedHeight: baseHeight + 20
                    buttonRadius: Rounding.normal
                    toggled: root.pinned
                    onClicked: root.pinned = !root.pinned

                    contentItem: MaterialSymbol {
                        text: "keep"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Fonts.sizes.verylarge
                        color: root.pinned ? Colors.m3.m3onPrimary : Colors.colOnLayer0
                    }
                }

                GroupButton {
                    baseWidth: 40
                    baseHeight: 40
                    clickedWidth: baseWidth
                    clickedHeight: baseHeight + 20
                    buttonRadius: Rounding.normal
                    onClicked: GlobalStates.oskOpen = false

                    contentItem: MaterialSymbol {
                        text: "keyboard_hide"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Fonts.sizes.verylarge
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Colors.colOutlineVariant
                Layout.topMargin: 20
                Layout.bottomMargin: 20
            }

            OskContent {
                Layout.fillWidth: true
            }
        }
    }
}
