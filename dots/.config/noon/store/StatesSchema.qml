pragma ComponentBehavior: Bound
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

JsonAdapter {
    property JsonObject desktop: JsonObject {
        property JsonObject icons
        property JsonObject bg
        property JsonObject appearance
        property JsonObject clock

        icons: JsonObject {
            property string currentIconTheme: ""
            property list<var> availableIconThemes: []
        }

        bg: JsonObject {
            property bool isLive: false
            property string currentVideo: ""
            property string currentBg: ""
            property string currentFolder: ""
        }

        appearance: JsonObject {
            property JsonObject colors

            property bool autoSchemeSelection: false
            property bool autoShellMode: false
            property string mode: "dark"
            property string scheme: ""

            colors: JsonObject {
                property real chroma: 1
                property real tone: 1
            }
        }

        clock: JsonObject {
            property bool center
            property real scale: 1
        }
    }

    property JsonObject services: JsonObject {
        property JsonObject kdeconnect
        property JsonObject bookmarks
        property JsonObject wm
        property JsonObject emojis
        property JsonObject ambientSounds
        property JsonObject mediaPlayer

        kdeconnect: JsonObject {
            property list<var> devices: []
            property list<var> availableDevices: []
            property string selectedDeviceId: ""
            property string myDeviceId: ""
        }

        bookmarks: JsonObject {
            property list<var> firefoxBookmarks: []
        }

        wm: JsonObject {
            property bool hypr: true
            property bool niri: true
        }

        emojis: JsonObject {
            property list<var> frequentEmojies: []
        }

        ambientSounds: JsonObject {
            property real masterVolume: 1
            property bool masterPaused: false
            property bool muted: false
            property list<var> availableSounds: []
            property list<var> activeSounds: []
        }

        mediaPlayer: JsonObject {
            // property string selectedPlayerDbusName: ""
            property int selectedPlayerIndex: 0
        }
    }

    property JsonObject fonts: JsonObject {
        property JsonObject variableAxes

        variableAxes: JsonObject {
            property JsonObject display

            display: JsonObject {
                property int wght: 100
                property int wdth: 100
                property int ital: 100
                property int slnt: 100
                property int opsz: 100
            }
        }
    }

    property JsonObject beam: JsonObject {
        property JsonObject appearance

        appearance: JsonObject {
            property int mode: 0
        }
    }

    property JsonObject dock: JsonObject {
        property bool pinned: false
        property list<var> pinnedApps: ["firefox", "dolphin"]
    }
    property JsonObject misc:JsonObject {
        property list<string> ipcCommands: []
        property list<string> systemCommands: []
    }
    property JsonObject sidebarLauncher: JsonObject {
        property JsonObject behavior
        property JsonObject misc
        property JsonObject apis

        behavior: JsonObject {
            property bool expanded: false
            property bool pinned: false
        }

        misc: JsonObject {
            property int selectedTabIndex: 0
        }

        apis: JsonObject {
            property int selectedTab: 0
            property real fontScale: 1
        }
    }

    property JsonObject mediaPlayer: JsonObject {
        property string currentTrackPath: ""
    }
}
