import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    property bool canRemove: true
    property string filePath: ""
    property string mimeType: ""
    property real maxHeight: 200
    property real imageWidth: -1
    property real imageHeight: -1
    property real scale: Math.min(root.maxHeight / imageHeight, root.width / imageWidth)
    // Styles/widgets
    property real horizontalPadding: 10
    property real verticalPadding: 10

    signal remove()

    function refresh() {
        root.mimeType = "";
        root.imageWidth = -1;
        root.imageHeight = -1;
        fileTypeProc.exec(["file", "-b", "--mime-type", filePath]);
    }

    onFilePathChanged: refresh()
    visible: filePath !== ""
    radius: Rounding.small - anchors.margins
    color: Colors.colLayer2
    implicitHeight: visible ? (contentItem.implicitHeight + verticalPadding * 2) : 0

    Process {
        id: fileTypeProc

        command: ["file", "-b", "--mime-type", filePath]

        stdout: StdioCollector {
            onStreamFinished: {
                root.mimeType = this.text;
                if (root.mimeType.startsWith("image/"))
                    imageSizeProc.exec(["identify", "-format", "%wx%h", filePath]);

            }
        }

    }

    Process {
        id: imageSizeProc

        command: ["identify", "-format", "%wx%h", filePath]

        stdout: StdioCollector {
            onStreamFinished: {
                const dimensions = this.text.split("x");
                root.imageWidth = parseInt(dimensions[0]);
                root.imageHeight = parseInt(dimensions[1]);
            }
        }

    }

    ColumnLayout {
        id: contentItem

        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }

        RowLayout {
            MaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: {
                    if (root.mimeType.startsWith("image/"))
                        return "image";

                    if (root.mimeType.startsWith("audio/"))
                        return "music_note";

                    if (root.mimeType.startsWith("video/"))
                        return "movie";

                    if (root.mimeType === "application/pdf")
                        return "picture_as_pdf";

                    if (root.mimeType.startsWith("text/"))
                        return "description";

                    return "file_present";
                }
                font.pixelSize: Fonts.sizes.huge
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: root.filePath
                font.pixelSize: Fonts.sizes.verysmall
                font.family: Fonts.family.monospace
                wrapMode: Text.Wrap
            }

            RippleButton {
                visible: root.canRemove
                Layout.alignment: Qt.AlignTop
                buttonRadius: Rounding.full
                colBackground: Colors.colLayer2
                implicitHeight: 28
                implicitWidth: 28
                onClicked: root.remove()

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Fonts.sizes.verylarge
                    color: Colors.colOnLayer2
                }

            }

        }

        Loader {
            id: imagePreviewLoader

            visible: (root.imageWidth != -1) && (root.imageHeight != -1)
            Layout.alignment: Qt.AlignHCenter

            sourceComponent: StyledRect {
                implicitHeight: root.imageHeight * root.scale
                implicitWidth: imagePreview.implicitWidth
                color: "transparent"
                clip: true
                enableBorders: true
                radius: Rounding.normal

                Image {
                    id: imagePreview

                    anchors.fill: parent
                    source: Qt.resolvedUrl(root.filePath)
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
                    width: root.imageWidth * root.scale
                    height: root.imageHeight * root.scale
                    sourceSize.width: root.imageWidth * root.scale
                    sourceSize.height: root.imageHeight * root.scale
                }

            }

        }

    }

}
