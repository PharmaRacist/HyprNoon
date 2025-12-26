pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import QtQuick

/**
 * Timer service with persistent state management
 * Storage: Uses Mem.states.services.timer.timers and Mem.states.services.timer.nextTimerId
 */
Singleton {
    id: root
    readonly property var uiTimers: timers
    property var timers: []
    property int nextTimerId: 1
    property bool needsSave: false
    property bool isLoaded: false

    signal timerFinished(int timerId, string name)
    signal timersLoaded

    Component.onCompleted: {
        if (Mem.ready) {
            Qt.callLater(loadFromConfig);
        }
    }

    // Debounced save timer - saves at most once per 10 seconds
    Timer {
        id: autoSaveTimer
        interval: 10000
        repeat: false
        onTriggered: {
            if (needsSave) {
                saveToConfig();
                needsSave = false;
            }
        }
    }

    readonly property list<var> presets: [
        {
            "duration": 1500,
            "icon": "timer",
            "name": "Pomodoro"
        },
        {
            "duration": 300,
            "icon": "coffee",
            "name": "Short Break"
        },
        {
            "duration": 900,
            "icon": "bed",
            "name": "Long Break"
        },
        {
            "duration": 5400,
            "icon": "mindfulness",
            "name": "Deep Work"
        },
        {
            "duration": 1800,
            "icon": "fitness_center",
            "name": "Exercise"
        },
        {
            "duration": 600,
            "icon": "self_improvement",
            "name": "Meditation"
        },
        {
            "duration": 900,
            "icon": "flash_on",
            "name": "Quick Task"
        },
        {
            "duration": 3600,
            "icon": "groups",
            "name": "Meeting"
        }
    ]

    // Storage Operations
    function saveToConfig() {
        if (!Mem.statesReady) {
            return;
        }

        const saveData = timers.map(timer => {
            let actualRemainingTime = timer.remainingTime;

            // If timer is running, calculate actual remaining time
            if (timer.isRunning && timer.startTime > 0) {
                const elapsed = Math.floor((Date.now() - timer.startTime) / 1000);
                actualRemainingTime = Math.max(0, timer.originalDuration - elapsed);
            }

            return {
                id: timer.id,
                name: timer.name,
                originalDuration: timer.originalDuration,
                remainingTime: actualRemainingTime,
                isRunning: timer.isRunning,
                isPaused: actualRemainingTime < timer.originalDuration && actualRemainingTime > 0,
                preset: timer.preset,
                icon: timer.icon
            };
        });

        Mem.states.services.timer.timers = saveData;
        Mem.states.services.timer.nextTimerId = nextTimerId;
    }

    function scheduleSave() {
        needsSave = true;
        if (!autoSaveTimer.running) {
            autoSaveTimer.start();
        }
    }

    function loadFromConfig() {
        if (!Mem.statesReady) {
            return;
        }

        let savedTimers = Mem.states.services.timer.timers;
        const savedNextId = Mem.states.services.timer.nextTimerId;

        // Convert QML list to JS array if needed
        if (savedTimers && !Array.isArray(savedTimers)) {
            const tempArray = [];
            for (let i = 0; i < savedTimers.length; i++) {
                tempArray.push(savedTimers[i]);
            }
            savedTimers = tempArray;
        }

        if (savedNextId !== undefined && savedNextId !== null && savedNextId > 0) {
            nextTimerId = savedNextId;
        }

        if (savedTimers && savedTimers.length > 0) {
            // Clear existing timers
            timers = [];
            root.timers = [];

            // Build timers array directly
            for (let i = 0; i < savedTimers.length; i++) {
                const timerData = savedTimers[i];

                const loadedTimer = {
                    id: timerData.id,
                    name: timerData.name,
                    originalDuration: timerData.originalDuration,
                    remainingTime: timerData.remainingTime,
                    isRunning: timerData.isRunning || false,
                    isPaused: timerData.isPaused || false,
                    startTime: 0,
                    pausedTime: 0,
                    preset: timerData.preset,
                    icon: timerData.icon || "timer",
                    qtTimer: null,
                    lastSaveTime: 0
                };

                timers.push(loadedTimer);
            }

            // Force property update
            root.timers = timers.slice(0);
            root.timersChanged();
            root.isLoaded = true;
            root.timersLoaded();

            // Automatically restart timers that were running before restart
            Qt.callLater(() => {
                for (let i = 0; i < timers.length; i++) {
                    const t = timers[i];
                    if (t.isRunning && t.remainingTime > 0) {
                        startTimer(t.id);
                    }
                }
            });
        } else {
            timers = [];
            root.timers = [];
            root.isLoaded = true;
            root.timersLoaded();
        }
    }

    // Sounds via external commands (if supported)
    function playSound(name) {
        let sound = "";
        if (name === "start")
            sound = "alarm_endded";
        if (name === "finish")
            sound = "alarm_started";
        if (sound !== "") {
            Noon.playSound(sound);
        }
    }

    function showNotification(title, message) {
        Noon.notify(`'${title} , ${message}'`);
    }

    function parseTimeString(input) {
        if (!input || typeof input !== "string")
            return 0;

        input = input.trim().toLowerCase();

        // Match things like "1h30m", "45m", "10s", "2h10m5s"
        const regex = /(\d+)([hms])/g;
        let totalSeconds = 0;
        let match;

        while ((match = regex.exec(input)) !== null) {
            const value = parseInt(match[1]);
            const unit = match[2];

            if (unit === "h")
                totalSeconds += value * 3600;
            else if (unit === "m")
                totalSeconds += value * 60;
            else if (unit === "s")
                totalSeconds += value;
        }

        // If no unit is specified and input is numeric → assume minutes
        if (totalSeconds === 0 && /^\d+$/.test(input))
            totalSeconds = parseInt(input) * 60;

        return totalSeconds;
    }

    function addTimer(name, duration, preset) {
        const timer = {
            id: nextTimerId++,
            name: name,
            originalDuration: duration,
            remainingTime: duration,
            isRunning: false,
            isPaused: false,
            startTime: 0,
            pausedTime: 0,
            preset: preset || null,
            icon: preset ? preset.icon : "timer",
            qtTimer: null
        };

        timers.push(timer);
        root.timers = timers.slice(0);
        saveToConfig();
        return timer.id;
    }

    function removeTimer(timerId) {
        const index = timers.findIndex(t => t.id === timerId);
        if (index !== -1) {
            const timer = timers[index];
            if (timer.qtTimer)
                timer.qtTimer.destroy();
            timers.splice(index, 1);
            root.timers = timers.slice(0);
            saveToConfig();
        }
    }

    function startTimer(timerId) {
        const timer = timers.find(t => t.id === timerId);
        if (!timer || timer.remainingTime <= 0)
            return;

        if (!timer.qtTimer) {
            timer.qtTimer = timerComponent.createObject(root, {
                "timerId": timerId,
                "interval": 1000,
                "repeat": true
            });
        }

        timer.isRunning = true;
        timer.isPaused = false;
        timer.startTime = Date.now() - (timer.originalDuration - timer.remainingTime) * 1000;
        timer.qtTimer.start();
        root.playSound("start");
        root.timers = timers.slice(0);
        scheduleSave();
    }

    function pauseTimer(timerId) {
        const timer = timers.find(t => t.id === timerId);
        if (!timer || !timer.qtTimer)
            return;

        // Update remaining time before pausing
        if (timer.isRunning && timer.startTime > 0) {
            const elapsed = Math.floor((Date.now() - timer.startTime) / 1000);
            timer.remainingTime = Math.max(0, timer.originalDuration - elapsed);
        }

        timer.isRunning = false;
        timer.isPaused = true;
        timer.qtTimer.stop();
        root.timers = timers.slice(0);
        saveToConfig();
    }

    function resetTimer(timerId) {
        const timer = timers.find(t => t.id === timerId);
        if (!timer)
            return;

        if (timer.qtTimer)
            timer.qtTimer.stop();

        timer.isRunning = false;
        timer.isPaused = false;
        timer.remainingTime = timer.originalDuration;
        timer.startTime = 0;
        timer.pausedTime = 0;
        root.timers = timers.slice(0);
        saveToConfig();
    }

    function updateTimer(timerId, newDuration) {
        const timer = timers.find(t => t.id === timerId);
        if (!timer)
            return;

        const wasRunning = timer.isRunning;
        if (wasRunning)
            pauseTimer(timerId);

        timer.originalDuration = newDuration;
        timer.remainingTime = newDuration;
        root.timers = timers.slice(0);
        saveToConfig();

        if (wasRunning)
            startTimer(timerId);
    }

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;

        if (hours > 0) {
            return hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + (secs < 10 ? "0" : "") + secs;
        } else {
            return minutes + ":" + (secs < 10 ? "0" : "") + secs;
        }
    }

    function getProgressPercentage(timerId) {
        const timer = timers.find(t => t.id === timerId);
        if (!timer)
            return 0;

        let actualRemainingTime = timer.remainingTime;

        // If timer is running, calculate actual remaining time for accurate progress
        if (timer.isRunning && timer.startTime > 0) {
            const elapsed = Math.floor((Date.now() - timer.startTime) / 1000);
            actualRemainingTime = Math.max(0, timer.originalDuration - elapsed);
        }

        return ((timer.originalDuration - actualRemainingTime) / timer.originalDuration) * 100;
    }

    function handleTimerTick(timerId) {
        const timer = timers.find(t => t.id === timerId);
        if (!timer || !timer.isRunning)
            return;

        const elapsed = Math.floor((Date.now() - timer.startTime) / 1000);
        timer.remainingTime = Math.max(0, timer.originalDuration - elapsed);

        if (timer.remainingTime <= 0) {
            timer.isRunning = false;
            timer.isPaused = false;
            if (timer.qtTimer)
                timer.qtTimer.stop();

            root.playSound("finish");
            showNotification("⏰ Timer Complete", `${timer.name} finished!`);
            timerFinished(timer.id, timer.name);
            saveToConfig();
        } else {
            scheduleSave();
        }

        root.timers = timers.slice(0);
    }

    function refresh() {
        loadFromConfig();
    }

    Component {
        id: timerComponent
        Timer {
            property int timerId: -1
            onTriggered: root.handleTimerTick(timerId)
        }
    }
}
