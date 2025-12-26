import QtQuick
import Quickshell
import qs.modules.common

FileView {
    id: root

    required property string filePath
    property bool autoCreateOnError: true
    property string fileName
    property alias data: root.adapter
    property Timer reloadTimer: timer.createObject(root)
    property bool state: false
    property Component timer

    timer: Timer {
        id: reloadTimer

        interval: 100
        onTriggered: root.reload()
    }

    filePath: (state ? Directories.state + "/" : Directories.shellConfigs) + fileName + ".json"
    preload: true
    printErrors: true
    watchChanges: true
    path: filePath
    onFileChanged: reloadTimer.restart()
    onAdapterUpdated: root.writeAdapter()
    onLoadFailed: function(error) {
        if (autoCreateOnError && error === FileViewError.FileNotFound)
            root.writeAdapter();

    }
}
