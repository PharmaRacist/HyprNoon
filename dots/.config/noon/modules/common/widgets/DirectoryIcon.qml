// From https://github.com/caelestia-dots/shell with modifications.
// License: GPLv3

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions

Image {
    id: root

    required property var fileModelData

    asynchronous: true
    fillMode: Image.PreserveAspectFit
    source: {
        if (!fileModelData.fileIsDir)
            return Noon.iconPath("application-x-zerosize");

        if ([Directories.documents, Directories.downloads, Directories.music, Directories.pictures, Directories.videos].some((dir) => {
            return FileUtils.trimFileProtocol(dir) === fileModelData.filePath;
        }))
            return Noon.iconPath(`folder-${fileModelData.fileName.toLowerCase()}`);

        return Noon.iconPath("inode-directory");
    }
    onStatusChanged: {
        if (status === Image.Error)
            source = Noon.iconPath("error");

    }

    Process {
        running: !fileModelData.fileIsDir
        command: ["file", "--mime", "-b", fileModelData.filePath]

        stdout: StdioCollector {
            onStreamFinished: {
                const mime = text.split(";")[0].replace("/", "-");
                root.source = Images.validImageTypes.some((t) => {
                    return mime === `image-${t}`;
                }) ? fileModelData.fileUrl : Noon.iconPath(mime);
            }
        }

    }

}
