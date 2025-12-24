import qs.services
import qs.store
import qs.modules.bar.components
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland

MouseArea {
    id: root
    required property var bar
    hoverEnabled: true
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    height: rotatedContainer.height
    width: BarData.currentBarExclusiveSize
    Loader {
        active: HyprlandService.isHyprland && Mem.states.services.wm.hypr
        sourceComponent: WorkspacePopup {
            hoverTarget: root
        }
    }
    // Extended app substitution map (name + Nerd Font icon)
    readonly property var appSubstitutions: ({
            // Browsers
            "google-chrome": {
                name: "Chrome",
                icon: ""
            }          // nf-fa-chrome
            ,
            "chromium": {
                name: "Chromium",
                icon: ""
            },
            "firefox": {
                name: "Firefox",
                icon: ""
            }               // nf-fa-firefox
            ,
            "librewolf": {
                name: "LibreWolf",
                icon: "󰈹"
            }          // nf-md-firefox
            ,
            "brave-browser": {
                name: "Brave",
                icon: "󰂟"
            }          // nf-md-brave
            ,
            "microsoft-edge": {
                name: "Edge",
                icon: "󰇩"
            }          // nf-md-microsoft_edge

            ,

            // Editors / IDEs
            "code-oss": {
                name: "VS Code",
                icon: "󰨞"
            }              // nf-md-microsoft_visual_studio_code
            ,
            "code": {
                name: "VS Code",
                icon: "󰨞"
            },
            "cursor": {
                name: "Cursor",
                icon: "󰨞"
            },
            "idea": {
                name: "IntelliJ IDEA",
                icon: ""
            }            // nf-dev-intellij
            ,
            "pycharm": {
                name: "PyCharm",
                icon: ""
            }               // nf-dev-python
            ,
            "subl": {
                name: "Sublime Text",
                icon: ""
            }             // nf-dev-sublime
            ,
            "nvim": {
                name: "Neovim",
                icon: ""
            }                   // nf-custom-neovim

            ,

            // File managers
            "org.kde.dolphin": {
                name: "Files",
                icon: ""
            }         // nf-fa-folder
            ,
            "nautilus": {
                name: "Files",
                icon: ""
            }                // nf-fa-folder_open
            ,
            "thunar": {
                name: "Files",
                icon: "󰉋"
            }                  // nf-md-folder
            ,
            "pcmanfm": {
                name: "Files",
                icon: "󰉋"
            },

            // Terminals
            "gnome-terminal": {
                name: "Terminal",
                icon: ""
            }       // nf-dev-terminal
            ,
            "alacritty": {
                name: "Alacritty",
                icon: "󰆍"
            }           // nf-md-console
            ,
            "kitty": {
                name: "Kitty",
                icon: "󰄛"
            }                   // nf-md-cat
            ,
            "foot": {
                name: "Foot",
                icon: ""
            },
            "wezterm": {
                name: "WezTerm",
                icon: ""
            },

            // Communication
            "telegram-desktop": {
                name: "Telegram",
                icon: ""
            }     // nf-fa-telegram
            ,
            "discord": {
                name: "Discord",
                icon: "󰙯"
            }               // nf-md-discord
            ,
            "whatsapp": {
                name: "WhatsApp",
                icon: "󰖣"
            }             // nf-md-whatsapp
            ,
            "signal": {
                name: "Signal",
                icon: "󰭹"
            }                 // nf-md-message
            ,
            "slack": {
                name: "Slack",
                icon: "󰒱"
            }                   // nf-md-slack
            ,
            "zoom": {
                name: "Zoom",
                icon: "󰍉"
            }                     // nf-md-video

            ,

            // Media / Music
            "spotify": {
                name: "Spotify",
                icon: ""
            }               // nf-fa-spotify
            ,
            "vlc": {
                name: "VLC",
                icon: "󰕼"
            }                      // nf-md-video
            ,
            "mpv": {
                name: "MPV",
                icon: "󰕼"
            },
            "youtube-music": {
                name: "YT Music",
                icon: "󰗃"
            }        // nf-md-youtube
            ,
            "rhythmbox": {
                name: "Music",
                icon: "󰝚"
            }               // nf-md-music
            ,
            "audacious": {
                name: "Audacious",
                icon: "󰝚"
            },

            // Utilities
            "org.gnome.calculator": {
                name: "Calculator",
                icon: "󰃬"
            } // nf-md-calculator
            ,
            "gnome-system-monitor": {
                name: "Monitor",
                icon: ""
            }  // nf-oct-dashboard
            ,
            "htop": {
                name: "Htop",
                icon: "󰍛"
            },
            "obs": {
                name: "OBS Studio",
                icon: "󰐯"
            }                // nf-md-video_wireless
            ,
            "gimp": {
                name: "GIMP",
                icon: ""
            }                     // nf-fa-paint_brush
            ,
            "inkscape": {
                name: "Inkscape",
                icon: ""
            },
            "kdenlive": {
                name: "Kdenlive",
                icon: "󰕧"
            }             // nf-md-video_edit
            ,
            "blender": {
                name: "Blender",
                icon: "󰂫"
            }               // nf-md-cube

            ,

            // System / Settings
            "systemsettings": {
                name: "Settings",
                icon: "󰒓"
            }       // nf-md-cog
            ,
            "gnome-control-center": {
                name: "Settings",
                icon: "󰒓"
            },
            "nemo": {
                name: "Files",
                icon: ""
            },
            "nm-connection-editor": {
                name: "Network",
                icon: "󰤨"
            } // nf-md-wifi
            ,
            "blueman-manager": {
                name: "Bluetooth",
                icon: "󰂯"
            }    // nf-md-bluetooth
            ,
            "pavucontrol": {
                name: "Audio",
                icon: "󰓃"
            }            // nf-md-volume_high

            ,

            // Dev Tools / Misc
            "postman": {
                name: "Postman",
                icon: "󰚩"
            },
            "insomnia": {
                name: "Insomnia",
                icon: "󰚩"
            },
            "docker": {
                name: "Docker",
                icon: "󰡨"
            },
            "virt-manager": {
                name: "VM Manager",
                icon: "󰨈"
            },
            "steam": {
                name: "Steam",
                icon: ""
            }                  // nf-fa-steam
            ,
            "lutris": {
                name: "Lutris",
                icon: "󰺵"
            },
            "heroic": {
                name: "Heroic",
                icon: "󰺵"
            }
        })
    readonly property bool icons: false
    readonly property string currentAppId: activeWindow?.activated ? activeWindow?.appId : ""
    readonly property var currentApp: currentAppId && appSubstitutions[currentAppId] ? appSubstitutions[currentAppId] : ({
            name: currentAppId || "HyprNoon",
            icon: ""
        }) // default: window icon

    Item {
        id: rotatedContainer
        anchors.centerIn: parent
        width: row.implicitHeight
        height: row.implicitWidth
        rotation: -90
        transformOrigin: Item.Center

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6

            StyledText {
                id: iconText
                visible: root.icons
                text: currentApp.icon + "  "
                font.pixelSize: BarData.currentBarExclusiveSize * BarData.barPadding / 1.5
                font.family: Fonts.family.monospace
                color: Colors.colOnLayer1
            }

            StyledText {
                id: nameText
                text: currentApp.name
                font.pixelSize: BarData.currentBarExclusiveSize * BarData.barPadding / 1.5
                font.family: Fonts.family.monospace
                color: Colors.colOnLayer1
                elide: Text.ElideRight
                maximumLineCount: 1
                font.weight: Font.DemiBold
                animateChange: true
            }
        }
    }
}
