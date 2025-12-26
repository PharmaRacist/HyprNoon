import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
pragma Singleton

Singleton {
    // Replace the startRecording() function with this corrected version:

    id: root

    // Enums for recording options
    enum RecordingMode {
        FullScreen,
        Region,
        ActiveWindow
    }

    enum AudioMode {
        Muted,
        SystemAudio,
        MicrophoneAudio,
        BothAudio
    }

    enum Quality {
        Low, // 720p, 30fps
        Medium, // 1080p, 30fps
        High, // 1080p, 60fps
        Ultra // 4K, 60fps
    }

    // Public properties
    property bool isRecording: false
    property string lastError: ""
    property int recordingDuration: 0
    // Recording settings (persistent via Config)
    property int recordingMode: Mem.options.services.recording.recordingMode ?? RecordingService.RecordingMode.FullScreen
    property int audioMode: Mem.options.services.recording.audioMode ?? RecordingService.AudioMode.SystemAudio
    property int quality: Mem.options.services.recording.quality ?? RecordingService.Quality.Medium
    property bool showCursor: Mem.options.services.recording.showCursor ?? true
    property int customFramerate: Mem.options.services.recording.customFramerate ?? 0
    // Internal
    property Process recordingProcess: null
    property Timer stateCheckTimer

    stateCheckTimer: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: checkRecordingState()
    }

    property Timer durationTimer

    durationTimer: Timer {
        interval: 1000
        running: root.isRecording
        repeat: true
        onTriggered: root.recordingDuration++
    }

    // Signals
    signal recordingStarted()
    signal recordingStopped()
    signal recordingError(string error)

    // Check if wf-recorder is running
    function checkRecordingState() {
        // Poll the process list (this is a simplified check)
        // In a real implementation, you'd want a more robust check

        const wasRecording = root.isRecording;
        // Simple check using pidof
        const result = Noon.exec("pidof wf-recorder");
        if (wasRecording && !root.isRecording) {
            root.recordingDuration = 0;
            root.recordingStopped();
        } else if (!wasRecording && root.isRecording) {
            root.recordingStarted();
        }
    }

    // Update getQualityParams() to return CRF values:
    function getQualityParams() {
        switch (root.quality) {
        case RecordingService.Quality.Low:
            return {
                "fps": 30,
                "crf": 28
            }; // Lower quality, smaller file
        case RecordingService.Quality.Medium:
            return {
                "fps": 30,
                "crf": 23
            }; // Balanced (default)
        case RecordingService.Quality.High:
            return {
                "fps": 60,
                "crf": 20
            }; // Higher quality
        case RecordingService.Quality.Ultra:
            return {
                "fps": 60,
                "crf": 18
            }; // Best quality, larger file
        default:
            return {
                "fps": 30,
                "crf": 23
            };
        }
    }

    // Build output filename
    function getOutputPath() {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').split('.')[0];
        return `${FileUtils.trimFileProtocol(Directories.videos)}/recordings/recording-${timestamp}.mp4`;
    }

    function startRecording() {
        if (root.isRecording) {
            console.warn("RecordingService: Already recording");
            return false;
        }
        try {
            const qualityParams = getQualityParams();
            const fps = root.customFramerate > 0 ? root.customFramerate : qualityParams.fps;
            const outputPath = getOutputPath();
            let cmd = [];
            // Use software encoding - works everywhere
            const codec = "libx264";
            // Handle region selection first
            if (root.recordingMode === RecordingService.RecordingMode.Region) {
                // Use slurp to get region, then pipe to wf-recorder
                const audioFlags = getAudioFlags();
                const cursorFlag = !root.showCursor ? " --no-damage" : "";
                cmd = ["sh", "-c", `slurp | xargs -I {} wf-recorder -g "{}" -f ${outputPath} -r ${fps} -c ${codec} -p preset=fast -p crf=${qualityParams.crf}${cursorFlag}${audioFlags}`];
            } else {
                cmd = ["wf-recorder", "-f", outputPath, "-r", fps.toString(), "-c", codec];
                // Add codec parameters separately
                cmd.push("-p", "preset=fast");
                cmd.push("-p", `crf=${qualityParams.crf}`);
                // Add cursor option
                if (!root.showCursor)
                    cmd.push("--no-damage");

                // Add audio options
                if (root.audioMode !== RecordingService.AudioMode.Muted) {
                    cmd.push("--audio");
                    if (root.audioMode === RecordingService.AudioMode.MicrophoneAudio || root.audioMode === RecordingService.AudioMode.BothAudio)
                        cmd.push("--audio-device=default");

                }
                // Add geometry for active window
                if (root.recordingMode === RecordingService.RecordingMode.ActiveWindow) {
                    // Get active window geometry - simplified approach
                    const audioFlags = getAudioFlags();
                    const cursorFlag = !root.showCursor ? " --no-damage" : "";
                    cmd = ["sh", "-c", `GEOM=$(hyprctl -j activewindow | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"') && wf-recorder -g "$GEOM" -f ${outputPath} -r ${fps} -c ${codec} -p preset=fast -p crf=${qualityParams.crf}${cursorFlag}${audioFlags}`];
                }
            }
            console.log("RecordingService: Starting recording:", cmd.join(" "));
            // Execute via hyprland dispatch
            const fullCmd = cmd.join(" ");
            Noon.exec(` ${fullCmd}`);
            // Set recording state after a short delay to allow process to start
            Qt.callLater(() => {
                root.isRecording = true;
                root.recordingDuration = 0;
                root.lastError = "";
            });
            return true;
        } catch (e) {
            root.lastError = e.toString();
            root.recordingError(root.lastError);
            console.error("RecordingService: Failed to start recording:", e);
            return false;
        }
    }

    // Get audio flags as string
    function getAudioFlags() {
        if (root.audioMode === RecordingService.AudioMode.Muted)
            return "";

        let flags = " --audio";
        if (root.audioMode === RecordingService.AudioMode.MicrophoneAudio || root.audioMode === RecordingService.AudioMode.BothAudio)
            flags += " --audio-device=default";

        return flags;
    }

    // Stop recording
    function stopRecording() {
        if (!root.isRecording) {
            console.warn("RecordingService: Not currently recording");
            return false;
        }
        try {
            // Send SIGINT to wf-recorder to stop gracefully
            Noon.exec("pkill -SIGINT wf-recorder");
            root.isRecording = false;
            root.recordingDuration = 0;
            root.lastError = "";
            console.log("RecordingService: Stopped recording");
            return true;
        } catch (e) {
            root.lastError = e.toString();
            root.recordingError(root.lastError);
            console.error("RecordingService: Failed to stop recording:", e);
            return false;
        }
    }

    // Toggle recording
    function toggleRecording() {
        return root.isRecording ? stopRecording() : startRecording();
    }

    // Format duration as MM:SS
    function getFormattedDuration() {
        const minutes = Math.floor(root.recordingDuration / 60);
        const seconds = root.recordingDuration % 60;
        return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }

    // Settings methods
    function setRecordingMode(mode) {
        if (!root.isRecording) {
            root.recordingMode = mode;
            return true;
        }
        return false;
    }

    function setAudioMode(mode) {
        if (!root.isRecording) {
            root.audioMode = mode;
            return true;
        }
        return false;
    }

    function setQuality(qualityLevel) {
        if (!root.isRecording) {
            root.quality = qualityLevel;
            return true;
        }
        return false;
    }

    function resetSettings() {
        if (root.isRecording)
            return false;

        root.recordingMode = RecordingService.RecordingMode.FullScreen;
        root.audioMode = RecordingService.AudioMode.SystemAudio;
        root.quality = RecordingService.Quality.Medium;
        root.showCursor = true;
        root.customFramerate = 0;
        return true;
    }

    // Get human-readable text
    function getRecordingModeText() {
        switch (root.recordingMode) {
        case RecordingService.RecordingMode.FullScreen:
            return "Full Screen";
        case RecordingService.RecordingMode.Region:
            return "Region";
        case RecordingService.RecordingMode.ActiveWindow:
            return "Active Window";
        default:
            return "Unknown";
        }
    }

    function getAudioModeText() {
        switch (root.audioMode) {
        case RecordingService.AudioMode.Muted:
            return "Muted";
        case RecordingService.AudioMode.SystemAudio:
            return "System Audio";
        case RecordingService.AudioMode.MicrophoneAudio:
            return "Microphone";
        case RecordingService.AudioMode.BothAudio:
            return "System + Mic";
        default:
            return "Unknown";
        }
    }

    function getQualityText() {
        switch (root.quality) {
        case RecordingService.Quality.Low:
            return "Low (720p 30fps)";
        case RecordingService.Quality.Medium:
            return "Medium (1080p 30fps)";
        case RecordingService.Quality.High:
            return "High (1080p 60fps)";
        case RecordingService.Quality.Ultra:
            return "Ultra (4K 60fps)";
        default:
            return "Unknown";
        }
    }

    // Save settings to config when changed
    onRecordingModeChanged: Mem.options.services.recording.recordingMode = recordingMode
    onAudioModeChanged: Mem.options.services.recording.audioMode = audioMode
    onQualityChanged: Mem.options.services.recording.quality = quality
    onShowCursorChanged: Mem.options.services.recording.showCursor = showCursor
    onCustomFramerateChanged: Mem.options.services.recording.customFramerate = customFramerate
    // Initialize config structure
    Component.onCompleted: {
        if (!Mem.options.services)
            Mem.options.services = {
            };

        if (!Mem.options.services.recording)
            Mem.options.services.recording = {
                "recordingMode": RecordingService.RecordingMode.FullScreen,
                "audioMode": RecordingService.AudioMode.SystemAudio,
                "quality": RecordingService.Quality.Medium,
                "showCursor": true,
                "customFramerate": 0
            };

    }
}
