import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sidebar.components.apis
import qs.services

Item {
    id: root

    property var inputField: inputCanvas.inputTextArea

    onFocusChanged: focus => {
        if (focus)
            root.inputField.forceActiveFocus();
    }

    Timer {
        id: searchTimer
        interval: Mem.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: {
            const searchTerm = root.inputField?.text?.trim() ?? "";
            MedicalDictionaryService.search(searchTerm);
        }
    }

    // Format results for display
    function formatResults() {
        if (MedicalDictionaryService.results.length === 0) {
            return "";
        }

        let formatted = "";

        MedicalDictionaryService.results.forEach((result, index) => {
            // Handle suggestions
            if (result.suggestions) {
                formatted += "<p style='color: #888; font-style: italic;'>Did you mean:</p>";
                result.suggestions.forEach(suggestion => {
                    formatted += `<p style='margin-left: 20px;'>• ${suggestion}</p>`;
                });
                return;
            }

            // Word title
            formatted += `<h2 style='color: #2196F3; margin-bottom: 5px; font-weight: bold;'>${result.word.toUpperCase()}</h2>`;

            // Metadata
            let metadata = "";
            if (result.partOfSpeech) {
                metadata += `<span style='color: #666; font-style: italic;'>(${result.partOfSpeech})</span>`;
            }
            if (result.pronunciation) {
                metadata += metadata ? ` <span style='color: #888;'>/${result.pronunciation}/</span>` : `<span style='color: #888;'>/${result.pronunciation}/</span>`;
            }
            if (metadata) {
                formatted += `<p style='margin-bottom: 10px;'>${metadata}</p>`;
            }

            // Definitions
            if (result.definitions && result.definitions.length > 0) {
                formatted += "<div style='margin-left: 10px;'>";
                result.definitions.forEach((def, defIndex) => {
                    formatted += `<p style='margin-bottom: 8px; line-height: 1.4;'><strong>${defIndex + 1}.</strong> ${def}</p>`;
                });
                formatted += "</div>";
            } else {
                formatted += "<p style='color: #888; font-style: italic; margin-left: 10px;'>No definition available</p>";
            }

            // Separator
            if (index < MedicalDictionaryService.results.length - 1) {
                formatted += "<hr style='margin: 20px 0; border: 1px solid #ddd;' />";
            }
        });

        return formatted;
    }

    ColumnLayout {
        anchors.fill: parent

        StyledFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.implicitHeight

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent

                // Search results
                TextCanvas {
                    id: outputCanvas
                    isInput: false
                    Layout.fillHeight: true
                    Layout.minimumHeight: 120
                    placeholderText: MedicalDictionaryService.isSearching ? qsTr("Searching...") : qsTr("Medical definitions appear here...")
                    text: formatResults()

                    GroupButton {
                        id: copyButton
                        baseWidth: height
                        buttonRadius: Rounding.small
                        enabled: outputCanvas.displayedText.trim().length > 0 && !MedicalDictionaryService.isSearching
                        onClicked: {
                            Quickshell.clipboardText = outputCanvas.displayedText;
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Fonts.sizes.verylarge
                            text: "content_copy"
                            color: copyButton.enabled ? Colors.colOnLayer1 : Colors.colSubtext
                        }
                    }

                    GroupButton {
                        id: searchButton
                        baseWidth: height
                        buttonRadius: Rounding.small
                        enabled: MedicalDictionaryService.results.length > 0 && !MedicalDictionaryService.isSearching
                        onClicked: {
                            let url = Mem.options.search.engineBaseUrl + MedicalDictionaryService.lastSearchTerm + " medical definition";
                            for (let site of Mem.options.search.excludedSites) {
                                url += ` -site:${site}`;
                            }
                            Qt.openUrlExternally(url);
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Fonts.sizes.verylarge
                            text: "travel_explore"
                            color: searchButton.enabled ? Colors.colOnLayer1 : Colors.colSubtext
                        }
                    }

                    GroupButton {
                        id: clearButton
                        baseWidth: height
                        buttonRadius: Rounding.small
                        enabled: MedicalDictionaryService.results.length > 0
                        onClicked: {
                            MedicalDictionaryService.clear();
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Fonts.sizes.verylarge
                            text: "clear_all"
                            color: clearButton.enabled ? Colors.colOnLayer1 : Colors.colSubtext
                        }
                    }
                }
            }
        }

        // Search input
        TextCanvas {
            id: inputCanvas
            isInput: true
            placeholderText: qsTr("Enter medical term to search...")
            onInputTextChanged: {
                searchTimer.restart();
            }

            GroupButton {
                id: pasteButton
                baseWidth: height
                buttonRadius: Rounding.small
                onClicked: {
                    if (root.inputField) {
                        root.inputField.text = Quickshell.clipboardText;
                    }
                }

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Fonts.sizes.verylarge
                    text: "content_paste"
                    color: Colors.colOnLayer1
                }
            }

            GroupButton {
                id: deleteButton
                baseWidth: height
                buttonRadius: Rounding.small
                enabled: root.inputField?.text?.length > 0
                onClicked: {
                    if (root.inputField) {
                        root.inputField.text = "";
                    }
                    MedicalDictionaryService.clear();
                }

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Fonts.sizes.verylarge
                    text: "close"
                    color: deleteButton.enabled ? Colors.colOnLayer1 : Colors.colSubtext
                }
            }
        }
    }
}
