import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common

Separator {
    property bool extraVisibleCondition: true

    visible: extraVisibleCondition && parent.children.length > 2
    Layout.leftMargin: Padding.large
    Layout.rightMargin: Padding.large
    Layout.bottomMargin: Padding.verylarge
}
