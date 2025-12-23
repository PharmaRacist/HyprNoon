import qs.services
import qs.store
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

StyledListView {
    id: root
    property alias model: root.model
    property string selectedCategory: ""
    property alias currentIndex: root.currentIndex
    readonly property int iconSize: 36
    signal altLaunched(var app)
    signal appLaunched(var app)
    signal searchFocusRequested
    signal contentFocusRequested

    spacing: Padding.normal
    clip: true
    focus: true
    animateMovement: false
    popin: true

    Connections {
        target: root
        function onContentFocusRequested() {
            if (root.count > 0) {
                root.currentIndex = 0;
                root.forceActiveFocus();
                root.positionViewAtIndex(0, ListView.Beginning);
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Up) {
            if (currentIndex > 0) {
                currentIndex--;
                positionViewAtIndex(currentIndex, ListView.Contain);
            } else if (currentIndex === 0) {
                searchFocusRequested();
                currentIndex = -1;
            } else if (currentIndex === -1 && count > 0) {
                currentIndex = count - 1;
                positionViewAtIndex(currentIndex, ListView.Contain);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            if (currentIndex === -1 && count > 0) {
                currentIndex = 0;
                positionViewAtIndex(currentIndex, ListView.Contain);
            } else if (currentIndex < count - 1) {
                currentIndex++;
                positionViewAtIndex(currentIndex, ListView.Contain);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (currentIndex >= 0 && currentIndex < count) {
                const item = model.get(currentIndex);
                if (item)
                    appLaunched(item);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            if (count > 0) {
                currentIndex = 0;
                positionViewAtIndex(currentIndex, ListView.Beginning);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            if (count > 0) {
                currentIndex = count - 1;
                positionViewAtIndex(currentIndex, ListView.End);
            }
            event.accepted = true;
        }
    }

    delegate: RippleButton {
        id: clipboardItem
        required property var model
        required property int index

        implicitWidth: root.width - Padding.verylarge
        implicitHeight: model.isImage ? 200 : 70
        colBackground: Colors.colLayer2
        buttonRadius: Rounding.verylarge

        releaseAction: () => root.appLaunched(model)
        altAction: () => {
            root.altLaunched(model);
            console.log("pressed", model);
        }

        states: [
            State {
                name: "colorized"
                when: ColorUtils.isValidColor(model.name || "")
                PropertyChanges {
                    target: clipboardItem
                    colBackground: ColorUtils.transparentize(model.name || "", 0.5)
                }
            },
            State {
                name: "hovered"
                when: !ColorUtils.isValidColor(model.name || "") && clipboardItem.hovered
                PropertyChanges {
                    target: clipboardItem
                    colBackground: ColorUtils.transparentize(Colors.colSurfaceContainerHighestHover, 0.5)
                }
            },
            State {
                name: "focused"
                when: !ColorUtils.isValidColor(model.name || "")
                      && root.currentIndex === index && root.activeFocus
                PropertyChanges {
                    target: clipboardItem
                    colBackground: ColorUtils.transparentize(Colors.colSurfaceContainerHighestHover, 0.3)
                }
            }
        ]

        StyledRect {
            id: imageContainer
            anchors.fill: parent
            anchors.margins: Padding.small
            visible: model?.isImage === true
            z: 1
            color: Colors.colLayer2
            radius: Rounding.verylarge
            clip: true

            Loader {
                anchors.fill: parent
                active: true
                asynchronous: true
                sourceComponent: CroppedImage {
                    id: previewImage
                    anchors.fill: parent
                    smooth: true
                    mipmap: true
                    source: model?.imagePath || ""
                    PagePlaceholder {
                        z: 99
                        anchors.fill: parent
                        shown: parent.source === null || parent.source === ""
                        icon: "image"
                    }
                }
            }
        }

        RowLayout {
            visible: !model.isImage
            anchors.fill: parent
            anchors.margins: Padding.normal
            spacing: Padding.verylarge

            Loader {
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Padding.large

                sourceComponent: {
                    if (model.faviconLocal || model.faviconUrl) {
                        return faviconComponent;
                    } else if (model.iconImage) {
                        return iconImageComponent;
                    }
                    return materialSymbolComponent;
                }

                Component {
                    id: iconImageComponent
                    StyledIconImage {
                        source: Noon.iconPath(model?.iconImage || "")
                        implicitSize: root.iconSize
                    }
                }

                Component {
                    id: faviconComponent
                    Image {
                        source: model.faviconUrl || model.faviconLocal || ""
                        width: root.iconSize
                        height: root.iconSize
                        smooth: true
                        mipmap: true
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                    }
                }

                Component {
                    id: materialSymbolComponent
                    MaterialShapeWrappedMaterialSymbol {
                        text: model.icon || "content_paste"
                        font.pixelSize: 24
                        color: Colors.colSecondaryContainer
                        colSymbol: mainText.color
                    }
                }
            }

            StyledText {
                id: mainText
                text: model.name || ""
                font.pixelSize: Fonts.sizes.small
                color: Colors.colOnLayer2
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: model.type || ""
                font.pixelSize: Fonts.sizes.verysmall
                color: mainText.color
                opacity: 0.6
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    RippleButtonWithIcon {
        id: fab
        visible: root.selectedCategory === "History"
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 30
        }

        StyledRectangularShadow {
            target: fab
            radius: fab.buttonRadius
        }

        implicitSize: 55
        iconSize: Fonts.sizes.huge
        buttonRadius: Rounding.large
        colBackground: Colors.colSecondaryContainer

        releaseAction: () => {
            Cliphist.wipe()
            Cliphist.refresh()
        }

        materialIcon: switch (selectedCategory) {
            case "History":
                return "clear_all";
        }
    }

    Rectangle {
        anchors.fill: parent
        z: -1
        color: Colors.colLayer1
        radius: Rounding.verylarge
    }
}
