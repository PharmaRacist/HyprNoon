import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

StyledRect {
    id: wallpaperItem

    property string fileUrl
    property bool isKeyboardSelected: false
    property bool isCurrentWallpaper: false
    readonly property bool isVideoFile: {
        if (!fileUrl)
            return false;

        const name = fileUrl.toString().toLowerCase();
        return name.endsWith(".mp4") || name.endsWith(".mov") || name.endsWith(".m4v") || name.endsWith(".avi") || name.endsWith(".mkv") || name.endsWith(".webm");
    }

    signal clicked()

    anchors.fill: parent
    anchors.margins: isKeyboardSelected ? 3 * root.itemSpacing : root.itemSpacing
    radius: Rounding.large
    color: ColorUtils.transparentize(Colors.colLayer0, isKeyboardSelected ? 0 : 0.8)
    enableShadows: isKeyboardSelected
    enableBorders: isKeyboardSelected
    clip: true

    CroppedImage {
        id: imageObject

        anchors.fill: parent
        source: isVideoFile ? "" : WallpaperService.getThumbnailPath(wallpaperItem.fileUrl, "large")
        radius: Rounding.large
        asynchronous: true
        visible: !isVideoFile
    }

    VideoPreview {
        id: videoPlayer

        anchors.fill: parent
        source: isVideoFile ? wallpaperItem.fileUrl : ""
        visible: isVideoFile
    }

    Rectangle {
        visible: isVideoFile
        width: 40
        height: 40
        radius: 20
        color: ColorUtils.transparentize(Colors.colLayer0, 0.3)

        anchors {
            top: parent.top
            right: parent.right
            margins: 8
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "play_circle"
            fill: 1
            color: Colors.m3.m3onSurface
            font.pixelSize: 24
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (event) => {
            if (event.button === Qt.RightButton)
                wallpaperMenu.popup(event.x, event.y);
            else if (event.button === Qt.LeftButton)
                wallpaperItem.clicked();
        }
        onEntered: {
            if (isVideoFile && videoPlayer.playbackState !== MediaPlayer.PlayingState)
                videoPlayer.play();

        }
        onExited: {
            if (isVideoFile && videoPlayer.playbackState === MediaPlayer.PlayingState)
                videoPlayer.pause();

        }
    }

    RoundCorner {
        id: checkmark

        corner: cornerEnum.bottomRight
        size: 70
        color: Colors.m3.m3primary
        visible: isCurrentWallpaper
        z: 99

        anchors {
            bottom: parent.bottom
            right: parent.right
        }

    }

    MaterialSymbol {
        z: 999
        visible: checkmark.visible
        text: "check"
        fill: 1
        color: Colors.m3.m3onPrimary
        font.pixelSize: 25

        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 0
        }

    }

    Menu {
        id: wallpaperMenu

        Material.theme: Material.Dark
        Material.primary: Colors.colPrimaryContainer
        Material.accent: Colors.colSecondaryContainer
        Material.roundedScale: Rounding.normal
        Material.elevation: 8

        MenuItem {
            text: "Delete"
            Material.foreground: Colors.colOnLayer2
            onTriggered: {
                if (wallpaperItem.fileUrl)
                    FileUtils.deleteItem(wallpaperItem.fileUrl);

            }

            background: Rectangle {
                color: parent.hovered ? Colors.colOnSurface : "transparent"
                radius: Rounding.verylarge
                opacity: parent.hovered ? 0.08 : 0

                anchors {
                    leftMargin: Padding.normal
                    rightMargin: Padding.normal
                    fill: parent
                }

            }

        }

        background: StyledRect {
            implicitWidth: 240
            implicitHeight: 26 * parent.contentItem.children.length
            color: Colors.colLayer0
            radius: Rounding.verylarge
            enableShadows: true
        }

        enter: Transition {
            Anim {
                property: "opacity"
                from: 0
                to: 1
                duration: Animations.durations.small
            }

            Anim {
                property: "scale"
                from: 0.95
                to: 1
                duration: Animations.durations.small
            }

        }

        exit: Transition {
            Anim {
                property: "opacity"
                from: 1
                to: 0
                duration: Animations.durations.small
            }

            Anim {
                property: "scale"
                from: 1
                to: 0.95
                duration: Animations.durations.small
            }

        }

    }

}
