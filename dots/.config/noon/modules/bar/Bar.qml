import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Wayland
import qs.modules.bar
import qs.modules.bar.layouts
import qs.modules.bar.verticalBar
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

Scope {
    id: bar

    property bool vertical: BarData.verticalBar
    readonly property var horizontalLayouts: BarData.horizontalLayouts
    readonly property var verticalLayouts: BarData.verticalLayouts
    property int horizontalLayout: Mem.options.bar.currentLayout
    property int verticalLayout: Mem.options.bar.currentVerticalLayout
    readonly property var currentBarData: vertical ? BarData.getVerticalBar(verticalLayout) : BarData.getHorizontalBar(horizontalLayout)
    readonly property var effectiveAnchors: BarData.getEffectiveAnchors(currentBarData)
    // Hover-to-reveal properties
    property bool exclusiveHover: !Mem.options.bar.appearance.useBg
    property bool hoverEnabled: Mem.options.bar.behavior.autoHide
    property int peekSize: 10
    property var horizontalLayoutComponents: {
        let components = {
        };
        for (let i = 0; i < horizontalLayouts.length; i++) {
            components[i] = Qt.createComponent(`./layouts/${horizontalLayouts[i]}.qml`);
        }
        return components;
    }
    property var verticalLayoutComponents: {
        let components = {
        };
        for (let i = 0; i < verticalLayouts.length; i++) {
            components[i] = Qt.createComponent(`./verticalBar/${verticalLayouts[i]}.qml`);
        }
        return components;
    }
    property var horizontalModel: []
    property var verticalModel: []
    property var modelProxy: []
    property string currentPosition: Mem.options.bar.behavior.position

    function updateModels() {
        let screensModel = Mem.options.bar.behavior.showOnAll ? Quickshell.screens : [Quickshell.screens[0]] ?? Quickshell.screens;
        if (vertical) {
            horizontalModel = [];
            verticalModel = screensModel;
        } else {
            verticalModel = [];
            horizontalModel = screensModel;
        }
    }

    function debounceRecreate() {
        if (debounceTimer.running)
            debounceTimer.stop();

        modelProxy = [];
        debounceTimer.restart();
    }

    onVerticalChanged: updateModels()
    onCurrentPositionChanged: debounceRecreate()

    Timer {
        id: debounceTimer

        interval: Mem.options.hacks.arbitraryRaceConditionDelay
        onTriggered: modelProxy = vertical ? verticalModel : horizontalModel
    }

    Variants {
        model: modelProxy

        StyledPanel {
            id: barRoot

            property ShellScreen modelData
            property bool barHovered: false

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            name: "bar"
            implicitWidth: vertical ? BarData.getEffectiveWidth(currentBarData) : BarData.getEffectiveHeight(currentBarData)
            implicitHeight: !vertical ? BarData.getEffectiveHeight(currentBarData) : Screen.height
            exclusiveZone: {
                if (!bar.hoverEnabled)
                    return BarData.getEffectiveExclusiveZone(currentBarData);

                return barRoot.barHovered && bar.exclusiveHover ? BarData.getEffectiveExclusiveZone(currentBarData) : bar.peekSize;
            }

            anchors {
                left: effectiveAnchors.left
                top: effectiveAnchors.top
                right: effectiveAnchors.right
                bottom: effectiveAnchors.bottom
            }

            // Hover detection area
            MouseArea {
                id: hoverArea

                anchors.fill: parent
                hoverEnabled: bar.hoverEnabled
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onEntered: {
                    if (bar.hoverEnabled)
                        barRoot.barHovered = true;

                }
                onExited: {
                    if (bar.hoverEnabled)
                        barRoot.barHovered = false;

                }

                // Container for bar content with margins
                Item {
                    id: barContainer

                    // Calculate margins for hiding based on position
                    property int hideMargin: {
                        if (!bar.hoverEnabled || barRoot.barHovered)
                            return 0;

                        return -(vertical ? BarData.getEffectiveWidth(currentBarData) : BarData.getEffectiveHeight(currentBarData) - bar.peekSize);
                    }

                    opacity: !bar.hoverEnabled || barRoot.barHovered ? 1 : 0

                    anchors {
                        fill: parent
                        leftMargin: (Mem.options.bar.behavior.position === "left") ? hideMargin : 0
                        rightMargin: (Mem.options.bar.behavior.position === "right") ? hideMargin : 0
                        topMargin: (Mem.options.bar.behavior.position === "top") ? hideMargin : 0
                        bottomMargin: (Mem.options.bar.behavior.position === "bottom") ? hideMargin : 0
                    }

                    // Unified layout loader
                    Loader {
                        id: layoutLoader

                        anchors.fill: parent
                        sourceComponent: vertical ? bar.verticalLayoutComponents[bar.verticalLayout] : bar.horizontalLayoutComponents[bar.horizontalLayout]
                        onLoaded: {
                            if (item)
                                item.barRoot = barRoot;

                        }
                    }

                    // Smooth transitions for margins
                    Behavior on anchors.topMargin {
                        enabled: !vertical && Mem.options.bar.behavior.position === "top"

                        Anim {
                            duration: Animations.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Animations.curves.expressiveFastSpatial
                        }

                    }

                    Behavior on anchors.bottomMargin {
                        enabled: !vertical && Mem.options.bar.behavior.position === "bottom"

                        Anim {
                            duration: Animations.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Animations.curves.expressiveFastSpatial
                        }

                    }

                    Behavior on anchors.leftMargin {
                        enabled: vertical && Mem.options.bar.behavior.position === "left"

                        Anim {
                            duration: Animations.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Animations.curves.expressiveFastSpatial
                        }

                    }

                    Behavior on anchors.rightMargin {
                        enabled: vertical && Mem.options.bar.behavior.position === "right"

                        Anim {
                            duration: Animations.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Animations.curves.expressiveFastSpatial
                        }

                    }

                }

            }

            mask: Region {

                item: Rectangle {
                    property bool isHorizontal: !vertical

                    x: isHorizontal ? 0 : (Mem.options.bar.behavior.position === "right" ? (barRoot.width - barRoot.exclusiveZone) : 0)
                    y: isHorizontal ? (Mem.options.bar.behavior.position === "bottom" ? (barRoot.height - barRoot.exclusiveZone) : 0) : 0
                    width: isHorizontal ? barRoot.width : barRoot.exclusiveZone
                    height: isHorizontal ? barRoot.exclusiveZone : barRoot.height
                    visible: false
                }

            }

        }

    }

}
