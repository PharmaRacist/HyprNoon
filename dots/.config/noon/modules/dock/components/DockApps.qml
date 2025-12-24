import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30

    property Item lastHoveredButton
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show
    property bool verticalMode: false
    property var pinnedApps: []
    Layout.preferredWidth: listView.implicitWidth
    Layout.preferredHeight: listView.implicitHeight
    Layout.fillWidth: true
    Component.onCompleted: {
          if (Mem && Mem.states && Mem.states.dock) {
              pinnedApps = Qt.binding(() => Mem.states.dock.pinnedApps ?? []);
          }
      }

      Connections {
          target: Mem?.states?.dock
          function onPinnedAppsChanged() {
              root.pinnedApps = Mem.states.dock.pinnedApps ?? [];
          }
      }

    // Layout.fillHeight: true
    StyledListView {
        id: listView
        spacing: 0
        orientation: ListView.Horizontal
        implicitWidth: contentWidth
        implicitHeight: Mem.options.dock.appearance.iconSize
        model: ScriptModel {
            objectProp: "appId"
            values: {
                var map = new Map();
                var pinnedAppIds = new Set();
                var runningAppIds = new Set();

                // Process pinned apps
                for (const appId of root.pinnedApps) {
                    const normalizedAppId = appId.toLowerCase();
                    pinnedAppIds.add(normalizedAppId);

                    if (!map.has(normalizedAppId)) {
                        map.set(normalizedAppId, {
                            appId: appId,  // Keep original case
                            pinned: true,
                            toplevels: []
                        });
                    }
                }

                // Process running apps
                for (const toplevel of ToplevelManager.toplevels.values) {
                    const originalAppId = toplevel.appId;
                    const normalizedAppId = originalAppId.toLowerCase();
                    runningAppIds.add(normalizedAppId);

                    if (!map.has(normalizedAppId)) {
                        map.set(normalizedAppId, {
                            appId: originalAppId,  // Store original
                            pinned: false,
                            toplevels: []
                        });
                    }
                    map.get(normalizedAppId).toplevels.push(toplevel);
                }

                // Determine if we need a separator
                const hasUnpinnedRunningApps = Array.from(runningAppIds).some(appId => !pinnedAppIds.has(appId));
                const shouldAddSeparator = root.pinnedApps.length > 0 && hasUnpinnedRunningApps;

                // Build the final values array
                var values = [];

                // Add pinned apps first
                for (const appId of root.pinnedApps) {
                    const normalizedAppId = appId.toLowerCase();
                    if (map.has(normalizedAppId)) {
                        const appData = map.get(normalizedAppId);
                        values.push({
                            appId: appData.appId,  // Use original case
                            toplevels: appData.toplevels,
                            pinned: appData.pinned
                        });
                        map.delete(normalizedAppId);
                    }
                }

                // Add separator if needed
                if (shouldAddSeparator) {
                    values.push({
                        appId: "SEPARATOR",
                        toplevels: [],
                        pinned: false
                    });
                }

                // Add remaining running apps
                for (const [normalizedKey, appData] of map) {
                    if (appData.toplevels.length > 0) {
                        values.push({
                            appId: appData.appId,  // Use original case
                            toplevels: appData.toplevels,
                            pinned: appData.pinned
                        });
                    }
                }

                return values;
            }
        }


        delegate: DockAppButton {
            required property var modelData
            appToplevel: modelData
            appListRoot: root
        }
    }

    PopupWindow {
        id: previewPopup
        // visible: false
        property var appTopLevel: root.lastHoveredButton?.appToplevel
        property bool allPreviewsReady: false
        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                previewPopup.allPreviewsReady = false; // Reset readiness when the hovered button changes
            }
        }
        function updatePreviewReadiness() {
            for (var i = 0; i < previewRowLayout.children.length; i++) {
                const view = previewRowLayout.children[i];
                if (view.hasContent === false) {
                    allPreviewsReady = false;
                    return;
                }
            }
            allPreviewsReady = true;
        }
        property bool shouldShow: {
            const hoverConditions = (popupMouseArea.containsMouse || root.buttonHovered);
            return hoverConditions && allPreviewsReady;
        }
        property bool show: false

        onShouldShowChanged: {
            if (shouldShow) {
                // show = true;
                updateTimer.restart();
            } else {
                updateTimer.restart();
            }
        }
        Timer {
            id: updateTimer
            interval: 100
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow;
            }
        }
        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }
        visible: popupBackground.visible
        color: "transparent"
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: popupMouseArea.implicitHeight + root.windowControlsHeight + Sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            anchors.bottom: parent.bottom
            implicitWidth: popupBackground.implicitWidth + Sizes.elevationMargin * 2
            implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight + Sizes.elevationMargin * 2
            hoverEnabled: true
            x: {
                if (!root.lastHoveredButton || root.lastHoveredButton.window === null) {
                    return 0;  // Fallback: left-align during unready states
                }
                var itemCenter = root.QsWindow.mapFromItem(root.lastHoveredButton, root.lastHoveredButton.width / 2, 0);
                return itemCenter.x - width / 2;
            }
            StyledRectangularShadow {
                target: popupBackground
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    FAnim {}
                }
            }
            Rectangle {
                id: popupBackground
                property real padding: 5
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    FAnim {}
                }
                clip: true
                color: Colors.colSurfaceContainer
                radius: Rounding.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Sizes.elevationMargin
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: previewRowLayout.implicitHeight + padding * 2
                implicitWidth: previewRowLayout.implicitWidth + padding * 2
                Behavior on implicitWidth {
                    FAnim {}
                }
                Behavior on implicitHeight {
                    FAnim {}
                }

                RowLayout {
                    id: previewRowLayout
                    anchors.centerIn: parent
                    Repeater {
                        model: ScriptModel {
                            values: previewPopup.appTopLevel?.toplevels ?? []
                        }
                        RippleButton {
                            id: windowButton
                            required property var modelData
                            padding: 0
                            middleClickAction: () => {
                                windowButton.modelData?.close();
                            }
                            onClicked: {
                                windowButton.modelData?.activate();
                            }
                            contentItem: ColumnLayout {
                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight

                                ButtonGroup {
                                    contentWidth: parent.width - anchors.margins * 2
                                    WrapperRectangle {
                                        Layout.fillWidth: true
                                        color: ColorUtils.transparentize(Colors.colSurfaceContainer)
                                        radius: Rounding.small
                                        margin: 5
                                        StyledText {
                                            Layout.fillWidth: true
                                            font.pixelSize: Fonts.sizes.small
                                            text: windowButton.modelData?.title
                                            elide: Text.ElideRight
                                            color: Colors.m3.m3onSurface
                                        }
                                    }
                                    GroupButton {
                                        id: closeButton
                                        colBackground: ColorUtils.transparentize(Colors.colSurfaceContainer)
                                        baseWidth: windowControlsHeight
                                        baseHeight: windowControlsHeight
                                        buttonRadius: Rounding.full
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            font.pixelSize: Fonts.sizes.normal
                                            color: Colors.m3.m3onSurface
                                        }
                                        onClicked: windowButton.modelData?.close()
                                    }
                                }
                                StyledScreencopyView {
                                    id: screencopyView
                                    captureSource: HyprlandService.isHyprland && previewPopup ? windowButton.modelData : null
                                    live: true
                                    radius: Rounding.small
                                    paintCursor: true
                                    constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                                    onHasContentChanged: previewPopup.updatePreviewReadiness()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
