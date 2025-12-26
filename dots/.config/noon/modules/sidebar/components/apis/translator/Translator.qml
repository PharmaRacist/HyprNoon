import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.sidebar.components.apis
import qs.services

/**
 * Translator widget using TranslatorService singleton.
 */
Item {
    id: root

    // Widgets
    property var inputField: inputCanvas.inputTextArea
    // UI state
    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false // true for target language, false for source language

    function showLanguageSelectorDialog(isTargetLang: bool) {
        root.languageSelectorTarget = isTargetLang;
        root.showLanguageSelector = true;
    }

    onFocusChanged: (focus) => {
        if (focus)
            root.inputField.forceActiveFocus();

    }
    // Initialize service with saved preferences
    Component.onCompleted: {
        TranslatorService.targetLanguage = Mem.options.language.translator.targetLanguage;
        TranslatorService.sourceLanguage = Mem.options.language.translator.sourceLanguage;
    }

    // Debounce timer for translation
    Timer {
        id: translateTimer

        interval: Mem.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: () => {
            TranslatorService.translate(root.inputField.text);
        }
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

                // Target language button
                LanguageSelectorButton {
                    id: targetLanguageButton

                    displayText: TranslatorService.targetLanguage
                    onClicked: {
                        root.showLanguageSelectorDialog(true);
                    }
                }

                // Content translation output
                TextCanvas {
                    id: outputCanvas

                    property bool hasTranslation: (TranslatorService.translatedText.trim().length > 0)

                    isInput: false
                    placeholderText: qsTr("Translation goes here...")
                    text: hasTranslation ? TranslatorService.translatedText : ""

                    GroupButton {
                        id: copyButton

                        baseWidth: height
                        buttonRadius: Rounding.small
                        enabled: outputCanvas.displayedText.trim().length > 0
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
                        enabled: outputCanvas.displayedText.trim().length > 0
                        onClicked: {
                            let url = Mem.options.search.engineBaseUrl + outputCanvas.displayedText;
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

                }

            }

        }

        // Source language button
        LanguageSelectorButton {
            id: sourceLanguageButton

            displayText: TranslatorService.sourceLanguage
            onClicked: {
                root.showLanguageSelectorDialog(false);
            }
        }

        // Content input
        TextCanvas {
            id: inputCanvas

            isInput: true
            placeholderText: qsTr("Enter text to translate...")
            onInputTextChanged: {
                translateTimer.restart();
            }

            GroupButton {
                id: pasteButton

                baseWidth: height
                buttonRadius: Rounding.small
                onClicked: {
                    root.inputField.text = Quickshell.clipboardText;
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
                enabled: inputCanvas.inputTextArea.text.length > 0
                onClicked: {
                    root.inputField.text = "";
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

    // Language selector dialog
    Loader {
        anchors.fill: parent
        active: root.showLanguageSelector
        visible: root.showLanguageSelector
        z: 9999

        sourceComponent: SelectionDialog {
            id: languageSelectorDialog

            titleText: qsTr("Select Language")
            items: TranslatorService.languages
            defaultChoice: root.languageSelectorTarget ? TranslatorService.targetLanguage : TranslatorService.sourceLanguage
            onCanceled: () => {
                root.showLanguageSelector = false;
            }
            onSelected: (result) => {
                root.showLanguageSelector = false;
                if (!result || result.length === 0)
                    return ;

                // No selection made
                if (root.languageSelectorTarget) {
                    TranslatorService.setTargetLanguage(result, true);
                    Mem.options.language.translator.targetLanguage = result; // Save to config
                } else {
                    TranslatorService.setSourceLanguage(result, true);
                    Mem.options.language.translator.sourceLanguage = result; // Save to config
                }
            }
        }

    }

}
