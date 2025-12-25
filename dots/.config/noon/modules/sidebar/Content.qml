import "./components/apis"
import "./components/beats"
import "./components/gallary"
import "./components/games"
import "./components/misc"
import "./components/notes"
import "./components/notifs"
import "./components/polkit"
import "./components/session"
import "./components/settings"
import "./components/tasks"
import "./components/view"
import "./components/wallpapers"
import "./components/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.store

FocusScope {
    id: root

    property bool showContent: false
    property bool rightMode: true
    property bool clearAppListOnHide: true
    property string searchText: ""
    property string selectedCategory: "Apps"
    property bool expanded: false
    property bool _manualExpandedToggle: false
    property bool effectiveSearchable: SidebarData.isSearchable(selectedCategory)
    property bool pinned: false
    property color contentColor: selectedCategory === "Beats" && Mem.options.mediaPlayer.adaptiveTheme ? TrackColorsService.colors.colLayer0 : Colors.colLayer0
    required property var panelWindow
    // Auxiliary component properties
    property bool auxVisible: false
    property string auxCategory: ""
    property string auxSearchText: ""
    readonly property var componentMap: ({
        "WallpaperSelector": wallpaperselectorcomponent,
        "OverviewWidget": overviewcomponent,
        "KanbanWidget": kanbancomponent,
        "PowerMenu": sessioncomponent,
        "API": apicomponent,
        "StyledNotifications": notificationscomponent,
        "Beats": beatscomponent,
        "AppListView": listviewcomponent,
        "AppGridView": gridviewcomponent,
        "Tweaks": tweakscomponent,
        "Notes": notesComponent,
        "GalleryWidget": gallerycomponent,
        "MiscComponent": misccomponent,
        "Auth": polkitComponent,
        "Games": gamescomponent
    })

    signal requestPin()
    signal barLayoutChangeRequested(int layoutIndex, bool isVertical)
    signal appLaunched(var app)
    signal contentToggleRequested()
    signal hideBarRequested()
    signal dismiss()

    // Helper to focus search input
    function focusSearchInput() {
        const mainPanel = panelRepeater.itemAt(0);
        if (mainPanel && mainPanel.searchInput && effectiveSearchable)
            mainPanel.searchInput.forceActiveFocus();

    }

    function updateAppList(isAux = false) {
        const category = isAux ? auxCategory : selectedCategory;
        const query = isAux ? auxSearchText : searchText;
        const model = isAux ? auxModel : mainModel;
        if (!category || (isAux && !auxVisible)) {
            model.clear();
            return ;
        }
        if (!isAux && (!showContent || !GlobalStates.sidebarOpen)) {
            if (clearAppListOnHide)
                model.clear();

            return ;
        }
        if (!SidebarData.hasModel(category)) {
            model.clear();
            return ;
        }
        const params = {
            "frequentEmojis": EmojisService.frequentEmojis,
            "horizontalLayouts": BarData.horizontalLayouts,
            "verticalLayouts": BarData.verticalLayouts,
            "isVerticalBar": BarData.verticalBar,
            "currentHorizontalLayout": Mem.options.bar.currentLayout,
            "currentVerticalLayout": Mem.options.bar.currentVerticalLayout
        };
        const results = SidebarData.generateData(category, query.trim(), params);
        model.clear();
        for (let i = 0; i < results.length; ++i) {
            model.append(results[i]);
        }
    }

    function auxReveal(category) {
        if (!category || (category !== "Auth" && !SidebarData.enabledCategories.includes(category))) {
            console.warn("Category not enabled:", category);
            return ;
        }
        const isSameCategory = auxCategory === category;
        if (isSameCategory && auxVisible) {
            closeAuxPanel();
            return ;
        }
        // Guard: prevent duplicate content between main and aux panels
        if (category === selectedCategory && showContent) {
            console.warn("Category already displayed in main panel:", category);
            return ;
        }
        auxCategory = category;
        auxSearchText = "";
        auxVisible = true;
        if (SidebarData.hasModel(category)) {
            auxModel.clear();
            auxDelayedRefresh.restart();
        }
    }

    function closeAuxPanel() {
        auxVisible = false;
        auxCategory = "";
        auxSearchText = "";
        auxModel.clear();
    }

    function requestCategoryChange(newCategory, initialQuery = "") {
        if (newCategory !== "Auth" && !SidebarData.enabledCategories.includes(newCategory)) {
            console.warn("Category not enabled:", newCategory);
            return ;
        }
        const isSameCategory = selectedCategory === newCategory;
        const isExpanded = showContent && GlobalStates.sidebarOpen;
        if (isSameCategory && isExpanded) {
            selectedCategory = "";
            dismiss();
            return ;
        }
        if (!GlobalStates.sidebarOpen)
            GlobalStates.sidebarOpen = true;

        selectedCategory = newCategory;
        resetSearch(initialQuery);
        if (!showContent)
            Qt.callLater(() => {
            contentToggleRequested();
        });

    }

    function resetSearch(newQuery = "") {
        searchText = newQuery;
    }

    function switchToLayout(layoutIndex, isVertical) {
        if (isVertical)
            Mem.options.bar.currentVerticalLayout = layoutIndex;
        else
            Mem.options.bar.currentLayout = layoutIndex;
        barLayoutChangeRequested(layoutIndex, isVertical);
    }

    function handleRootKeys(event) {
        const key = event.key;
        const mods = event.modifiers;
        if (key === Qt.Key_Escape) {
            dismiss();
            event.accepted = true;
            return true;
        }
        if (key === Qt.Key_Tab || key === Qt.Key_Backtab) {
            let targetCategory;
            if (mods === Qt.ShiftModifier || mods === (Qt.ControlModifier | Qt.ShiftModifier))
                targetCategory = SidebarData.getPreviousEnabledCategory(selectedCategory);
            else if (mods === 0)
                targetCategory = SidebarData.getNextEnabledCategory(selectedCategory);
            if (targetCategory) {
                requestCategoryChange(targetCategory);
                event.accepted = true;
                return true;
            }
        }
        if (mods === Qt.ControlModifier) {
            if (key === Qt.Key_O && SidebarData.isExpandable(selectedCategory)) {
                // Don't allow manual collapse when aux is visible
                if (auxVisible && expanded) {
                    event.accepted = true;
                    return true;
                }
                _manualExpandedToggle = true;
                expanded = !expanded;
                event.accepted = true;
                return true;
            } else if (key === Qt.Key_P) {
                Qt.callLater(() => {
                    return requestPin();
                });
                event.accepted = true;
                return true;
            } else if (key === Qt.Key_Q) {
                Qt.callLater(() => {
                    return closeAuxPanel();
                });
                event.accepted = true;
                return true;
            } else if (key === Qt.Key_R && selectedCategory === "History") {
                ClipboardService.wipe();
                delayedRefresh.restart();
                event.accepted = true;
                return true;
            }
        }
        const isWallpapers = selectedCategory === "Walls";
        const shouldHandleViewKeys = (effectiveSearchable && mainModel.count > 0) || isWallpapers;
        if (shouldHandleViewKeys) {
            if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                const firstApp = mainModel.get(0);
                if (firstApp && effectiveSearchable) {
                    SidebarData.launchApp(firstApp);
                    event.accepted = true;
                    return true;
                }
            }
        }
        if (mods === Qt.ControlModifier && isWallpapers) {
            const mainPanelItem = panelRepeater.itemAt(0);
            const loader = mainPanelItem ? mainPanelItem.children[mainPanelItem.children.length - 2] : null;
            const view = loader ? loader.item : null;
            if (view) {
                switch (key) {
                case Qt.Key_Left:
                    WallpaperService.goBack();
                    break;
                case Qt.Key_S:
                    if (typeof view.shuffleWallpapers === 'function')
                        view.shuffleWallpapers();

                    break;
                }
                event.accepted = true;
                return true;
            }
        }
        return false;
    }

    clip: true
    focus: true
    onShowContentChanged: {
        if (showContent && GlobalStates.sidebarOpen)
            Qt.callLater(focusSearchInput);

        if (!showContent && clearAppListOnHide)
            mainModel.clear();

    }
    onEffectiveSearchableChanged: {
        if (showContent && GlobalStates.sidebarOpen)
            Qt.callLater(focusSearchInput);

    }
    onSelectedCategoryChanged: {
        mainModel.clear();
        resetSearch("");
        if (SidebarData.hasModel(selectedCategory))
            delayedRefresh.restart();

    }
    onAuxCategoryChanged: {
        auxModel.clear();
        auxSearchText = "";
        if (auxCategory && SidebarData.hasModel(auxCategory))
            auxDelayedRefresh.restart();

    }
    Keys.onPressed: (event) => {
        return handleRootKeys(event);
    }
    anchors.fill: parent
    anchors.margins: Padding.large

    // Data models for panels
    ListModel {
        id: mainModel
    }

    ListModel {
        id: auxModel
    }

    Connections {
        function onSidebarOpenChanged() {
            if (GlobalStates.sidebarOpen && showContent)
                Qt.callLater(root.focusSearchInput);

        }

        target: GlobalStates
    }

    // Listen to searchFocusRequested from main panel
    Connections {
        function onSearchFocusRequested() {
            root.focusSearchInput();
        }

        target: panelRepeater.itemAt(0)
        ignoreUnknownSignals: true
    }

    Binding {
        target: root
        property: "expanded"
        value: {
            // Force expand when aux is visible
            if (auxVisible)
                return true;

            // Otherwise use category's pre-expand setting
            return SidebarData.usePreExpand(selectedCategory) && SidebarData.isExpandable(selectedCategory);
        }
        when: !_manualExpandedToggle
    }

    Timer {
        id: delayedRefresh

        interval: Mem.options.hacks.arbitraryRaceConditionDelay ?? 100
        repeat: false
        onTriggered: {
            if (SidebarData.hasModel(selectedCategory))
                updateAppList(false);

        }
    }

    Timer {
        id: auxDelayedRefresh

        interval: Mem.options.hacks.arbitraryRaceConditionDelay ?? 100
        repeat: false
        onTriggered: {
            if (auxCategory && SidebarData.hasModel(auxCategory))
                updateAppList(true);

        }
    }

    Connections {
        function onFlowChanged() {
            const authRegistry = SidebarData.registry["Auth"];
            if (!authRegistry)
                return ;

            if (PolkitService.flow !== null) {
                authRegistry.enabled = true;
                if (!showContent)
                    contentToggleRequested();

                if (selectedCategory !== "Auth")
                    requestCategoryChange("Auth");

                Qt.callLater(focusSearchInput);
            } else {
                authRegistry.enabled = false;
                if (selectedCategory === "Auth")
                    dismiss();

            }
        }

        target: PolkitService
    }

    RowLayout {
        anchors.fill: parent
        layoutDirection: rightMode ? Qt.RightToLeft : Qt.LeftToRight
        spacing: Padding.large

        // Main Content Container with Panels
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            layoutDirection: !root.rightMode ? Qt.LeftToRight : Qt.RightToLeft

            SidebarNavigationRail {
                selectedCategory: root.selectedCategory
            }
            // Panel Repeater - Main and Aux

            Repeater {
                id: panelRepeater

                model: 2
                visible: root.showContent && GlobalStates.sidebarOpen
                clip: true

                ContentChild {
                    required property int index

                    showContent: root.showContent
                    Layout.fillHeight: true
                    Layout.fillWidth: index === 0
                    Layout.preferredWidth: {
                        // if (index === 0) {
                        //     const baseWidth = SidebarData.sizePresets.contentThreeQuarter || 600;
                        //     const expandWidth = root.expanded ? SidebarData.sizePresets.contentQuarter : 0;
                        //     return baseWidth + expandWidth;
                        // }
                        return SidebarData.sizePresets.contentQuarter;
                    }
                    Layout.margins: visible ? Padding.normal : 0
                    Layout.maximumWidth: isAux ? SidebarData.sizePresets.contentQuarter : Number.POSITIVE_INFINITY
                    visible: index === 0 ? true : auxVisible
                    category: index === 0 ? selectedCategory : auxCategory
                    searchText: index === 0 ? root.searchText : auxSearchText
                    dataModel: index === 0 ? mainModel : auxModel
                    componentMap: root.componentMap
                    parentRoot: root
                    isAux: index === 1
                    onSearchUpdated: (newText) => {
                        if (index === 0) {
                            root.searchText = newText;
                            delayedRefresh.restart();
                        } else {
                            root.auxSearchText = newText;
                            auxDelayedRefresh.restart();
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {
                        }

                    }

                }

                Behavior on opacity {
                    Anim {
                    }

                }

            }

        }

    }

    // Component definitions
    Component {
        id: notificationscomponent

        Notifs {
        }

    }

    Component {
        id: polkitComponent

        Polkit {
        }

    }

    Component {
        id: beatscomponent

        Beats {
        }

    }

    Component {
        id: kanbancomponent

        KanbanWidget {
            quarters: root.expanded
        }

    }

    Component {
        id: sessioncomponent

        PowerMenu {
            buttonSize: 140
            verticalMode: true
        }

    }

    Component {
        id: tweakscomponent

        QuickSettings {
            expanded: root.expanded
            sidebarMode: true
            searchText: root.searchText
        }

    }

    Component {
        id: overviewcomponent

        OverviewWidget {
            panelWindow: root.panelWindow
            rowsNumber: 5
            scale: 0.225
            windowOffset: 0.043
            expanded: root.expanded
        }

    }

    Component {
        id: gamescomponent

        GameLauncher {
            searchQuery: root.searchText
            sidebarMode: true
        }

    }

    Component {
        id: wallpaperselectorcomponent

        WallpaperSelector {
            expanded: root.expanded
            searchQuery: root.searchText
        }

    }

    Component {
        id: notesComponent

        Notes {
        }

    }

    Component {
        id: listviewcomponent

        AppListView {
        }

    }

    Component {
        id: apicomponent

        ApisContent {
            onExpandRequested: root.expanded = !root.expanded
        }

    }

    Component {
        id: misccomponent

        MiscWidget {
        }

    }

    Component {
        id: gridviewcomponent

        AppGridView {
        }

    }

    Component {
        id: gallerycomponent

        GalleryWidget {
        }

    }

}
