import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property bool editing: true
    property int autoSaveInterval: 5000

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    Component.onCompleted: {
        textArea.text = NotesService.content;
        textArea.forceActiveFocus();
    }

    // Auto-save timer
    Timer {
        id: autoSaveTimer

        interval: root.autoSaveInterval
        running: NotesService.isDirty
        repeat: false
        onTriggered: NotesService.save()
    }

    // Timer to update relative time display
    Timer {
        interval: 1000
        running: NotesService.lastSaved !== ""
        repeat: true
        onTriggered: {
            if (!NotesService.isDirty && NotesService.lastSaved)
                statusLabel.text = "Saved " + DateTimeService.getRelativeTime(NotesService.lastSaved);

        }
    }

    // Sync content changes from service
    Connections {
        function onContentChanged() {
            if (textArea.text !== NotesService.content)
                textArea.text = NotesService.content;

        }

        target: NotesService
    }

    // Background watermark
    StyledText {
        visible: true
        font.pixelSize: 500
        text: "text_snippet"
        font.family: Fonts.family.iconMaterial
        color: Colors.m3.m3secondaryContainer
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

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 0
            Layout.leftMargin: 15
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: "Notes"
                    Layout.fillWidth: true
                    font.family: Fonts.family.main
                    color: Colors.colOnLayer0
                    font.pixelSize: Fonts.sizes.title
                }

                Label {
                    id: statusLabel

                    text: NotesService.isDirty ? "Unsaved changes..." : (NotesService.lastSaved ? "Saved " + DateTimeService.getRelativeTime(NotesService.lastSaved) : "Ready")
                    color: NotesService.isDirty ? Colors.m3.m3tertiary : Colors.m3.m3primary
                    Layout.fillWidth: true
                    font.family: Fonts.family.main
                    font.pixelSize: Fonts.sizes.small
                }

            }

            Item {
                Layout.fillWidth: true
            }

            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: Rounding.small
                toggled: root.editing
                onPressed: root.editing = !root.editing

                contentItem: MaterialSymbol {
                    text: "edit"
                    font.pixelSize: 20
                    anchors.centerIn: parent
                    color: parent.parent.toggled ? Colors.colOnPrimaryContainer : Colors.colOnLayer1
                }

            }

        }

        // Text editor
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: textArea

                color: Colors.m3.m3onSurface
                font.pixelSize: Fonts.sizes.normal + 2
                font.family: Fonts.family.main
                selectByMouse: root.editing
                wrapMode: TextArea.Wrap
                readOnly: !root.editing
                focus: true
                textFormat: root.editing ? TextEdit.PlainText : TextEdit.MarkdownText
                selectedTextColor: Colors.m3.m3onSecondaryContainer
                selectionColor: Colors.colSecondaryContainer
                placeholderText: root.editing ? "Start typing your notes here..." : "Switch to edit mode to start writing..."
                placeholderTextColor: Colors.m3.m3onSurfaceVariant
                background: null
                onTextChanged: {
                    if (root.editing && text !== NotesService.content) {
                        NotesService.content = text;
                        NotesService.isDirty = true;
                        autoSaveTimer.restart();
                    }
                }
                onLinkActivated: (link) => {
                    return Qt.openUrlExternally(link);
                }
                Keys.onPressed: (event) => {
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_S) {
                            NotesService.save();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_E) {
                            root.editing = !root.editing;
                            event.accepted = true;
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : root.editing ? Qt.IBeamCursor : Qt.ArrowCursor
                }

            }

        }

    }

}
