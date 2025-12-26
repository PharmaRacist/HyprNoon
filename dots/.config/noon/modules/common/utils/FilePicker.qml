import QtQuick
import Quickshell

/**
 * Reusable KDialog file picker component with lazy loading
 * Process is only created when open() is called
 */
Item {
    id: root

    // Predefined file filter arrays
    readonly property var filterPresets: ({
        "ALL": {
            "name": "All files",
            "patterns": ["*"]
        },
        "IMAGES": {
            "name": "Image files",
            "patterns": ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.webp", "*.svg", "*.ico", "*.tiff", "*.tif"]
        },
        "DOCUMENTS": {
            "name": "Document files",
            "patterns": ["*.pdf", "*.doc", "*.docx", "*.txt", "*.rtf", "*.odt", "*.xls", "*.xlsx", "*.ppt", "*.pptx", "*.csv"]
        },
        "VIDEOS": {
            "name": "Video files",
            "patterns": ["*.mp4", "*.mkv", "*.avi", "*.mov", "*.wmv", "*.flv", "*.webm", "*.m4v", "*.mpg", "*.mpeg"]
        },
        "AUDIO": {
            "name": "Audio files",
            "patterns": ["*.mp3", "*.wav", "*.ogg", "*.flac", "*.aac", "*.m4a", "*.wma", "*.opus", "*.oga"]
        },
        "ARCHIVES": {
            "name": "Archive files",
            "patterns": ["*.zip", "*.tar", "*.gz", "*.bz2", "*.xz", "*.7z", "*.rar", "*.tar.gz", "*.tar.bz2", "*.tar.xz"]
        },
        "CODE": {
            "name": "Code files",
            "patterns": ["*.js", "*.py", "*.java", "*.cpp", "*.c", "*.h", "*.hpp", "*.cs", "*.go", "*.rs", "*.rb", "*.php", "*.html", "*.css", "*.qml"]
        },
        "TEXT": {
            "name": "Text files",
            "patterns": ["*.txt", "*.md", "*.log", "*.json", "*.xml", "*.yaml", "*.yml", "*.ini", "*.conf", "*.cfg"]
        }
    })
    // Configurable properties
    property string title: "Select File"
    property bool multipleSelection: false
    property bool directoryMode: false
    property bool saveMode: false
    property string currentFolder: "~"
    property var fileFilters: []
    property string separator: "\n"

    // Signals
    signal fileSelected(var files)
    signal cancelled()
    signal error(string message)

    // Public API
    function open() {
        if (pickerLoader.item && pickerLoader.item.running) {
            console.warn("[FilePicker] Picker already running");
            return ;
        }
        if (!pickerLoader.active)
            pickerLoader.active = true;

        Qt.callLater(() => {
            if (pickerLoader.item)
                pickerLoader.item.running = true;

        });
    }

    // Helper: Build kdialog filter string
    function buildKDialogFilter() {
        if (fileFilters.length === 0)
            return "";

        // KDialog format: "Name1 (*.ext1 *.ext2)|Name2 (*.ext3)"
        const filterStrings = fileFilters.map((filter) => {
            if (filter.name && filter.patterns) {
                const patterns = Array.isArray(filter.patterns) ? filter.patterns.join(" ") : filter.patterns;
                return `${filter.name} (${patterns})`;
            }
            return "";
        }).filter((f) => {
            return f !== "";
        });
        return filterStrings.join("|");
    }

    // Lazy loader for the Process
    LazyLoader {
        id: pickerLoader

        active: false
        component: pickerComponent

        Component {
            id: pickerComponent

            Process {
                id: picker

                property string output: ""
                property string errorOutput: ""

                command: {
                    let args = ["kdialog"];
                    // Title
                    if (root.title)
                        args.push("--title", root.title);

                    // Selection mode
                    if (root.directoryMode) {
                        args.push("--getexistingdirectory");
                        args.push(root.currentFolder);
                    } else if (root.saveMode) {
                        args.push("--getsavefilename");
                        args.push(root.currentFolder);
                        const filter = root.buildKDialogFilter();
                        if (filter)
                            args.push(filter);

                    } else {
                        // Open file(s)
                        args.push("--getopenfilename");
                        args.push(root.currentFolder);
                        const filter = root.buildKDialogFilter();
                        if (filter)
                            args.push(filter);

                        // Multiple selection
                        if (root.multipleSelection) {
                            args.push("--multiple");
                            args.push("--separate-output");
                        }
                    }
                    return args;
                }
                running: false
                onExited: (exitCode, exitStatus) => {
                    if (exitCode === 0) {
                        const trimmed = output.trim();
                        if (trimmed) {
                            if (root.multipleSelection) {
                                const files = trimmed.split("\n").filter((f) => {
                                    return f.trim() !== "";
                                });
                                root.fileSelected(files);
                            } else {
                                root.fileSelected(trimmed);
                            }
                        } else {
                            root.cancelled();
                        }
                    } else if (exitCode === 1) {
                        // User cancelled
                        root.cancelled();
                    } else {
                        // Error occurred
                        root.error(errorOutput.trim() || "File picker failed");
                    }
                    // Reset output for next use
                    output = "";
                    errorOutput = "";
                }

                stdout: SplitParser {
                    onRead: (line) => {
                        picker.output += line + "\n";
                    }
                }

                stderr: SplitParser {
                    onRead: (line) => {
                        picker.errorOutput += line + "\n";
                        console.error(`[FilePicker] ${line}`);
                    }
                }

            }

        }

    }

}
