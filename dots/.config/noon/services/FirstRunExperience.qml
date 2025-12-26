import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
pragma Singleton

Singleton {
    id: root

    property string firstRunFilePath: `${Directories.state}/user/first_run.txt`
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property string firstRunNotifSummary: "Welcome!"
    property string firstRunNotifBody: "Hit Super+/ for a list of keybinds"
    property string defaultWallpaperPath: FileUtils.trimFileProtocol(`${Directories.config}/noon/assets/images/default_wallpaper.png`)

    function load() {
        firstRunFileView.reload();
    }

    function handleFirstRun() {
        Noon.notify(`'${root.firstRunNotifSummary}' '${root.firstRunNotifBody}'`);
        Appearance.getCurrentIconTheme();
    }

    FileView {
        id: firstRunFileView

        path: Qt.resolvedUrl(firstRunFilePath)
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                firstRunFileView.setText(root.firstRunFileContent);
                root.handleFirstRun();
            }
        }
    }

}
