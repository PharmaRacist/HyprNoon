pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.store

Singleton {
    id: root

    // --- Optimized Default Options ---
    // isnet-general-use: Better accuracy across diverse images (IoU 0.82)
    // 44MB model vs u2net's 176MB - faster download/load
    property string model: "isnet-general-use"

    // Alpha matting: OFF by default for speed
    // Only enable for complex edges (hair, fur, fine details)
    property bool alphaMatting: false

    // Optimized alpha matting parameters (when enabled):
    // For general images: 240-10-10 (balanced)
    // For fine details (hair/fur): 240-10-3 (less erosion)
    property int foregroundThreshold: 240  // Higher = more foreground preserved
    property int backgroundThreshold: 10   // Lower = more background removed
    property int erodeSize: 10             // Lower = finer edges (more detail)

    // --- Internal ---
    property string _inputPath: ""
    property string _outputPath: ""
    property string _current_depth_path:""
    // --- States ---
    property string state: "idle" // idle, running, success, error, aborted

    readonly property bool isBusy: state === "running"

    // --- Process ---
    Process {
        id: proc
        stdout: SplitParser {
            onRead: data => root.stdoutReady(data)
        }
        stderr: SplitParser {
            onRead: data => root.stderrReady(data)
        }
        onStarted: {
            root.state = "running";
            root.started(root._inputPath, root._outputPath);
        }
        onExited: (exitCode, exitStatus) => {
            const crashed = (exitStatus !== 0);
            const success = !crashed && (exitCode === 0);

            root.state = crashed ? "aborted" : success ? "success" : "error";
            root.finished(success, root._outputPath, exitCode);

            root._inputPath = "";
            root._outputPath = "";
        }
    }

    // --- Signals ---
    signal started(string inputPath, string outputPath)
    signal stdoutReady(string chunk)
    signal stderrReady(string chunk)
    signal finished(bool success, string outputPath, int exitCode)

    // --- Helper: build base command ---
    function _buildCommand(args) {
        const venvPath = FileUtils.trimFileProtocol(Directories.venv);
        const scriptPath = FileUtils.trimFileProtocol(
            Directories.scriptsDir + "/create_depth_image_rembg.py"
        );

        return ["uv", "--directory", venvPath, "run", scriptPath].concat(args);
    }

    // --- Helper: build process args ---
    function _buildProcessArgs(inputPath, outputPath, opts) {
        const trimmedInput = FileUtils.trimFileProtocol(inputPath);
        const trimmedOutput = FileUtils.trimFileProtocol(outputPath);

        const args = [
            trimmedInput,
            trimmedOutput,
            "-m", opts?.model ?? model
        ];

        if (opts?.alphaMatting ?? alphaMatting) {
            args.push("-a");
        }

        args.push("-ft", String(opts?.foregroundThreshold ?? foregroundThreshold));
        args.push("-bt", String(opts?.backgroundThreshold ?? backgroundThreshold));
        args.push("-e", String(opts?.erodeSize ?? erodeSize));

        return args;
    }

    // --- Helper: run command ---
    function _runCommand(args, outputPath, inputPath = "") {
        _inputPath = inputPath;
        _outputPath = outputPath;
        proc.command = _buildCommand(args);
        proc.running = true;
    }

    // --- Main API ---
    function removeBackground(inputPath, outputPath, opts = {}) {
        if (!inputPath || !outputPath) {
            root.state = "error";
            root.finished(false, outputPath, -1);
            return;
        }

        abort();

        const processArgs = _buildProcessArgs(inputPath, outputPath, opts);
        _runCommand(processArgs, outputPath, inputPath);
    }

    function abort() {
        if (proc.running) {
            proc.running = false;
            root.state = "aborted";
        }
    }
    function process_current_bg(){
        const inputPath = FileUtils.trimFileProtocol(Mem.states.desktop.bg.currentBg);
        const outputPath = FileUtils.trimFileProtocol(
            Directories.depthCache +
            Qt.md5(inputPath) +
            ".png"
        );
        root._current_depth_path = outputPath
        removeBackground(inputPath, outputPath);
    }
    function reset() {
        abort();
        root.state = "idle";
        root._inputPath = "";
        root._outputPath = "";
    }

    // --- Preset Configurations ---

    // Fast mode: No alpha matting, fastest processing
    readonly property var presetFast: ({
        "model": "isnet-general-use",
        "alphaMatting": false
    })

    // Quality mode: Alpha matting enabled for better edges
    readonly property var presetQuality: ({
        "model": "isnet-general-use",
        "alphaMatting": true,
        "foregroundThreshold": 240,
        "backgroundThreshold": 10,
        "erodeSize": 10
    })

    // Fine detail mode: For images with complex edges (hair, fur)
    readonly property var presetFineDetail: ({
        "model": "isnet-general-use",
        "alphaMatting": true,
        "foregroundThreshold": 240,
        "backgroundThreshold": 10,
        "erodeSize": 3  // Less erosion for finer details
    })
}
