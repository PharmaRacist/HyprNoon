import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.common.utils

StyledPanel {
    id: root

    property string title: "Noon"
    property string subTitle: "ERROR:"
    property string description: "YAY! No Errors"
    property bool expanded: false

    function refreshDescription() {
    }

    name: "errorDialog"
    visible: true
    margins: Padding.massive

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    HyprlandFocusGrab {
        // onCleared: visible = false

        windows: [root]
        active: visible
    }

    Timer {
        id: timeout

        running: visible
        interval: 300000
        onTriggered: visible = false
    }

    StyledRect {
        id: bg

        implicitWidth: root.expanded ? 1280 : 600
        implicitHeight: root.expanded ? 600 : 200
        enableShadows: true
        radius: Rounding.huge
        color: Colors.m3.m3surfaceContainer

        anchors {
            centerIn: parent
            margins: Padding.large
        }

        RLayout {
            id: topRow

            implicitHeight: 40

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Padding.verylarge
            }

            RLayout {
                Layout.topMargin: -Padding.verylarge
                Layout.leftMargin: Padding.verylarge

                MaterialSymbol {
                    text: "error"
                    font.pixelSize: 20
                    color: Colors.colSubtext
                }

                StyledText {
                    text: root.title
                    color: Colors.colSubtext

                    font {
                        family: Fonts.family.main
                        pixelSize: Fonts.sizes.normal
                    }

                }

            }

            Spacer {
            }

            RippleButtonWithIcon {
                materialIcon: "keyboard_arrow_down"
                toggled: root.expanded
                buttonRadius: Rounding.large
                implicitSize: 32
                releaseAction: () => {
                    return root.expanded = !root.expanded;
                }
            }

            RippleButtonWithIcon {
                materialIcon: "close"
                colRipple: Colors.colErrorActive
                colBackgroundHover: Colors.colErrorHover
                colBackground: Colors.colError
                iconColor: Colors.colOnError
                buttonRadius: Rounding.large
                implicitSize: 32
                releaseAction: () => {
                    return root.visible = false;
                }
            }

        }

        RLayout {
            anchors.margins: Padding.massive
            anchors.fill: parent
            spacing: Padding.large

            MaterialShapeWrappedMaterialSymbol {
                padding: Padding.verylarge
                text: "error"
                iconSize: 72
                color: Colors.colError
                colSymbol: Colors.colOnError
                shape: MaterialShape.Shape.Cookie9Sided
            }

            CLayout {
                spacing: -4
                Layout.bottomMargin: 16

                StyledText {
                    Layout.fillWidth: true
                    text: root.subTitle
                    color: Colors.colOnLayer1
                    horizontalAlignment: Text.AlignLeft

                    font {
                        variableAxes: Fonts.variableAxes.main
                        family: Fonts.family.main
                        pixelSize: Fonts.sizes.large
                    }

                }

                StyledText {
                    text: {
                        let lines = root.description.split(/\r\n|\r|\n/);
                        let errorLines = lines.filter((line) => {
                            return line.trim().startsWith('caused by');
                        });
                        let errors = errorLines.slice(root.expand ? -20 : -4);
                        let result = errors.join('\n');
                        return result;
                    }
                    horizontalAlignment: Text.AlignLeft
                    Layout.fillWidth: true
                    color: Colors.colError
                    elide: Text.ElideLeft
                    wrapMode: TextEdit.Wrap
                    maximumLineCount: root.expanded ? 20 : 4

                    font {
                        variableAxes: Fonts.variableAxes.title
                        family: Fonts.family.monospace
                        pixelSize: Fonts.sizes.normal
                    }

                }

            }

        }

        RLayout {
            spacing: Padding.normal

            anchors {
                bottom: bg.bottom
                right: bg.right
                margins: Padding.verylarge
            }

            GroupButton {
                buttonText: "Show Logs"
                buttonRadius: Rounding.large
                colBackgroundHover: Colors.m3.m3surfaceContainerHigh
                colBackground: Colors.m3.m3surfaceContainerHighest
                implicitHeight: 30
                padding: 6
                releaseAction: () => {
                    let cmd = `${Quickshell.env("FILE_MANAGER")} ${Directories.home}/.cache/quickshell/crashes`;
                    Noon.exec(cmd);
                    root.visible = false;
                }
            }

        }

    }

}
