import QtQuick
import Quickshell
import qs.common
import qs.common.utils
pragma Singleton

Singleton {
    id: root

    property bool enabled: Mem.states.services.nightLight.enabled
    property int temperature: Mem.states.services.nightLight.temperature ?? 6400
    property bool autoEnabled: Mem.options.services.nightLight.autoNightLightCycle ?? false

    function reload() {
        if (enabled) {
            mainProc.running = false;
            mainProc.running = true;
        } else {
            mainProc.running = false;
            Noon.execDetached("killall hyprsunset");
        }
    }

    function debounced_reload() {
        debounceTimer.restart();
    }

    function syncWithSunset() {
        if (!autoEnabled)
            return ;

        const now = new Date();
        const currentHour = now.getHours() + now.getMinutes() / 60;
        const [sunriseH, sunriseM] = WeatherService.sunrise.split(":").map(Number);
        const [sunsetH, sunsetM] = WeatherService.sunset.split(":").map(Number);
        const sunrise = sunriseH + sunriseM / 60;
        const sunset = sunsetH + sunsetM / 60;
        const isNight = currentHour < sunrise || currentHour > sunset;
        isNight ? enable() : disable();
    }

    onEnabledChanged: () => {
        return reload();
    }
    onTemperatureChanged: () => {
        return debounced_reload();
    }
    onAutoEnabledChanged: {
        if (autoEnabled)
            syncWithSunset();

    }

    Timer {
        id: debounceTimer

        interval: 200
        onTriggered: reload()
    }

    Process {
        id: mainProc

        command: ["bash", "-c", `hyprsunset -t ${temperature}`]
    }

    Process {
        running: true
        command: ["pidof", "hyprsunset"]
        onExited: (exitCode) => {
            return Mem.states.services.nightLight.enabled = (exitCode === 0);
        }
    }

    Connections {
        function onSunriseChanged() {
            if (root.autoEnabled)
                root.syncWithSunset();

        }

        function onSunsetChanged() {
            if (root.autoEnabled)
                root.syncWithSunset();

        }

        target: WeatherService
    }

}
