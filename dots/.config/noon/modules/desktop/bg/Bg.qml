import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import QtQuick.Controls
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import qs.store

Scope {
    id: background
    Variants {
        model: Quickshell.screens
        StyledPanel {
            id: backgroundPanel
            property ShellScreen modelData
            screen: modelData
            name: "bg"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            color: Colors.colLayer0

            // Properties
            readonly property bool enableDepthMode: Mem.options.desktop.bg.depthMode // New config toggle for depth mode
            readonly property bool enableParallax: Mem.options.desktop.bg.parallax.enabled
            property string wallpaper: WallpaperService.currentWallpaper
            property var workspaceList: Hyprland.workspaces.values.filter(ws => ws.id >= 0).sort((a, b) => a.id - b.id)
            property real currentWorkspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
            onWallpaperChanged: fgImage.refresh
            readonly property real wallpaperScale: Mem.options.desktop.bg.parallax.parallaxStrength + 1
            readonly property real effectiveWallpaperScale: enableParallax ? wallpaperScale : 1.0
            readonly property real effectiveMovableXSpace: (effectiveWallpaperScale - 1) / 2 * screen.width
            readonly property real effectiveMovableYSpace: (effectiveWallpaperScale - 1) / 2 * screen.height
            exclusiveZone: -1
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                anchors.fill: parent
                Item {
                    id: bgLayerWrapper
                    anchors.fill: parent
                    Image {
                        id: bgImage
                        z: 0
                        fillMode: Image.PreserveAspectCrop
                        source: backgroundPanel.wallpaper
                        asynchronous: true
                        cache: true
                        mipmap: true
                        anchors.fill: enableParallax ? undefined : bgLayerWrapper
                        property bool imageLoaded: status === Image.Ready
                        property bool verticalParallaxMode: Mem.options.desktop.bg.parallax.verticalParallax

                        property real parallaxFactor: {
                            const firstId = workspaceList[0]?.id || 1;
                            const lastId = workspaceList[workspaceList.length - 1]?.id || Mem.options.bar.workspaces.shown;
                            const range = lastId - firstId;
                            const workspaceOffset = range > 0 ? ((currentWorkspace - firstId) / range) : 0.5;
                            return Math.max(0, Math.min(1, workspaceOffset));
                        }

                        property int widgetMargin: Mem.options.desktop.bg.parallax.widgetParallax && enableParallax && Mem.states.sidebar.behavior.expanded ? (Mem.options.bar.behavior.position === "left" ? -1 : 1) * Math.max(Mem.options.desktop.bg.parallax.parallaxStrength, 0.1) * 12 * (SidebarData.launcherWidth > 500 ? 20 : 50) : 0
                        sourceSize: Qt.size(screen.width, screen.height)
                        width: imageLoaded ? parent.width * effectiveWallpaperScale : parent.width
                        height: imageLoaded ? parent.height * effectiveWallpaperScale : parent.height

                        x: imageLoaded ? (verticalParallaxMode ? widgetMargin : -effectiveMovableXSpace - (parallaxFactor - 0.5) * 2 * effectiveMovableXSpace) : 0
                        y: imageLoaded ? (verticalParallaxMode ? -effectiveMovableYSpace - (parallaxFactor - 0.5) * 2 * effectiveMovableYSpace : 0) : 0

                        Behavior on x {
                            Anim {
                                duration: Animations.durations.verylarge
                            }
                        }
                        Behavior on y {
                            Anim {
                                duration: Animations.durations.verylarge
                            }
                        }

                        opacity: imageLoaded ? 1.0 : 0.0
                        Behavior on opacity {
                            Anim {
                                duration: Animations.durations.verylarge
                            }
                        }
                    }
                    Loader {
                        id: layerClock
                        active: fgImage.status === Image.Ready && backgroundPanel.enableDepthMode
                        sourceComponent: LayerClock {}
                        asynchronous: true
                    }
                    DesktopClock {
                        z: 9999
                        visible: !backgroundPanel.enableDepthMode && Mem.options.desktop.clock.enabled || !layerClock.active
                    }
                    Image {
                        id: fgImage
                        visible: backgroundPanel.enableDepthMode
                        z: 9999
                        anchors.fill: bgImage
                        fillMode: Image.PreserveAspectCrop
                        source: FileUtils.trimFileProtocol(Directories.depthCache + Qt.md5(FileUtils.trimFileProtocol(Mem.states.desktop.bg.currentBg)) + ".png")
                        asynchronous: true
                        cache: true
                        mipmap: true
                        sourceSize: bgImage.sourceSize
                        x: bgImage.x
                        y: bgImage.y
                        function refresh() {
                            fgImage.source = "";
                            fgImage.source = FileUtils.trimFileProtocol(Directories.depthCache + Qt.md5(FileUtils.trimFileProtocol(Mem.states.desktop.bg.currentBg)) + ".png");
                        }
                        opacity: fgImage.status === Image.Ready ? 1 : 0
                        Behavior on opacity {
                            Anim {}
                        }
                    }
                }
            }
        }
    }
}
