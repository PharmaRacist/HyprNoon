pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.utils

Singleton {
    id: root

    property string filePath: Directories.documents + "/Notes/noon_notes.md"
    property string content: ""
    property bool isDirty: false
    property string lastSaved: ""
    property bool isLoaded: false
    property string _pendingNote: ""

    FileView {
        id: noteFile
        path: root.filePath

        onLoaded: {
            root.content = noteFile.text() || getDefaultContent();
            root.isDirty = false;
            root.isLoaded = true;
            if (root._pendingNote)
                root.note(root._pendingNote);
        }

        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.content = getDefaultContent();
                root.isLoaded = true;
                save();
            }
        }

        onSaved: {
            root.isDirty = false;
            root.lastSaved = new Date().toISOString();
        }
    }

    function getDefaultContent() {
        var date = new Date();
        return "# " + date.toLocaleDateString() + " - " + date.toLocaleTimeString() + "\n\n";
    }

    function save() {
        noteFile.setText(root.content);
    }

    function note(text) {
        if (!text?.trim())
            return;
        if (!root.isLoaded) {
            root._pendingNote = text;
            noteFile.reload();
            return;
        }
        root.content += text.trim() + "\n";
        root.isDirty = true;
        save();
    }

    Component.onCompleted: noteFile.reload()
}
