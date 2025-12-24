import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root
    property int selectedPlayerIndex: BeatsService.selectedPlayerIndex
    onSelectedPlayerIndexChanged: BeatsService.selectedPlayerIndex = selectedPlayerIndex

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: playerSelector.width + 10
    Layout.preferredHeight: playerSelector.height + 10
    Layout.bottomMargin: -10
    radius: 15
    enableShadows: true
    color: TrackColorsService.colors.colSecondaryContainer
    visible: BeatsService.meaningfulPlayers.length > 1

    function getPlayerIcon(dbus) {
        if (!dbus) return "music_note";
        if (dbus.includes("spotify")) return "queue_music";
        if (dbus.includes("firefox") || dbus.includes("chromium")) return "web";
        if (dbus.includes("vlc")) return "play_circle";
        if (dbus.includes("mpv")) return "video_library";
        if (dbus.includes("mpd")) return "library_music";
        return "music_note";
    }

    function getPlayerName(player, index) {
        return player?.identity || player?.dbusName?.replace("org.mpris.MediaPlayer2.", "") || "Player " + (index + 1);
    }

    Grid {
        id: playerSelector
        anchors.centerIn: parent
        spacing: 4
        rows: 1
        columns: BeatsService.meaningfulPlayers.length

        Repeater {
            model: BeatsService.meaningfulPlayers
            delegate: RippleButtonWithIcon {
                implicitSize: 20
                buttonRadius: Rounding.full
                
                readonly property bool isSelected: index === root.selectedPlayerIndex

                toggled: isSelected
                colBackground: isSelected ? TrackColorsService.colors.colPrimary : TrackColorsService.colors.colSecondaryContainer
                colBackgroundHover: isSelected ? TrackColorsService.colors.colPrimaryHover : TrackColorsService.colors.colSecondaryContainerHover
                colRipple: isSelected ? TrackColorsService.colors.colPrimary : TrackColorsService.colors.colSecondaryContainerActive
                
                materialIcon: root.getPlayerIcon(modelData?.dbusName)
                iconColor: isSelected ? TrackColorsService.colors.colOnPrimary : TrackColorsService.colors.colOnSecondaryContainer
                
                onClicked: {
                    root.selectedPlayerIndex = index;
                    Mem.states.services.mediaPlayer.selectedPlayerIndex = index;
                }

                StyledToolTip {
                    extraVisibleCondition: hovered
                    content: root.getPlayerName(modelData, index)
                }
            }
        }
    }
}
