pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common

/**
 * Singleton service for translation using the `trans` commandline tool.
 */

Singleton {
    id: service

    // Translation state
    property string translatedText: ""
    property list<string> languages: []
    property bool isTranslating: false

    // Language settings (persisted via Mem.options)
    property string targetLanguage: Mem.options.language.translator.targetLanguage ?? "en"
    property string sourceLanguage: Mem.options.language.translator.sourceLanguage ?? "auto"

    // Internal state
    property string _currentInputText: ""
    property var _translationCallback: null

    // Initialize languages on startup
    Component.onCompleted: {
        loadLanguages();
    }

    /**
     * Load available languages from trans command
     */
    function loadLanguages() {
        getLanguagesProc.running = true;
    }

    /**
     * Translate text from source to target language
     * @param text - Text to translate
     * @param callback - Optional callback function(translatedText) called when translation completes
     */
    function translate(text, callback) {
        if (!text || text.trim().length === 0) {
            service.translatedText = "";
            if (callback)
                callback("");
            return;
        }

        service._currentInputText = text.trim();
        service._translationCallback = callback;
        service.isTranslating = true;

        // Restart translation process
        translateProc.running = false;
        translateProc.buffer = "";
        translateProc.running = true;
    }

    /**
     * Set target language and optionally retranslate
     * @param lang - Language code
     * @param retranslate - Whether to retranslate current text
     */
    function setTargetLanguage(lang, retranslate) {
        service.targetLanguage = lang;
        if (retranslate && service._currentInputText.length > 0) {
            translate(service._currentInputText, service._translationCallback);
        }
    }

    /**
     * Set source language and optionally retranslate
     * @param lang - Language code
     * @param retranslate - Whether to retranslate current text
     */
    function setSourceLanguage(lang, retranslate) {
        service.sourceLanguage = lang;
        if (retranslate && service._currentInputText.length > 0) {
            translate(service._currentInputText, service._translationCallback);
        }
    }

    // Translation process
    Process {
        id: translateProc
        command: ["bash", "-c", `trans -no-theme -no-bidi` + ` -source '${StringUtils.shellSingleQuoteEscape(service.sourceLanguage)}'` + ` -target '${StringUtils.shellSingleQuoteEscape(service.targetLanguage)}'` + ` -no-ansi '${StringUtils.shellSingleQuoteEscape(service._currentInputText)}'`]
        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data + "\n";
            }
        }

        onExited: (exitCode, exitStatus) => {
            // Split into sections by double newlines
            const sections = translateProc.buffer.trim().split(/\n\s*\n/);

            // Extract translated text (second section)
            const result = sections.length > 1 ? sections[1].trim() : "";
            service.translatedText = result;
            service.isTranslating = false;

            // Call callback if provided
            if (service._translationCallback) {
                service._translationCallback(result);
            }
        }
    }

    // Language list process
    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages", "-no-bidi"]
        property list<string> bufferList: ["auto"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                getLanguagesProc.bufferList.push(data.trim());
            }
        }

        onExited: (exitCode, exitStatus) => {
            // Filter, sort, and ensure "auto" is first
            let langs = getLanguagesProc.bufferList.filter(lang => lang.trim().length > 0 && lang !== "auto").sort((a, b) => a.localeCompare(b));
            langs.unshift("auto");
            service.languages = langs;
            getLanguagesProc.bufferList = [];
        }
    }
}
