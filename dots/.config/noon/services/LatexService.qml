pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common.functions
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.platform

/**
 * Renders LaTeX snippets with MicroTeX.
 * For every request:
 *   1. Hash it
 *   2. Check if the hash is already processed
 *   3. If not, render it with MicroTeX and mark as processed
 */
Singleton {
    id: root

    readonly property var renderPadding: 4
    property list<string> processedHashes: []
    property var processedExpressions: ({})
    property var renderedImagePaths: ({})
    property string microtexBinaryDir: "/opt/MicroTeX"
    property string microtexBinaryName: "LaTeX"
    property string latexOutputPath: Directories.latexOutput

    signal renderFinished(string hash, string imagePath)

    /**
     * Requests rendering of a LaTeX expression.
     * Returns the [hash, isNew]
     */
    function requestRender(expression) {
        const hash = Qt.md5(expression);
        const imagePath = `${latexOutputPath}/${hash}.svg`;

        if (processedHashes.includes(hash)) {
            renderFinished(hash, imagePath);
            return [hash, false];
        } else {
            root.processedHashes.push(hash);
            root.processedExpressions[hash] = expression;
        }

        const processQml = `
            import Quickshell.Io
            Process {
                id: microtexProcess${hash}
                running: true
                command: [ "bash", "-c",
                    "cd ${root.microtexBinaryDir} && ./${root.microtexBinaryName} -headless '-input=${StringUtils.shellSingleQuoteEscape(StringUtils.escapeBackslashes(expression))}' "
                    + "'-output=${imagePath}' "
                    + "'-textsize=${Fonts.sizes.normal}' "
                    + "'-padding=${renderPadding}' "
                    + "'-foreground=${Colors.colOnLayer1}' "
                    + "-maxwidth=0.85 "
                ]
                onExited: (exitCode, exitStatus) => {
                    renderedImagePaths["${hash}"] = "${imagePath}"
                    root.renderFinished("${hash}", "${imagePath}")
                    microtexProcess${hash}.destroy()
                }
            }
        `;

        Qt.createQmlObject(processQml, root, `MicroTeXProcess_${hash}`);
        return [hash, true];
    }
}