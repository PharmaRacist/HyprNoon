pragma Singleton
import Quickshell

Singleton {
    id: root

    /**
     * Trims the File protocol off the input string
     * @param {string} str
     * @returns {string}
     */
    function trimFileProtocol(str) {
        str = String(str);
        return str.startsWith("file://") ? str.slice(7) : str;
    }

    /**
     * Extracts the file name from a file path
     * @param {string} str
     * @returns {string}
     */
    function fileNameForPath(str) {
        if (typeof str !== "string") return "";
        const trimmed = trimFileProtocol(str);
        return trimmed.split(/[\\/]/).pop();
    }
    /**
         * Removes the file extension from a file path or name
         * @param {string} str
         * @returns {string}
         */
        function trimFileExt(str) {
            if (typeof str !== "string") return "";
            const trimmed = trimFileProtocol(str);
            const lastDot = trimmed.lastIndexOf(".");
            if (lastDot > -1 && lastDot > trimmed.lastIndexOf("/")) {
                return trimmed.slice(0, lastDot);
            }
            return trimmed;
        }
    /**
        * Returns the parent directory of a given file path
        * @param {string} str
        * @returns {string}
        */
       function parentDirectory(str) {
           if (typeof str !== "string") return "";
           const trimmed = trimFileProtocol(str);
           const parts = trimmed.split(/[\\/]/);
           if (parts.length <= 1) return "";
           parts.pop();
           return parts.join("/");
       }
    /**
     * Extracts the folder name from a directory path
     * @param {string} str
     * @returns {string}
     */
    function folderNameForPath(str) {
        if (typeof str !== "string") return "";
        const trimmed = trimFileProtocol(str);
        // Remove trailing slash if present
        const noTrailing = trimmed.endsWith("/") ? trimmed.slice(0, -1) : trimmed;
        if (!noTrailing) return "";
        return noTrailing.split(/[\\/]/).pop();
    }


    /**
     * Extracts the filename (with extension) from a path
     * @param {string} path
     * @returns {string}
     */
    function getEscapedFileName(path) {
        // Remove file:// if present
        const trimmed = trimFileProtocol(path);
        // Use only the last part after the last slash
        const fileName = trimmed.split(/[\/\\]/).pop();
        // Escape special characters except filename (if needed)
        return encodeURIComponent(fileName);
    }

    /**
     * Extracts and escapes the filename (without extension) from a path
     * @param {string} path
     * @returns {string}
     */
    function getEscapedFileNameWithoutExtension(path) {
        const trimmed = trimFileProtocol(path);
        const fileName = trimmed.split(/[\/\\]/).pop(); // e.g., "my song.mp3"
        const lastDotIndex = fileName.lastIndexOf(".");
        const nameWithoutExtension = lastDotIndex !== -1 ? fileName.slice(0, lastDotIndex) : fileName;
        return encodeURIComponent(nameWithoutExtension);
    }

    /**
     * Extracts and escapes the extension (without the dot) from a path
     * @param {string} path
     * @returns {string}
     */
    function getEscapedFileExtension(path) {
        const trimmed = trimFileProtocol(path);
        const fileName = trimmed.split(/[\/\\]/).pop(); // e.g., "track.mp3"
        const lastDotIndex = fileName.lastIndexOf(".");
        const extension = lastDotIndex !== -1 && lastDotIndex < fileName.length - 1 ? fileName.slice(lastDotIndex + 1) : "";
        return encodeURIComponent(extension);
    }

    /**
     * Inserts text before the file extension and returns the full modified path.
     * Example: insertTextBeforeExtension("file:///path/to/image.png", "_layer") → "file:///path/to/image_layer.png"
     *
     * @param {string} path - Original file path
     * @param {string} insertText - Text to insert before the extension
     * @returns {string} - Modified path with text inserted
     */
    function insertTextBeforeExtension(path, insertText) {
        if (!path || typeof path !== "string")
            return "";
        const hasFileProtocol = path.startsWith("file://");
        const trimmed = hasFileProtocol ? path.slice(7) : path;
        const parts = trimmed.split(/[\/\\]/);
        const fileName = parts.pop();
        if (!fileName)
            return "";
        const lastDotIndex = fileName.lastIndexOf(".");
        const nameWithoutExt = lastDotIndex !== -1 ? fileName.slice(0, lastDotIndex).replace(/\s+$/, "") // ← manually trim end
        : fileName;
        const ext = lastDotIndex !== -1 ? fileName.slice(lastDotIndex) : "";
        const newFileName = nameWithoutExt + insertText + ext;
        const newPath = [...parts, newFileName].join("/");
        return hasFileProtocol ? "file://" + newPath : newPath;
    }

    /**
     * Checks if a file exists at the given path
     * @param {string} filePath - Path to the file (supports file:// protocol)
     * @returns {boolean} - True if file exists, false otherwise
     */
function fileExists(filePath) {
    if (!filePath) {
        return false;
    }

    let pathToCheck = filePath;
    if (typeof filePath === "object" && filePath.toString) {
        // Handle QML Url objects (e.g., if passed as Url {})
        pathToCheck = filePath.toString();
    } else if (typeof filePath !== "string") {
        console.warn("fileExists: Invalid input type:", typeof filePath);
        return false;
    }

    // Manual trim to avoid recursion in FileUtils.trimFileProtocol
    let trimmed = pathToCheck;
    if (pathToCheck.startsWith("file://")) {
        trimmed = pathToCheck.substring(7);  // Strip "file://" prefix
    } else if (pathToCheck.startsWith("file:///")) {
        trimmed = pathToCheck.substring(8);  // Handle triple-slash variant (absolute paths)
    }

    try {
        const exists = FileUtils.fileExists(trimmed);
        return exists;
    } catch (error) {
        return false;
    }
}    /**
     * Gets file info using QuickShell's IO capabilities
     * @param {string} filePath - Path to the file
     * @returns {object|null} - File info object or null if error
     */
    function getFileInfo(filePath) {
        if (!filePath || typeof filePath !== "string")
            return null;

        try {
            const trimmed = trimFileProtocol(filePath);
            return Io.fileInfo(trimmed);
        } catch (error) {
            console.warn("GetFileInfo error:", error);
            return null;
        }
    }
    function deleteItem(path:string) {
        Quickshell.execDetached(["bash","-c", `rm -rf ${trimFileProtocol(path)}`]);
    }
}
