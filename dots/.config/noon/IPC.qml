import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.view
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.store

Scope {
    IpcHandler {
        target: "global"
        function expose(show: bool) {
            if (show) {
                GlobalStates.exposeView = true;
            } else if (!show) {
                GlobalStates.exposeView = false;
            }
        }

        function inc_brightness() {
            onPressed: BrightnessService.increaseBrightness();
        }

        function dec_brightness() {
            onPressed: BrightnessService.decreaseBrightness();
        }
        function clear_clipboard(): void {
            ClipboardService.wipe();
        }
        function update_clipboard(): void {
            ClipboardService.reload();
        }
        function refresh_appearance() {
            WallpaperService.refreshTheme();
        }
        function toggleLightMode() {
            WallpaperService.toggleShellMode();
        }
        function pick_accent() {
            WallpaperService.pickAccentColor();
            Noon.notify("Color Changed");
        }
        function pick_random_wall() {
            WallpaperService.applyRandomWallpaper();
            Noon.notify("Picked Random Wall");
        }
        function set_wall(path: string) {
            WallpaperService.applyWallpaper(path);
            Noon.notify("Wallpaper Changed");
        }
        function toggle_bar_mode() {
            Mem.options.bar.behavior.position = BarData.getNextMode();
        }
        function swap_bar_position() {
            BarData.swapPosition();
        }
        function toggle_dock_pin() {
            Mem.states.dock.pinned = !Mem.states.dock.pinned;
        }
        function toggle_osk() {
            GlobalStates.oskOpen = !GlobalStates.oskOpen;
        }
        function todoist_key(key: string) {
            const trimmed = key.trim();
            KeyringStorage.setNestedField(["todoistApiKey"], trimmed);
            TodoService.todoistApiToken = trimmed;
            console.log("API token set (trimmed):", TodoService.todoistApiToken);
        }
        function toggle_beats() {
            GlobalStates.playlistOpen = !GlobalStates.playlistOpen;
        }
        function add_alarm(time: string, name: string) {
            AlarmService.addTimer(time, name);
        }
        function wake(message: string) {
            Noon.wake(message, "alarm");
        }
        function close_beats() {
            GlobalStates.playlistOpen = false;
        }
        function open_beats() {
            GlobalStates.playlistOpen = true;
        }
        function lock() {
            GlobalStates.locked = true;
            IdleService.idleMonitor.reset();
        }
        function pause_all_players(): void {
            for (const player of Mpris.players.values) {
                if (player.canPause)
                    player.pause();
            }
        }

        function toggle_playing(): void {
            MprisController.togglePlaying();
        }
        function previous_track(): void {
            MprisController.previous();
        }
        function next_track(): void {
            MprisController.next();
        }
        function medical_key(key: string) {
            MedicalDictionaryService.setApiKey(key);
        }
        function toggle_ai_bar() {
            GlobalStates.showBeam = !GlobalStates.showBeam;
        }
    }
}
