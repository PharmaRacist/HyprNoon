import QtQuick
import Quickshell
import qs.modules.common

LazyLoader {
    property bool enabled: true

    active: enabled && Mem.ready
    component: children[0]
}
