import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick.Controls

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

Scope {
    Variants {
        model: Quickshell.screens
        StyledPanel {
            id: root
            name: "beam"
            visible: reveal || hoverReveal || scrollReveal
            property var modelData
            property string state: "ai"
            property string query: ""
            property int detectionArea: scrollReveal ? 20 : 4
            property bool scrollReveal: Mem.options.beam.behavior.scrollToReveal
            property bool hoverReveal: Mem.options.beam.behavior.hoverToReveal
            property bool revealLauncherOnAction: true // For Revealing More Info panels if needed
            property bool reveal: GlobalStates.showBeam || (hoverReveal && beamMouseArea.containsMouse) || (Mem.options.beam.behavior.revealOnEmpty && !ToplevelManager.activeToplevel.activated)
            property bool addSeparatorForNotes: true
            property int expandedLitterThreshhold: 10
            property int mainRounding: Rounding.huge
            property int elevationValue: Mem.options.bar.behavior.position === "bottom" ? BarData.currentBarSize + Sizes.elevationValue : Sizes.elevationMargin
            property bool clearAiChatBeforeSearch: Mem.options.beam.behavior.clearAiChatBeforeSearch ?? false
            property string currentSearchSubstate: "search"
            property var suggestedApp: null
            property int mode: Mem.states.beam.appearance.mode ?? 0
            property var reg: ({
                    "ai": {
                        prefix: "",
                        icon: "thread_unread",
                        shape: MaterialShape.Shape.Ghostish,
                        placeholder: "Ask " + Ai.getModel(Mem.options.ai?.model).name + " Any Thing ..",
                        showHint: false,
                        showOsrButton: true
                    },
                    "commands": {
                        prefix: ";",
                        icon: "keyboard_return",
                        shape: MaterialShape.Shape.Oval,
                        placeholder: "Command Master ..",
                        showHint: true,
                        showOsrButton: false
                    },
                    "calc": {
                        prefix: "=",
                        icon: "calculate",
                        shape: MaterialShape.Shape.Hexagon,
                        placeholder: "Calculate ..",
                        showHint: true,
                        showOsrButton: false
                    },
                    "install": {
                        prefix: "$",
                        icon: "deployed_code_update",
                        shape: MaterialShape.Shape.SoftBurst,
                        placeholder: "Install ..",
                        showHint: false,
                        showOsrButton: false
                    },
                    "note": {
                        prefix: ",",
                        icon: "stylus",
                        shape: MaterialShape.Shape.Slanted,
                        placeholder: "Note ..",
                        showHint: false,
                        showOsrButton: false
                    },
                    "alarm": {
                        prefix: "`",
                        icon: "timer",
                        shape: MaterialShape.Shape.Diamond,
                        placeholder: "I Can Wake You ..",
                        showHint: false,
                        showOsrButton: false
                    },
                    "launch": {
                        prefix: ".",
                        icon: "rocket_launch",
                        shape: MaterialShape.Shape.Pentagon,
                        placeholder: "Launch App ..",
                        showHint: true,
                        showOsrButton: false
                    },
                    "timer": {
                        prefix: "~",
                        icon: "hourglass",
                        shape: MaterialShape.Shape.Clover8Leaf,
                        placeholder: "How Long ..",
                        showHint: false,
                        showOsrButton: false
                    },
                    "todo": {
                        prefix: "/",
                        icon: "task_alt",
                        shape: MaterialShape.Shape.Cookie4Sided,
                        placeholder: "Any plans ..?",
                        showHint: false,
                        showOsrButton: false
                    },
                    "ipc": {
                        prefix: "!",
                        icon: "moon_stars",
                        shape: MaterialShape.Shape.Pentagon,
                        placeholder: "Just Order ..?",
                        showHint: true,
                        showOsrButton: false
                    },
                    "search": {
                        prefix: "?",
                        icon: "search",
                        shape: MaterialShape.Shape.PixelCircle,
                        placeholder: "Wanna Search Google ..?",
                        showHint: true,
                        showOsrButton: false,
                        subStates: ({
                                "search": {
                                    prefix: "",
                                    icon: "search",
                                    searchQuery: "https://www.google.com/search?q=",
                                    shape: MaterialShape.Shape.PixelCircle
                                },
                                "yt_music": {
                                    prefix: "m",
                                    icon: "music_note",
                                    searchQuery: "https://music.youtube.com/search?q=",
                                    shape: MaterialShape.Shape.Bun
                                },
                                "spotify": {
                                    prefix: "s",
                                    icon: "music_cast",
                                    searchQuery: "https://open.spotify.com/search/",
                                    shape: MaterialShape.Shape.Cookie7Sided
                                },
                                "m3": {
                                    prefix: "i",
                                    icon: "glyphs",
                                    searchQuery: "https://fonts.google.com/icons?icon.query=",
                                    shape: MaterialShape.Shape.Cookie12Sided
                                },
                                "github": {
                                    prefix: "g",
                                    icon: "commit",
                                    searchQuery: "https://github.com/search?q=",
                                    shape: MaterialShape.Shape.Oval
                                }
                            })
                    },
                    "translate": {
                        prefix: ">",
                        icon: "translate",
                        shape: MaterialShape.Shape.Arrow,
                        placeholder: "Translate ..?",
                        showHint: true,
                        showOsrButton: false
                    },
                    "terminology": {
                        prefix: "<",
                        icon: "healing",
                        shape: MaterialShape.Shape.Pill,
                        placeholder: "Medical Term ..?",
                        showHint: true,
                        showOsrButton: false
                    }
                })

            anchors.bottom: true
            implicitWidth: Sizes.beamSizeExpanded.width + 2 * Rounding.huge
            implicitHeight: Sizes.beamSize.height + elevationValue
            kbFocus: true
            exclusiveZone: -1

            mask: Region {
                item: hoverDetectionArea
            }
            Item {
                id: hoverDetectionArea
                visible: root.hoverReveal
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                width: bg.implicitWidth
                height: root.detectionArea
            }

            Timer {
                id: idleTimer
                repeat: true
                running: root.reveal && query.length < 1 && !beamMouseArea.containsMouse
                interval: 5000
                onTriggered: root.hide()
            }

            Timer {
                id: screenshotProcessTimer
                interval: Mem.options.hacks.arbitraryRaceConditionDelay
                property bool autoSend: false
                onTriggered: processScreenshot(autoSend)
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                active: root.reveal
                onCleared: root.hide()
            }

            Connections {
                target: ScreenShotService
                function onScreenshotCompleted() {
                    ClipboardService.reload();
                    screenshotProcessTimer.start();
                }
            }

            Connections {
                target: ClipboardService
                function onImageDecoded(path) {
                    if (path && path !== "") {
                        root.revealSidebar();
                        Ai.attachFile(path);
                        if (screenshotProcessTimer.autoSend) {
                            Ai.sendUserMessage("Explain This Briefly");
                        }
                    }
                }
            }
            function getSearchSuggestions() {
                if (FirefoxBookmarksService.bookmarkTitles.length > 0) {
                    for (let i = 0; i < FirefoxBookmarksService.bookmarkTitles.length; i++) {
                        const bookmark = FirefoxBookmarksService.bookmarkTitles[i];
                        if (bookmark.toLowerCase().startsWith(root.query.substring(1))) {
                            return bookmark;
                        }
                    }
                }
            }
            function getIpcSuggestion() {
                if (Noon.avilableIpcCommands.length < 1) {
                    Noon.fetchIpcCommands();
                }
                for (let i = 0; i < Noon.avilableIpcCommands.length; i++) {
                    const cmd = Noon.avilableIpcCommands[i];
                    if (cmd.toLowerCase().startsWith(root.query.substring(2).toLowerCase())) {
                        return cmd;
                    }
                }
            }
            function updateSearchSubstate() {
                if (!root.query.startsWith("?")) {
                    root.currentSearchSubstate = "search";
                    return;
                }
                const secondChar = root.query.charAt(1);
                const subStates = reg.search.subStates;
                for (const [subName, subConfig] of Object.entries(subStates)) {
                    if (subConfig.prefix && secondChar === subConfig.prefix) {
                        root.currentSearchSubstate = subName;
                        return;
                    }
                }
                root.currentSearchSubstate = "search";
            }

            function getCommandSuggestion() {
                if (Noon.avilableSystemCommands.length < 1) {
                    Noon.fetchCommands();
                }
                for (let i = 0; i < Noon.avilableSystemCommands.length; i++) {
                    const cmd = Noon.avilableSystemCommands[i];
                    if (cmd.toLowerCase().startsWith(root.query.substring(2).toLowerCase())) {
                        return cmd;
                    }
                }
            }
            function processScreenshot(autoSend) {
                ClipboardService.getLatestImage();
            }

            function revealSidebar() {
                if (GlobalStates.sidebarOpen)
                    return;
                Mem.states.sidebar.apis.selectedTab = 0;
                Noon.callIpc("sidebar reveal API");
            }

            function handleImage(autoSend = false) {
                screenshotProcessTimer.autoSend = autoSend;
                ScreenShotService.takeScreenShot();
            }

            function hide() {
                GlobalStates.showBeam = false;
            }
            function getAppSuggestion() {
                const q = root.query.substring(1).trim().toLowerCase();

                if (q === "") {
                    root.suggestedApp = null;
                    return "";
                }

                const allApps = [...DesktopEntries.applications.values];
                let bestMatch = null;
                let bestScore = 0;

                for (let i = 0; i < allApps.length; i++) {
                    const app = allApps[i];
                    const name = (app.name || "").toLowerCase();
                    const genericName = (app.genericName || "").toLowerCase();
                    let score = 0;

                    if (name.startsWith(q)) {
                        score = 100 + (100 - name.length);
                    } else if (name.includes(q)) {
                        score = 50;
                    }

                    if (genericName.startsWith(q)) {
                        score = 90;
                    } else if (genericName.includes(q)) {
                        score = 45;
                    }

                    const words = name.split(/\s+/);
                    const acronym = words.map(w => w[0]).join('').toLowerCase();
                    if (acronym === q) {
                        score = 95;
                    }

                    if (score > bestScore) {
                        bestScore = score;
                        bestMatch = app;
                    }
                }

                root.suggestedApp = bestMatch;
                return bestMatch ? bestMatch.name : "";
            }

            function sendMessage() {
                root.processQuery();
                const text = inputField.text.trim();
                const prefixLength = reg[root.state]?.prefix?.length || 0;
                const cleanQuery = text.substring(prefixLength).trim();

                switch (root.state) {
                case "ai":
                    if (root.clearAiChatBeforeSearch) {
                        Ai.clearMessages();
                    }
                    root.revealSidebar();
                    Ai.sendUserMessage(root.query);
                    break;
                case "launch":
                    if (root.suggestedApp) {
                        const entry = DesktopEntries.byId(root.suggestedApp.id);
                        if (entry) {
                            entry.execute();
                        }
                    }
                    break;
                case "timer":
                    const duration = TimerService.parseTimeString(cleanQuery);
                    if (duration > 0) {
                        const id = TimerService.addTimer("Focus Time", duration);
                        TimerService.startTimer(id);
                        if (root.revealLauncherOnAction) {
                            Mem.states.sidebar.misc.selectedTabIndex = 2;
                            Noon.callIpc("sidebar reveal Misc");
                        }
                    }
                    break;
                case "todo":
                    if (cleanQuery.length > 0) {
                        TodoService.addTask(cleanQuery);
                    }
                    break;
                case "install":
                    if (cleanQuery.length > 0) {
                        Noon.installPkg(cleanQuery);
                    }
                    break;
                case "calc":
                    if (cleanQuery.length > 0) {
                        QalcService.calculate(cleanQuery)
                        ClipboardService.copy(QalcService.result)
                    }
                    break;
                case "ipc":
                    if (cleanQuery.length > 0) {
                        Noon.callIpc(cleanQuery);
                    }
                    break;
                case "search":
                    if (cleanQuery.length > 0) {
                        const currentData = reg.search.subStates[root.currentSearchSubstate];  // CHANGE THIS
                        const subPrefix = currentData.prefix;
                        const searchQuery = cleanQuery.substring(subPrefix.length);
                        const cmd = currentData.searchQuery + encodeURIComponent(searchQuery);
                        Noon.execDetached(["xdg-open", cmd]);
                    }
                    break;
                case "commands":
                    if (cleanQuery.length > 0) {
                        Noon.execDetached(["bash", "-c", cleanQuery]);
                    }
                    break;
                case "translate":
                    if (cleanQuery.length > 0) {
                        ClipboardService.copy(hintText.text);
                    }
                    break;
                case "note":
                    NotesService.note(cleanQuery + (root.addSeparatorForNotes ? "\n - - - " : ""));
                    break;
                case "alarm":
                    AlarmService.addTimer(cleanQuery, "Beam Timer");
                    if (root.revealLauncherOnAction) {
                        Mem.states.sidebar.misc.selectedTabIndex = 3;
                        Noon.callIpc("sidebar reveal Misc");
                    }
                    break;
                }

                root.query = "";
                root.suggestedApp = null;
                root.hide();
            }

            function handleHintText() {
                switch (root.state) {
                case "translate":
                    TranslatorService.translate(root.query.substring(1));
                    return TranslatorService.translatedText;
                case "launch":
                    return getAppSuggestion();
                case "search":
                    return getSearchSuggestions();
                case "calc":
                    QalcService.calculate(root.query.substring(1))
                    return QalcService.result
                case "ipc":
                    return getIpcSuggestion();
                case "commands":
                    return getCommandSuggestion();
                case "terminology":
                    const query = root.query.substring(1);
                    MedicalDictionaryService.search(query);  // Service handles debounce
                    return MedicalDictionaryService.getResult(query);
                }
                return "";
            }

            function processQuery() {
                const text = inputField.text.trim();

                for (const [stateName, config] of Object.entries(reg)) {
                    if (config.prefix && text.startsWith(config.prefix)) {
                        root.state = stateName;
                        return;
                    }
                }

                root.state = "ai";
            }

            MouseArea {
                id: beamMouseArea
                z: 0
                hoverEnabled: true
                anchors.fill: parent

                propagateComposedEvents: true
                scrollGestureEnabled: true
                onWheel: function (wheel) {
                    if (!root.scrollReveal)
                        return;
                    let scrollSum = 0;
                    let toggleThreshold = 20;
                    scrollSum += wheel.angleDelta.y;
                    if (!root.reveal && scrollSum <= -toggleThreshold) {
                        GlobalStates.showBeam = true;
                        scrollSum = 0;
                    } else if (root.reveal && scrollSum >= toggleThreshold) {
                        GlobalStates.showBeam = false;
                        scrollSum = 0;
                    }

                    wheel.accepted = true;
                }

                anchors {
                    bottomMargin: root.reveal && !GlobalStates.showOsdValues ? 0 : -(Sizes.beamSize.height + elevationValue - 2)

                    Behavior on bottomMargin {
                        Anim {}
                    }
                }

                Item {
                    anchors.fill: parent
                    StyledRect {
                        id: bg
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                        }

                        implicitHeight: Sizes.beamSize.height
                        implicitWidth: hintText.text.length > root.expandedLitterThreshhold || root.query.length > root.expandedLitterThreshhold ? Sizes.beamSizeExpanded.width : Sizes.beamSize.width

                        Behavior on implicitWidth {
                            Anim {}
                        }

                        states: [
                            State {
                                name: "floating"
                                when: root.mode === 0
                                PropertyChanges {
                                    target: bg
                                    anchors.bottomMargin: elevationValue
                                    bottomRadius: Rounding.huge
                                    topRadius: Rounding.huge
                                    enableBorders: true
                                }
                                PropertyChanges {
                                    target: c1
                                    visible: false
                                }
                            },
                            State {
                                name: "notch"
                                when: root.mode === 1
                                PropertyChanges {
                                    target: bg
                                    anchors.bottomMargin: -1
                                    bottomRadius: 0
                                    topRadius: Rounding.huge
                                    enableBorders: true
                                }
                                PropertyChanges {
                                    target: c1
                                    visible: false
                                }

                            },
                            State {
                                name: "corners"
                                when: root.mode === 2
                                PropertyChanges {
                                    target: bg
                                    anchors.bottomMargin: -1
                                    bottomRadius: 0
                                    topRadius: Rounding.huge
                                    enableBorders: false
                                }
                                PropertyChanges {
                                    target: c1
                                    visible: true
                                }

                            }

                        ]
                        transitions: [
                            Transition {
                                Anim {
                                    properties: "anchors.margins,anchors.bottomMargin,radius,topLeftRadius,topRightRadius,bottomLeftRadius,bottomRightRadius"
                                }
                                
                                Anim {
                                    properties: "anchors.topMargin,anchors.bottomMargin,opacity"
                                    targets: [c1, c2]
                                }
                            }
                        ]
                        color: Colors.colLayer0
                        enableShadows: true
                        enableBorders: true
                        clip: true

                        StyledRect {
                            id: sideRect
                            anchors {
                                top: parent.top
                                left: parent.left
                                bottom: parent.bottom
                                margins: 1
                            }
                            topLeftRadius: bg.topLeftRadius
                            enableShadows: true
                            color: "transparent" // Colors.colLayer2
                            implicitWidth: 60

                            MaterialShapeWrappedMaterialSymbol {
                                id: icon
                                anchors {
                                    centerIn: parent
                                    horizontalCenterOffset: Padding.tiny
                                }
                                implicitSize: 42
                                iconSize: 20
                                text: root.state === "search" ? (reg.search.subStates[root.currentSearchSubstate]?.icon || reg.search.icon) : (reg[root.state]?.icon || "search")
                                shape: root.state === "search" ? (reg.search.subStates[root.currentSearchSubstate]?.shape || reg.search.shape) : (reg[root.state]?.shape || MaterialShape.Shape.Bun)
                                fill: 1
                                colSymbol: inputField.focus ? Colors.colPrimary : Colors.colOnLayer3
                                color: inputField.focus ? Colors.colPrimaryContainer : Colors.colLayer3
                            }
                        }

                        TextField {
                            id: inputField
                            z: 10
                            anchors {
                                top: parent.top
                                right: buttonsRow.left
                                left: sideRect.right
                                bottom: parent.bottom
                                rightMargin: Padding.large
                                leftMargin: Padding.large
                            }
                            focus: grab.active
                            objectName: "inputField"
                            placeholderText: reg[root.state]?.placeholder || "Ask any thing ..."
                            text: root.query
                            background: null
                            selectionColor: Colors.colPrimaryContainer
                            selectedTextColor: Colors.m3.m3onPrimaryContainer
                            color: Colors.colOnLayer0
                            placeholderTextColor: Colors.colSubtext
                            selectByMouse: true

                            onTextChanged: {
                                root.query = text;
                                root.processQuery();
                                if (root.state === "search" && Object.keys(root.reg.search.subStates).length > 1) {
                                    root.updateSearchSubstate();
                                }
                            }

                            StyledText {
                                id: hintText
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    bottom: parent.bottom
                                    rightMargin: Padding.normal
                                }
                                animateChange:true
                                horizontalAlignment: Text.AlignRight
                                width: 450
                                elide: Text.ElideRight
                                wrapMode: TextEdit.Wrap
                                maximumLineCount: 2
                                font.pixelSize: Fonts.sizes.normal
                                color: Colors.colSubtext
                                opacity: 0.6
                                visible: reg[root.state]?.showHint || false
                                text: root?.handleHintText() || ""
                            }

                            font {
                                pixelSize: Fonts.sizes.normal
                                family: Fonts.family.main
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.hide();
                                    event.accepted = true;
                                }
                                if (event.key === Qt.Key_Return) {
                                    root.sendMessage();
                                    event.accepted = true;
                                }

                                if (event.key === Qt.Key_Tab) {
                                    if (root.state === "launch" && root.suggestedApp) {
                                        root.query = "." + root.suggestedApp.name;
                                        event.accepted = true;
                                    } else if (root.state === "translate" && hintText.text) {
                                        root.query = ">" + hintText.text;
                                        event.accepted = true;
                                    } else if (root.state === "commands" && hintText.text) {
                                        root.query = ";" + hintText.text;
                                        event.accepted = true;
                                    } else if (root.state === "ipc" && hintText.text) {
                                        root.query = "!" + hintText.text;
                                        event.accepted = true;
                                    } else if (root.state === "search" && hintText.text) {
                                        root.query = "?" + hintText.text;
                                        event.accepted = true;
                                    } else if (root.state === "calc" && hintText.text) {
                                        root.query = "=" + hintText.text;
                                        event.accepted = true;
                                    }
                                }

                                if (event.modifiers === Qt.ControlModifier) {
                                    if (event.key === Qt.Key_S) {
                                        root.handleImage(true);
                                        event.accepted = true;
                                    }
                                }
                            }
                        }

                        RowLayout {
                            id: buttonsRow
                            z: 10
                            spacing: Padding.verysmall
                            anchors {
                                top: bg.top
                                bottom: bg.bottom
                                right: bg.right
                                rightMargin: Padding.normal
                            }

                            RippleButtonWithIcon {
                                id: sendButton
                                releaseAction: () => root.sendMessage()
                                buttonRadius:root.mainRounding
                                visible: opacity > 0
                                opacity: inputField.text.length > 0 ? 1 : 0
                                materialIcon: "send"
                                implicitSize: bg.height * 0.75
                                Behavior on opacity {
                                    Anim {}
                                }
                            }

                            RippleButtonWithIcon {
                                id: osrButton
                                buttonRadius:root.mainRounding
                                releaseAction: () => root.handleImage(false)
                                materialIcon: "screenshot_region"
                                implicitSize: bg.height * 0.75
                                enabled: !ScreenShotService.isBusy
                                visible: reg[root.state]?.showOsrButton || false
                                Behavior on opacity {
                                    Anim {}
                                }
                            }
                        }
                    }
                    RoundCorner {
                        id:c1
                        corner:cornerEnum.bottomLeft
                        size:root.mainRounding
                        anchors {
                            bottom:bg.bottom
                            left:bg.right
                        }
                    }
                    RoundCorner {
                        id:c2
                        visible:c1.visible
                        corner:cornerEnum.bottomRight
                        size:root.mainRounding
                        anchors {
                            bottom:bg.bottom
                            right:bg.left
                        }
                    }

                }
            }
        }
    }
}
