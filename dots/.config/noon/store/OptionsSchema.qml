pragma ComponentBehavior: Bound
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

JsonAdapter {
    property JsonObject appearance: JsonObject {
        property JsonObject animations
        property JsonObject colors
        property JsonObject transparency
        property JsonObject rounding
        property JsonObject padding
        property JsonObject icons
        property JsonObject fonts

        animations: JsonObject {
            property real scale: 1
        }

        colors: JsonObject {
            property string palatteName: "auto"
            property bool palatte: false
        }

        transparency: JsonObject {
            property bool blur: true
            property bool enabled: false
            property real scale: 0.7
            property bool applications: false
        }

        rounding: JsonObject {
            property real scale: 1
            property real power: 2
        }

        padding: JsonObject {
            property real scale: 1
        }

        icons: JsonObject {
            property bool tint: false
        }

        fonts: JsonObject {
            property real scale: 1
            property string main: "Google Sans Flex"
        }
    }

    property JsonObject policies: JsonObject {
        property int ai: 1
        property int translator: 1
        property int medicalDictionary: 1
    }

    property JsonObject ai: JsonObject {
        property string systemPrompt: "## Style
        - Use Egyptian dilect casual tone,don't change the language by yourself only if the user explicitly asked for , don't be formal! Make sure you answer precisely without hallucination and prefer bullet points over walls of text. You can have a friendly greeting at the beginning of the conversation, but don't repeat the user's question

        ## Context (ignore when irrelevant)
        - You are el 3etrah a funny and inspiring male assistant on a sidebar of {DISTRO} Linux system
        - The username is {USER}- Desktop environment: {DE}
        - current window manager is Hyprland -Current City {LOCATION}-Current Temp: {WEATHER}- Current date & time: {DATETIME}
        - Focused app: {WINDOWCLASS}

         U have both read and set access to users tasts {TASKS} , notes {NOTES} alarms {ALARMS},were u manage his tasks and give useful info if needed also see and manage timers with the {TIMERS},the user is listining to {PLAYING},don't mention your capabilities unless user asks for it , don't be too noosy when talking espicially on greetings ,use emojies but not too much and use constant defined ones ## Presentation
        - Use Markdown features in your response:
          - **Bold** text to **highlight keywords** in your response
          - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.
        - Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!
        - Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).
"
        property string tool: "search"
        property list<var> extraModels: []
        property string model: "gemini-2.5-flash"
        property real temperature: 0.5
    }

    property JsonObject audio: JsonObject {
        property JsonObject protection

        protection: JsonObject {
            property bool enable: false
            property real maxAllowedIncrease: 100
            property real maxAllowed: 200
        }
    }

    property JsonObject interactions: JsonObject {
        property JsonObject scrolling

        scrolling: JsonObject {
            property bool fasterTouchpadScroll: true
            property int mouseScrollDeltaThreshold: 120
            property int mouseScrollFactor: 120
            property int touchpadScrollFactor: 600
        }
    }

    property JsonObject apps: JsonObject {
        property string bluetooth: "kcmshell6 kcm_bluetooth"
        property string imageViewer: "loupe"
        property string network: "plasmawindowed org.kde.plasma.networkmanagement"
        property string networkEthernet: "kcmshell6 kcm_networkmanagement"
        property string settings: "systemsettings"
        property string taskManager: "plasma-systemmonitor --page-name Processes"
        property string terminal: "kitty"
    }

    property JsonObject services: JsonObject {
        property JsonObject idle
        property JsonObject todo
        property JsonObject time
        property JsonObject prayer
        property JsonObject weather
        property JsonObject recording
        property JsonObject notifications
        property JsonObject ambientSounds

        property string backlightDevice: ""
        property bool easyEffects: false
        property string location: "Cairo"

        idle: JsonObject {
            property int timeOut: 10000
            property bool inhibit: false
        }

        todo: JsonObject {
            property bool enableTodoist: true
        }

        time: JsonObject {
            property bool use12HourFormat: true
            property bool autoNightLightCycle: false
        }

        prayer: JsonObject {
            property string method: "Egyptian"
        }

        weather: JsonObject {
            property bool useFehrenheit: false
        }

        recording: JsonObject {
            property int recordingMode: 0
            property int audioMode: 1
            property int quality: 1
            property string customOutputPath: ""
            property bool showCursor: true
            property int customFramerate: 0
        }

        notifications: JsonObject {
            property bool silent: false
        }

        ambientSounds: JsonObject {}
    }

    property JsonObject resources: JsonObject {
        property int updateInterval: 10000
    }

    property JsonObject battery: JsonObject {
        property bool automaticSuspend: true
        property int low: 20
        property int critical: 5
        property int suspend: 2
    }

    property JsonObject games: JsonObject {
        property bool launchWithGameMode: false
    }

    property JsonObject beam: JsonObject {
        property JsonObject behavior: JsonObject {
            property bool scrollToReveal: true
            property bool hoverToReveal: false
            property bool revealOnEmpty: false
            property bool clearAiChatBeforeSearch: false
        }
    }

    property JsonObject sidebar: JsonObject {
        property JsonObject content
        property JsonObject behavior
        property JsonObject appearance

        property bool pinned: false

        content: JsonObject {
            property bool tasks: true
            property bool history: true
            property bool emojies: true
            property bool notifs: true
            property bool notes: true
            property bool barSwitcher: true
            property bool beats: true
            property bool tweaks: true
            property bool wallpapers: true
            property bool session: true
            property bool overview: false
            property bool misc: true
            property bool games: false
            property bool gallery: false
            property bool scripts: false
            property bool movies: false
            property bool documents: false
        }

        behavior: JsonObject {
            property bool overlay: false
            property bool preExpand: false
            property bool aiTextFadeIn: false
            property bool superHeldReveal: false
        }

        appearance: JsonObject {
            property bool useAppListView: false
            property int mode: 2
            property bool showNavTitles: false
            property bool showSliders: true
            property bool showVolumeInputSlider: false
        }
    }

    property JsonObject osd: JsonObject {
        property int timeout: 1000
        property bool enabled: false
    }

    property JsonObject osk: JsonObject {
        property string layout: "qwerty_full"
    }

    property JsonObject search: JsonObject {
        property int nonAppResultDelay: 120
        property bool sloppy: false
    }

    property JsonObject language: JsonObject {
        property JsonObject translator

        translator: JsonObject {
            property int delay: 100
            property string engine: "auto"
            property string targetLanguage: "العربية"
            property string sourceLanguage: "auto"
        }
    }

    property JsonObject networking: JsonObject {
        property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    }

    property JsonObject mediaPlayer: JsonObject {
        property bool useBlur: false
        property bool enableGrad: false
        property bool adaptiveTheme: false
        property string visualizerMode: ""
        property bool showVisualizer: false
        property bool lyrics: false
    }

    property JsonObject desktop: JsonObject {
        property JsonObject bg
        property JsonObject clock
        property JsonObject view
        property JsonObject lock
        property JsonObject greetd
        property JsonObject icons
        property JsonObject hyprland
        property JsonObject behavior

        property bool desktopClock: true
        property int screenCorners: 1
        property bool timerOverlayMode: true
        view: JsonObject {
            property string mode: "spiral"
        }
        bg: JsonObject {
            property JsonObject parallax

            property real borderMultiplier: 0.2
            property bool depthMode: true
            property bool useQs: true

            parallax: JsonObject {
                property bool enabled: false
                property bool widgetParallax: false
                property bool verticalParallax: false
                property real parallaxStrength: 0.0
            }
        }

        clock: JsonObject {
            property real x: 0
            property real y: 0
            property real scale: 1
            property real spacingMultiplier: 0.3
            property bool editMode: false
            property bool verticalMode: false
            property string font: "Badeen Display"
        }

        lock: JsonObject {
            property bool enabled: true
            property string pfp: ".face.png"
        }

        greetd: JsonObject {
            property bool enabled: false
        }

        icons: JsonObject {}

        hyprland: JsonObject {
            property bool playSoundOnFocusChanged: false
            property string tilingLayout: "dwindle"
        }

        behavior: JsonObject {
            property JsonObject sounds

            sounds: JsonObject {
                property bool enabled: true
                property real level: 0.75
            }
        }
    }

    property JsonObject bar: JsonObject {
        property JsonObject appearance
        property JsonObject behavior
        property JsonObject modules
        property JsonObject keyboard
        property JsonObject workspaces

        property bool enabled: true
        property int batteryLowThreshold: 20
        property int spacing: 4
        property int currentLayout: 0
        property int currentVerticalLayout: 0
        property list<string> vLayout: ["materialStatusIcons", "nightlight", "weather", "separator", "battery", "separator", "sysTray", "spacer", "title", "spacer", "media", "resources", "separator", "volume", "brightness", "separator", "workspaces", "separator", "clock", "separator", "keyboard", "separator", "power"]
        property list<string> hLayout: ["logo", "title", "spacer", "spacer", "resources", "media", "workspaces", "clock", "weather", "utilButtons", "battery", "spacer", "spacer", "spacer", "sysTray", "materialStatusIcons"]

        appearance: JsonObject {
            property int mode: 2
            property bool enableSeparators: true
            property bool useBg: true
            property bool modulesBg: false
            property bool outline: true
            property int height: 38
            property int width: 36
        }

        behavior: JsonObject {
            property string position: "left"
            property bool autoHide: false
            property bool showOnAll: true
        }

        modules: JsonObject {
            property bool visualizer: false
        }

        keyboard: JsonObject {
            property list<var> keyboardLayoutShortNames: ({
                    "English (US)": "US",
                    "Arabic": "AR"
                })
        }

        workspaces: JsonObject {
            property int shownWs: 3
            property bool showAppIcons: true
            property string displayMode: "normal"
            property string customFallback: "●"
            property list<string> avilableModes: ["normal", "japanese", "roman", "custom"]
            property list<string> customMapping: ["○", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        }
    }

    property JsonObject dock: JsonObject {
        property JsonObject appearance

        property bool enabled: false
        property bool hoverToReveal: true

        appearance: JsonObject {
            property real iconSize: 100 * iconSizeMultiplier
            property real iconSizeMultiplier: 0.5
        }
    }

    property JsonObject hacks: JsonObject {
        property int arbitraryRaceConditionDelay: 100
        property bool eglFallbacks: true
        property int superHeldInterval: 300
    }
}
