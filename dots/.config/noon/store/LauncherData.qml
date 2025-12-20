pragma Singleton
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services
import qs.store

Singleton {
    id: root
    property int sidebarWidth
    
    readonly property var sizePresets: ({
        bar: Sizes.collapsedSideBarWidth ?? 50,
        contentQuarter: Math.round(Screen.width * 0.235) - Sizes.collapsedSideBarWidth,
        half: Math.round(Screen.width * 0.457),
        full: Screen.width,
        quarter: Math.round(Screen.width * 0.246),
        threeQuarter: Math.round(Screen.width * 0.85),
        session: 280,
        overview: 1250
    })

    property var _categoryMap: ({})
    property var _enabledCategories: []
    property var _appCache: null
    property bool _appCacheValid: false
    
    readonly property var categories: [
        { id: "Apps", name: "Apps", icon: "apps", placeholder: qsTr("Search applications..."), 
          component: Mem.options.sidebarLauncher.appearance.useAppListView ? "AppListView" : "AppGridView", 
          searchable: true, hasModel: true, customSize: sizePresets.quarter, enabled: true },
        { id: "API", name: "APIs", icon: "neurology", component: "API", expandable: true, overlay: true, 
          customSize: sizePresets.half, enabled: true },
        { id: "Notifs", name: "Notifs", icon: "notifications_active", component: "StyledNotifications", 
          customSize: sizePresets.quarter, enabled: Mem.options.sidebarLauncher.content.notifs },
        { id: "Walls", name: "Walls", icon: "image", placeholder: qsTr("Search Wallpapers..."), 
          component: "WallpaperSelector", expandable: true, searchable: true, customSize: sizePresets.threeQuarter, 
          enabled: Mem.options.sidebarLauncher.content.wallpapers },
        { id: "Gallery", name: "Gallery", icon: "photo_library", placeholder: qsTr("Search gallery..."), 
          component: "GalleryWidget", expandable: true, customSize: sizePresets.threeQuarter, searchable: true, 
          hasModel: true, folderPath: Qt.resolvedUrl(Directories.gallery), 
          nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"], enabled: Mem.options.sidebarLauncher.content.gallery ?? true },
        { id: "Tasks", name: "Tasks", icon: "task_alt", component: "KanbanWidget", expandable: true, 
          preExpand: false, customSize: sizePresets.half, enabled: Mem.options.sidebarLauncher.content.tasks },
        { id: "Notes", name: "Notes", icon: "stylus", component: "Notes", expandable: true, 
          customSize: sizePresets.half, enabled: Mem.options.sidebarLauncher.content.notes },
        { id: "View", name: "View", icon: "ad", component: "OverviewWidget", expandable: true, preExpand: true, 
          customSize: sizePresets.overview, enabled: Mem.options.sidebarLauncher.content.overview },
        { id: "Beats", name: "Beats", icon: "music_note", component: "Beats", expandable: true, 
          customSize: sizePresets.half, preExpand: false, enabled: Mem.options.sidebarLauncher.content.beats },
        { id: "Bars", name: "Bars", icon: "format_paint", placeholder: qsTr("Search bar layouts..."), 
          component: "AppListView", searchable: true, hasModel: true, useListView: true, 
          customSize: sizePresets.quarter, enabled: Mem.options.sidebarLauncher.content.barSwitcher },
        { id: "Emojis", name: "Emojis", icon: "emoji_emotions", placeholder: qsTr("Search emojis..."), 
          component: "AppGridView", searchable: true, hasModel: true, customSize: sizePresets.quarter, 
          enabled: Mem.options.sidebarLauncher.content.emojies },
        { id: "History", name: "History", icon: "content_paste", placeholder: qsTr("Search history..."), 
          component: "AppListView", searchable: true, hasModel: true, useListView: true, 
          customSize: sizePresets.quarter, enabled: Mem.options.sidebarLauncher.content.history },
        { id: "Games", name: "Games", icon: "stadia_controller", component: "Games", expandable: true, 
          preExpand: true, searchable: true, customSize: sizePresets.half, enabled: Mem.options.sidebarLauncher.content.games },
        { id: "Tweaks", name: "Tweaks", icon: "tune", component: "Tweaks", expandable: true, searchable: true, 
          customSize: sizePresets.threeQuarter, enabled: Mem.options.sidebarLauncher.content.tweaks },
        { id: "Docs", name: "Docs", icon: "description", placeholder: qsTr("Search docs..."), 
          component: "AppListView", searchable: true, hasModel: true, useListView: true, customSize: sizePresets.quarter, 
          folderPath: Qt.resolvedUrl(Directories.notes), nameFilters: ["*.pdf", "*.docx", "*.md", "*.txt", "*.rtf", "*.odt"], 
          enabled: Mem.options.sidebarLauncher.content.documents },
        { id: "Movies", name: "Movies", icon: "movie", placeholder: qsTr("Search movies..."), 
          component: "AppListView", searchable: true, hasModel: true, useListView: true, customSize: sizePresets.quarter, 
          folderPath: Directories.videos, nameFilters: ["*.mp4", "*.mkv", "*.avi", "*.mov", "*.wmv", "*.flv"], 
          enabled: Mem.options.sidebarLauncher.content.movies },
        { id: "Bookmarks", name: "Bookmarks", icon: "bookmark", placeholder: qsTr("Search bookmarks..."), 
          component: "AppListView", searchable: true, hasModel: true, useListView: true, customSize: sizePresets.quarter, 
          enabled: Mem.options.sidebarLauncher.content.bookmarks ?? true },
        { id: "Misc", name: "Misc", icon: "more_horiz", component: "MiscComponent", overlay: true, 
          customSize: sizePresets.quarter, enabled: Mem.options.sidebarLauncher.content.misc },
        { id: "Auth", name: "Auth", icon: "lock", component: "Auth", overlay: true, 
          customSize: sizePresets.quarter, enabled: false },
        { id: "Session", name: "Session", icon: "power_settings_new", component: "PowerMenu", overlay: true, 
          customSize: sizePresets.session, enabled: Mem.options.sidebarLauncher.content.session },
    ]

    Component.onCompleted: {
        const map = {}, enabled = [];
        for (let i = 0; i < categories.length; i++) {
            const cat = categories[i];
            map[cat.id] = cat;
            if (cat.enabled) enabled.push(cat.id);
        }
        _categoryMap = map;
        _enabledCategories = enabled;
    }

    // Invalidate app cache when desktop entries change
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { _appCacheValid = false; }
    }

    readonly property var categoryMap: _categoryMap
    readonly property var enabledCategories: _enabledCategories
    readonly property var registry: _categoryMap

    function getCategory(catId) { return _categoryMap[catId] || _categoryMap["Apps"]; }
    function getIcon(catId) { const cat = _categoryMap[catId]; return cat ? cat.icon : "apps"; }
    function getPlaceholder(catId) { const cat = _categoryMap[catId]; return cat ? (cat.placeholder || qsTr("Search...")) : qsTr("Search..."); }
    function getComponent(catId) { const cat = _categoryMap[catId]; return cat ? (cat.component || "AppGridView") : "AppGridView"; }
    function isSearchable(catId) { const cat = _categoryMap[catId]; return cat ? (cat.searchable ?? false) : false; }
    function hasModel(catId) { const cat = _categoryMap[catId]; return cat ? (cat.hasModel ?? false) : false; }
    function isExpandable(catId) { const cat = _categoryMap[catId]; return cat ? (cat.expandable ?? false) : false; }
    function usePreExpand(catId) { const cat = _categoryMap[catId]; return cat ? (cat.preExpand ?? false) : false; }
    function isOverlay(catId) { const cat = _categoryMap[catId]; return cat ? (cat.overlay ?? false) : false; }

    function currentSize(barMode, expanded, selectedCategory) {
        if (barMode) return sizePresets.bar + Padding.large;
        const cat = _categoryMap[selectedCategory];
        if (expanded && cat?.expandable) return cat.customSize;
        return selectedCategory === "Session" ? sizePresets.session : sizePresets.quarter;
    }

    function getNextEnabledCategory(currentId) {
        const idx = _enabledCategories.indexOf(currentId);
        return idx === -1 ? (_enabledCategories[0] || "") : (_enabledCategories[(idx + 1) % _enabledCategories.length] || "");
    }

    function getPreviousEnabledCategory(currentId) {
        const idx = _enabledCategories.indexOf(currentId);
        return idx === -1 ? (_enabledCategories[0] || "") : (_enabledCategories[(idx - 1 + _enabledCategories.length) % _enabledCategories.length] || "");
    }

    function generateData(catId, searchText, params) {
        if (!catId) return [];
        switch (catId) {
        case "Apps": return generateApps(searchText);
        case "Bars": return generateBarLayouts(searchText, params);
        case "Emojis": return generateEmojis(searchText, params);
        case "History": return generateHistory(searchText);
        case "Bookmarks": return generateBookmarks(searchText);
        default: return [];
        }
    }

    function _buildAppCache() {
        const allEntries = DesktopEntries.applications.values;
        if (!allEntries?.length) return [];
        
        const sorted = Array.from(allEntries);
        sorted.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        
        return sorted.map(entry => ({
            id: entry.id,
            name: entry.name,
            command: Array.isArray(entry.command) ? entry.command.join(' ') : String(entry.command || ""),
            execString: Array.isArray(entry.execString) ? entry.execString.join(' ') : String(entry.execString || ""),
            iconImage: entry.icon || entry.genericIcon || "applications-system",
            clickActionName: qsTr("Launch"),
            type: qsTr("App"),
            _entry: entry
        }));
    }

    function generateApps(query) {
        const q = query?.trim() || "";
        
        if (!_appCacheValid || !_appCache) {
            _appCache = _buildAppCache();
            _appCacheValid = true;
        }
        
        if (!_appCache.length) return [];
        if (!q) return _appCache;
        
        const fuzzyResults = Fuzzy.go(q, _appCache.map(a => a._entry), {
            keys: ['name', 'genericName', 'comment', 'keywords'],
            threshold: -10000,
            limit: 100
        });
        
        const idSet = new Set(fuzzyResults.map(r => r.obj.id));
        return _appCache.filter(app => idSet.has(app.id));
    }

    function generateBarLayouts(query, params) {
        if (!params) return [];
        const allLayouts = [];

        const addLayouts = (layouts, isVert) => {
            if (!layouts) return;
            const isActiveCheck = isVert ? params.isVerticalBar : !params.isVerticalBar;
            const currentLayout = isVert ? params.currentVerticalLayout : params.currentHorizontalLayout;
            
            for (let idx = 0; idx < layouts.length; idx++) {
                const name = layouts[idx].replace('Layout', '');
                const isActive = isActiveCheck && currentLayout === idx;
                const icon = isActive ? 'radio_button_checked' : 'radio_button_unchecked';
                allLayouts.push({
                    name: `${name} (${isVert ? 'Vertical' : 'Horizontal'})`,
                    displayName: name,
                    icon: icon,
                    materialSymbol: icon,
                    clickActionName: qsTr("Switch"),
                    type: isActive ? qsTr("Bar Layout (Active)") : qsTr("Bar Layout"),
                    categories: ["BarLayout"],
                    layoutIndex: idx,
                    isVertical: isVert,
                    id: ""
                });
            }
        };

        addLayouts(params.horizontalLayouts, false);
        addLayouts(params.verticalLayouts, true);

        if (!query?.trim()) return allLayouts;

        const fuzzyResults = Fuzzy.go(query, allLayouts, {
            key: 'displayName',
            threshold: -5000
        });

        return fuzzyResults.map(r => r.obj);
    }

    function generateEmojis(query, params) {
        if (!params) return [];
        
        const allEmojis = Emojis.list || [];
        if (!allEmojis.length) return [];
        
        const mapped = allEmojis.map(e => {
            const emoji = e.match(/^\s*(\S+)/)?.[1] || "";
            const name = e.replace(/^\s*\S+\s+/, "");
            return {
                cliphistRawString: e,
                bigText: emoji,
                name: name,
                searchName: name,
                icon: emoji,
                clickActionName: qsTr("Copy"),
                type: qsTr("Emoji"),
                categories: ["Emojis"],
                id: ""
            };
        });

        const q = query?.trim() || "";
        if (!q) {
            // Return frequent emojis when no search
            const frequentSet = new Set(params.frequentEmojis || []);
            const frequent = mapped.filter(e => frequentSet.has(e.bigText));
            return frequent.length ? frequent : mapped.slice(0, 24);
        }

        const fuzzyResults = Fuzzy.go(q, mapped, {
            key: 'searchName',
            threshold: -10000,
            limit: 100
        });

        return fuzzyResults.map(r => r.obj);
    }

    function generateHistory(query) {
        const allResults = Cliphist.entries || [];
        if (!allResults?.length) return [];
        
        const mapped = allResults.map(str => {
            const id = Number(str.split("\t")[0]);
            const isImage = Cliphist.entryIsImage(str);
            const content = StringUtils.cleanCliphistEntry(str);
            let displayName = content, imagePath = "";

            if (isImage) {
                imagePath = Cliphist.decodeImageEntry(str);
                displayName = content.split("]]")[1]?.trim() || "Image";
            }

            return {
                cliphistRawString: str,
                name: displayName,
                searchText: displayName,
                icon: isImage ? "image" : "",
                clickActionName: qsTr("Copy"),
                type: isImage ? qsTr("Image") : `#${id}`,
                categories: ["History"],
                id: id.toString(),
                isImage: isImage,
                imagePath: imagePath
            };
        });

        if (!query?.trim()) return mapped;

        const fuzzyResults = Fuzzy.go(query, mapped, {
            key: 'searchText',
            threshold: -10000,
            limit: 50
        });

        return fuzzyResults.map(r => r.obj);
    }

    function generateBookmarks(query) {
        const bookmarks = FirefoxBookmarksService.bookmarks;
        if (!bookmarks?.length) return [];

        const mapped = bookmarks.map(b => ({
            name: b.title || "Untitled",
            searchTitle: b.title || "",
            searchUrl: b.url || "",
            icon: b.favicon_local || b.favicon_url || "bookmark",
            materialSymbol: (b.favicon_local || b.favicon_url) ? "" : "bookmark",
            faviconLocal: !!(b.favicon_local || b.favicon_url),
            clickActionName: qsTr("Open"),
            type: qsTr("Bookmark"),
            categories: ["Bookmarks"],
            url: b.url,
            id: b.id?.toString() || "",
            faviconUrl: b.favicon_url || ""
        }));

        if (!query?.trim()) return mapped;

        const fuzzyResults = Fuzzy.go(query, mapped, {
            keys: ['searchTitle', 'searchUrl'],
            threshold: -10000,
            limit: 50
        });

        return fuzzyResults.map(r => r.obj);
    }

    function launch(catId, app, layoutSwitcher, isAux = false) {
        if (!app) return;
        
        const hideIfNotAux = () => { if (!isAux) Noon.callIpc("sidebar_launcher hide"); };
        
        switch (catId) {
        case "Apps":
            launchApp(app, isAux);
            break;
        case "Bars":
            if (layoutSwitcher) layoutSwitcher(app.layoutIndex, app.isVertical);
            hideIfNotAux();
            break;
        case "Emojis":
            Noon.exec(`wl-copy '${StringUtils.shellSingleQuoteEscape(app.bigText)}'`);
            Emojis.recordEmojiUse(app.cliphistRawString);
            hideIfNotAux();
            break;
        case "History":
            Cliphist.copy(app.cliphistRawString);
            hideIfNotAux();
            break;
        case "Bookmarks":
            FirefoxBookmarksService.openUrl(app.url);
            hideIfNotAux();
            break;
        case "Docs":
        case "Movies":
        case "Gallery":
        case "Gallary":
            if (app.path) Noon.exec(`xdg-open "${app.path}"`);
            hideIfNotAux();
            break;
        }
    }

    function altLaunch(app, isAux = false) {
        if (!app) return;
        const cat = _categoryMap[selectedCategory];
        if (cat?.altLaunch) {
            cat.altLaunch(app, switchToLayout);
            if (!isAux) Noon.callIpc("sidebar_launcher hide");
        }
    }

    function launchApp(app, isAux = false) {
        if (!app) return;
        const hideIfNotAux = () => { if (!isAux) Noon.callIpc("sidebar_launcher hide"); };
        
        if (app.execute) { app.execute(); hideIfNotAux(); return; }
        if (app.onClick) { app.onClick(); hideIfNotAux(); return; }
        
        const entry = DesktopEntries.byId(app.id);
        if (entry) {
            Noon.playSound("event_accepted");
            entry.execute();
            hideIfNotAux();
        }
    }
}