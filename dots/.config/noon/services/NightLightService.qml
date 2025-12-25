pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

Singleton {
    id: nightLightService

    property bool enabled: false
    property int temperature: 5000
    readonly property int debounceDelay: 400

    // Auto cycle properties
    property bool autoEnabled: Mem.options.services.time.autoNightLightCycle ?? false
    property bool nextIsEnable: false

    Timer {
        id: debounceTimer
        interval: nightLightService.debounceDelay
        repeat: false
        onTriggered: {
            if (nightLightService.enabled)
                nightLightService.applyTemperature();
        }
    }

    Timer {
        id: nextTransitionTimer
        interval: 1000  // Default; will be set dynamically
        repeat: false
        onTriggered: {
            if (nextIsEnable)
                enable();
            else
                disable();
            updateSchedule();
        }
    }

    Process {
        id: processChecker
        running: true
        command: ["pidof", "hyprsunset"]
        onExited: exitCode => {
            nightLightService.enabled = (exitCode === 0);
        }
    }

    onAutoEnabledChanged: {
        if (autoEnabled) {
            updateSchedule();
        } else {
            nextTransitionTimer.stop();
        }
    }

    Connections {
        target: WeatherService
        function onSunriseChanged() {
            if (nightLightService.autoEnabled)
                nightLightService.updateSchedule();
        }
        function onSunsetChanged() {
            if (nightLightService.autoEnabled)
                nightLightService.updateSchedule();
        }
        function onWeatherPredictionsChanged() {
            if (nightLightService.autoEnabled)
                nightLightService.updateSchedule();
        }
    }

    function parseTimeToHours(timeStr) {
        var parts = timeStr.split(":");
        return parseInt(parts[0]) + parseInt(parts[1]) / 60.0;
    }

    function updateSchedule() {
        if (!autoEnabled) {
            return;
        }

        var now = new Date();
        var currentHour = now.getHours() + now.getMinutes() / 60.0 + now.getSeconds() / 3600.0;
        var todayRise = parseTimeToHours(WeatherService.sunrise);
        var todaySet = parseTimeToHours(WeatherService.sunset);

        var isNightNow = currentHour < todayRise || currentHour > todaySet;
        if (isNightNow !== enabled) {
            if (isNightNow) {
                enable();
            } else {
                disable();
            }
        }

        var nextTime;
        var isEnableTransition = false;
        var today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);

        if (isNightNow) {
            // Next: sunrise (disable)
            isEnableTransition = false;
            var nextRise;
            if (currentHour < todayRise) {
                nextRise = todayRise;
                nextTime = new Date(today.getTime() + nextRise * 3600000);
            } else {
                // Tomorrow's sunrise
                var tomorrowRiseStr = WeatherService.weatherPredictions.length > 0 ? WeatherService.weatherPredictions[0].sunrise : WeatherService.sunrise;
                var tomorrowRise = parseTimeToHours(tomorrowRiseStr);
                var tomorrow = new Date(today.getTime() + 86400000);
                nextTime = new Date(tomorrow.getTime() + tomorrowRise * 3600000);
            }
        } else {
            // Next: sunset (enable)
            isEnableTransition = true;
            nextTime = new Date(today.getTime() + todaySet * 3600000);
        }

        var delay = nextTime.getTime() - now.getTime();
        if (delay > 0) {
            nextIsEnable = isEnableTransition;
            nextTransitionTimer.stop();
            nextTransitionTimer.interval = delay;
            nextTransitionTimer.start();
        } else {
            // Recalculate if delay <= 0 (should be rare)
            updateSchedule();
        }
    }

    function enable() {
        if (enabled)
            return;
        Noon.execDetached(`hyprsunset -t ${temperature}`);
        enabled = true;
    }

    function disable() {
        if (!enabled)
            return;
        Noon.execDetached("pkill -9 hyprsunset");
        enabled = false;
    }

    function toggle() {
        if (enabled)
            disable();
        else
            enable();
    }

    function setTemperature(value) {
        if (value === temperature)
            return;
        temperature = value;
        debounceTimer.restart();
    }

    function applyTemperature() {
        if (!enabled)
            return;
        Noon.execDetached(`pkill -9 hyprsunset; hyprsunset -t ${temperature}`);
    }
}
