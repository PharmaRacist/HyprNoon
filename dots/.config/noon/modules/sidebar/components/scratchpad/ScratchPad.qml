pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Item {
    id: root
    // Configuration properties
    property string notesDirectory: Directories.documents + "/Notes"
    property string currentFileName: "latex_notes.md"
    property string currentFilePath: notesDirectory + "/" + currentFileName
    property bool autoSave: true
    property bool expandView: root.expanded
    property int autoSaveInterval: 5000 // 3 seconds
    // State properties
    property bool isDirty: false
    property bool isLoading: false
    property string lastSaved: ""
    // LaTeX rendering properties
    property bool renderMarkdown: true
    property bool enableMouseSelection: true
    property bool editing: true
    property list<string> renderedLatexHashes: []
    property string renderedSegmentContent: ""
    property string segmentContent: ""
    property var latexRegex: /(\$\$(?:[\s\S]+?)\$\$)|(\$ (?:[^\$]+?)\$)|(\\\[(?:[\s\S]+?)\\\\])|(\\\((?:[\s\S]+?)\)\\))/g
    Layout.fillWidth: true
    Layout.fillHeight: true
    // anchors.fill: parent
    clip: true
    Component.onCompleted: {
        loadCurrentNote();
        textArea.forceActiveFocus();
    }
    // Auto-save timer
    Timer {
        id: autoSaveTimer
        interval: root.autoSaveInterval
        running: root.autoSave && root.isDirty && !root.isLoading
        repeat: false
        onTriggered: saveCurrentNote()
    }
    // LaTeX rendering timer
    Timer {
        id: renderTimer
        interval: 1000
        repeat: false
        onTriggered: {
            renderLatex();
            for (const hash of renderedLatexHashes) {
                handleRenderedLatex(hash, true);
            }
        }
    }
    // File management using FileView
    FileView {
        id: noteFileView
        path: root.currentFilePath
        onLoaded: {
            try {
                root.isLoading = true;
                const fileContents = noteFileView.text();
                root.segmentContent = fileContents;
                if (root.editing) {
                    textArea.text = root.segmentContent;
                }
                root.isDirty = false;
                root.isLoading = false;
            } catch (error) {
                // File exists but couldn't be read
                root.segmentContent = "# " + root.getCurrentDateString() + "\n\n";
                if (root.editing) {
                    textArea.text = root.segmentContent;
                }
                root.isDirty = false;
                root.isLoading = false;
            }
        }
        onLoadFailed: error => {
            root.isLoading = true;
            if (error == FileViewError.FileNotFound) {
                // File doesn't exist, start with default content
                root.segmentContent = "# " + root.getCurrentDateString() + "\n\n";
                if (root.editing) {
                    textArea.text = root.segmentContent;
                }
                root.isDirty = true; // Mark as dirty to trigger initial save
                root.saveCurrentNote(); // Create the file
            } else {
                // Other error, start with empty content
                root.segmentContent = "# " + root.getCurrentDateString() + "\n\n";
                if (root.editing) {
                    textArea.text = root.segmentContent;
                }
                root.isDirty = false;
            }
            root.isLoading = false;
        }
    }
    // LaTeX rendering functions
    function renderLatex() {
        latexRegex.lastIndex = 0;
        let match;
        while ((match = latexRegex.exec(segmentContent)) !== null) {
            let expression = match[1] || match[2] || match[3] || match[4];
            if (expression) {
                Qt.callLater(() => {
                    const [renderHash, isNew] = LatexService.requestRender(expression.trim());
                    if (!renderedLatexHashes.includes(renderHash)) {
                        renderedLatexHashes.push(renderHash);
                    }
                });
            }
        }
    }
    function handleRenderedLatex(hash, force = false) {
        if (renderedLatexHashes.includes(hash) || force) {
            const imagePath = LatexService.renderedImagePaths[hash];
            const markdownImage = `![latex](${imagePath})`;
            const expression = LatexService.processedExpressions[hash];
            renderedSegmentContent = renderedSegmentContent.replace(expression, markdownImage);
        }
    }
    // File management functions
    function loadCurrentNote() {
        noteFileView.path = currentFilePath;
        noteFileView.reload();
    }
    function saveCurrentNote() {
        if (isLoading)
            return;
        try {
            noteFileView.setText(segmentContent);
            isDirty = false;
            lastSaved = new Date().toLocaleTimeString();
            saveStatusText.text = "Saved";
            saveStatusText.color = Appearance.colors.m3.m3primary;
        } catch (error) {
            saveStatusText.text = "Error saving file";
            saveStatusText.color = Appearance.colors.m3.m3error;
        }
    }
    function getCurrentDateString() {
        var date = new Date();
        return date.toLocaleDateString() + " - " + date.toLocaleTimeString();
    }
    // Property change handlers
    onSegmentContentChanged: {
        renderedSegmentContent = segmentContent;
        if (!editing && segmentContent) {
            renderLatex();
        }
        if (!isLoading) {
            isDirty = true;
            if (autoSave) {
                autoSaveTimer.restart();
            }
        }
    }
    onRenderedSegmentContentChanged: {
        if (renderedSegmentContent && !editing) {
            textArea.text = renderedSegmentContent;
        }
    }
    onEditingChanged: {
        if (!editing) {
            renderLatex();
        } else {
            textArea.text = segmentContent;
        }
    }
    // LaTeX render completion handler
    Connections {
        target: LatexService
        function onRenderFinished(hash, imagePath) {
            const expression = LatexService.processedExpressions[hash];
            handleRenderedLatex(hash);
        }
    }
    // Background watermark
    StyledText {
        visible: true
        font.pixelSize: 500
        text: "text_snippet"
        font.family: Appearance.fonts.family.iconMaterial
        color: Appearance.colors.m3.m3secondaryContainer
        opacity: 0.15
        anchors {
            left: parent.left
            leftMargin: 200
            bottom: parent.bottom
            bottomMargin: -120
        }
        transform: Rotation {
            angle: 45
        }
    }
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        // Header with controls
        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 0
            Layout.leftMargin: 15
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    id: fileNameLabel
                    text: root.currentFileName
                    Layout.fillWidth: true
                    font.family: Appearance.fonts.family.main
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.fonts.sizes.title
                    horizontalAlignment: Text.AlignLeft
                }
                Label {
                    id: saveStatusText
                    text: root.isDirty ? "Unsaved changes..." : (root.lastSaved ? "Saved at " + root.lastSaved : "Ready")
                    color: root.isDirty ? Appearance.colors.m3.m3tertiary : Appearance.colors.m3.m3primary
                    Layout.fillWidth: true
                    font.family: Appearance.fonts.family.main
                    font.pixelSize: Appearance.fonts.sizes.small
                    horizontalAlignment: Text.AlignLeft
                }
            }
            Item {
                Layout.fillWidth: true
            }
            RowLayout {
                spacing: 8
                RippleButton {
                    id: editToggleButton
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    toggled: root.editing
                    contentItem: MaterialSymbol {
                        text: "edit"
                        font.pixelSize: 20
                        anchors.centerIn: parent
                        color: editToggleButton.toggled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                    onPressed: root.editing = !root.editing
                }
            }
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            TextArea {
                id: textArea
                // Styling
                color: Appearance.colors.m3.m3onSurface
                font.pixelSize: Appearance.fonts.sizes.normal + 2
                font.family: root.editing ? Appearance.fonts.family.main : Appearance.fonts.family.main
                font.hintingPreference: Font.PreferNoHinting
                selectByMouse: root.enableMouseSelection || root.editing
                wrapMode: TextArea.Wrap
                readOnly: !root.editing
                focus: true
                // Text formatting
                textFormat: root.renderMarkdown && !root.editing ? TextEdit.MarkdownText : TextEdit.PlainText
                renderType: Text.NativeRendering
                selectedTextColor: Appearance.colors.m3.m3onSecondaryContainer
                selectionColor: Appearance.colors.colSecondaryContainer
                // Placeholder
                placeholderText: root.editing ? "Start typing your notes here..." : "Switch to edit mode to start writing..."
                placeholderTextColor: Appearance.colors.m3.m3onSurfaceVariant
                // Background
                background: null
                // Handle text changes
                onTextChanged: {
                    if (root.editing && !root.isLoading) {
                        root.segmentContent = text;
                    }
                }
                // Handle link clicks
                onLinkActivated: link => {
                    Qt.openUrlExternally(link);
                }
                // Custom mouse area for cursor handling
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : (root.enableMouseSelection || root.editing) ? Qt.IBeamCursor : Qt.ArrowCursor
                }
                // Keyboard shortcuts
                Keys.onPressed: event => {
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_S) {
                            root.saveCurrentNote();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_E) {
                            root.editing = !root.editing;
                            event.accepted = true;
                        }
                    }
                }
            }
        }
    }
}
