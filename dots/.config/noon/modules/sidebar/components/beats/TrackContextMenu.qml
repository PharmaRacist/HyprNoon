import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Menu {
    id: contextMenu

    // Properties to be set from parent
    property string trackPath: ""
    property string trackName: ""
    property var musicModel: null
    property var onRefresh: null
    property var parentButton: null

    // Custom popup function with positioning
    function showMenu() {
        // Position at mouse or parent
        if (parentButton) {
            x = parentButton.width / 2;
            y = parentButton.height;
        }
        // Try both methods
        if (typeof popup === "function")
            popup();
        else if (typeof open === "function")
            open();
        else
            visible = true;
    }

    // Make sure menu is visible
    visible: false
    // Size properties
    width: 200
    modal: true
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // Play Track
    MenuItem {
        text: qsTr("Play")
        height: 40
        onTriggered: () => {
            if (trackPath)
                BeatsService.playTrack(trackPath, musicModel);

        }

        background: Rectangle {
            color: parent.hovered ? TrackColorsService.colors.colLayer1Hover : "transparent"
            radius: Rounding.small
        }

        contentItem: RowLayout {
            spacing: Padding.normal
            Layout.leftMargin: Padding.large
            Layout.rightMargin: Padding.large

            MaterialSymbol {
                Layout.leftMargin: Padding.normal
                text: "play_arrow"
                font.pixelSize: 18
                color: TrackColorsService.colors.colOnLayer2
            }

            StyledText {
                text: qsTr("Play")
                color: TrackColorsService.colors.colOnLayer2
                font.pixelSize: Fonts.sizes.small
                Layout.fillWidth: true
            }

        }

    }

    // Isolate Track
    MenuItem {
        text: qsTr("Isolate")
        height: 40
        onTriggered: {
            if (trackPath && onRefresh)
                BeatsService.isolateTrack(trackPath, onRefresh);

        }

        background: Rectangle {
            color: parent.hovered ? TrackColorsService.colors.colLayer1Hover : "transparent"
            radius: Rounding.small
        }

        contentItem: RowLayout {
            spacing: Padding.normal
            Layout.leftMargin: Padding.large
            Layout.rightMargin: Padding.large

            MaterialSymbol {
                Layout.leftMargin: Padding.normal
                text: "filter_alt"
                font.pixelSize: 18
                color: TrackColorsService.colors.colOnLayer2
            }

            StyledText {
                text: qsTr("Isolate")
                color: TrackColorsService.colors.colOnLayer2
                font.pixelSize: Fonts.sizes.small
                Layout.fillWidth: true
            }

        }

    }

    // Share via KDE Connect
    MenuItem {
        text: qsTr("Share")
        height: 40
        enabled: KdeConnectService.selectedDeviceId !== ""
        onTriggered: {
            if (trackPath)
                KdeConnectService.shareFile(KdeConnectService.selectedDeviceId, trackPath);

        }

        background: Rectangle {
            color: parent.hovered ? TrackColorsService.colors.colLayer1Hover : "transparent"
            radius: Rounding.small
        }

        contentItem: RowLayout {
            spacing: Padding.normal
            Layout.leftMargin: Padding.large
            Layout.rightMargin: Padding.large

            MaterialSymbol {
                Layout.leftMargin: Padding.normal
                text: "share"
                font.pixelSize: 18
                color: parent.parent.enabled ? TrackColorsService.colors.colOnLayer2 : TrackColorsService.colors.colSubtext
            }

            StyledText {
                text: qsTr("Share")
                color: parent.parent.enabled ? TrackColorsService.colors.colOnLayer2 : TrackColorsService.colors.colSubtext
                font.pixelSize: Fonts.sizes.small
                Layout.fillWidth: true
                opacity: parent.parent.enabled ? 1 : 0.5
            }

        }

    }

    // Show in File Manager
    MenuItem {
        text: qsTr("Show in Files")
        height: 40
        onTriggered: {
            if (trackPath) {
                const dirPath = trackPath.substring(0, trackPath.lastIndexOf('/'));
                Qt.openUrlExternally("file://" + dirPath);
            }
        }

        background: Rectangle {
            color: parent.hovered ? TrackColorsService.colors.colLayer1Hover : "transparent"
            radius: Rounding.small
        }

        contentItem: RowLayout {
            spacing: Padding.normal
            Layout.leftMargin: Padding.large
            Layout.rightMargin: Padding.large

            MaterialSymbol {
                Layout.leftMargin: Padding.normal
                text: "folder_open"
                font.pixelSize: 18
                color: TrackColorsService.colors.colOnLayer2
            }

            StyledText {
                text: qsTr("Show in Files")
                color: TrackColorsService.colors.colOnLayer2
                font.pixelSize: Fonts.sizes.small
                Layout.fillWidth: true
            }

        }

    }

    background: StyledRect {
        color: TrackColorsService.colors.colLayer2
        radius: Rounding.large
        enableShadows: true
    }

}
