import QtGraphicalEffects 1.12
import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import SddmComponents 2.0

Rectangle {
    id: root

    readonly property real scaleFactor: Math.max(0.5, Math.min(width / 1920, height / 1080))
    readonly property real baseUnit: 8 * scaleFactor
    // Color System
    readonly property color colPrimary: config.colPrimary || "#c7a1d8"
    readonly property color colOnPrimary: config.colOnPrimary || "#1a151f"
    readonly property color colSurface: config.colSurface || "#1c1822"
    readonly property color colSurfaceVariant: config.colSurfaceVariant || "#262130"
    readonly property color colOnSurface: config.colOnSurface || "#e9e4f0"
    readonly property color colOnSurfaceVariant: config.colOnSurfaceVariant || "#a79ab0"
    readonly property color colError: config.colError || "#e9899d"
    readonly property color colOutline: config.colOutline || "#342c42"
    // Font Size System
    readonly property real fontSizeTiny: 9 * scaleFactor
    readonly property real fontSizeSmall: 11 * scaleFactor
    readonly property real fontSizeMedium: 13 * scaleFactor
    readonly property real fontSizeLarge: 14 * scaleFactor
    readonly property real fontSizeXLarge: 18 * scaleFactor
    readonly property real fontSizeXXLarge: 25 * scaleFactor
    readonly property real fontSizeHuge: 32 * scaleFactor
    readonly property real fontSizeDisplay: 125 * scaleFactor
    // Other Properties
    readonly property real radiusL: 20 * scaleFactor
    readonly property real radiusM: 12 * scaleFactor
    readonly property real radiusCircle: 17 * scaleFactor
    readonly property string backgroundPath: config.background || "Assets/background.png"
    readonly property real blurRadius: config.blurRadius || 0

    width: Screen.width || 1920
    height: Screen.height || 1080
    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    Image {
        id: wallpaper

        anchors.fill: parent
        source: root.backgroundPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        clip: true
        visible: root.blurRadius <= 0
    }

    FastBlur {
        anchors.fill: parent
        source: wallpaper
        radius: root.blurRadius
        transparentBorder: false
        visible: root.blurRadius > 0
        cached: true
    }

    ColumnLayout {
        spacing: -6 * scaleFactor

        anchors {
            top: parent.top
            left: parent.left
            margins: 56 * scaleFactor
        }

        StyledText {
            text: Qt.formatTime(new Date(), "hh:mm")
            font.pixelSize: root.fontSizeDisplay
            font.bold: true
            color: root.colOnSurface
            Layout.fillWidth: true
        }

        StyledText {
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            font.pixelSize: root.fontSizeXXLarge
            font.bold: true
            color: root.colOnSurfaceVariant
            Layout.fillWidth: true
            Layout.leftMargin: 14 * scaleFactor
        }

        Anim on anchors.topMargin {
            from: -height - 56 * scaleFactor
            to: 56 * scaleFactor
        }

    }

    // User Switcher
    Controls.ComboBox {
        id: userList

        model: userModel
        textRole: "name"
        currentIndex: userModel.lastIndex
        implicitWidth: 200 * scaleFactor
        implicitHeight: 56 * scaleFactor
        visible: userModel.count > 1

        anchors {
            bottom: sessionList.top
            right: powerControls.left
            rightMargin: powerControls.spacing + 2
            bottomMargin: 8 * scaleFactor
        }

        delegate: Controls.ItemDelegate {
            width: userList.width
            height: 48 * scaleFactor
            text: model.name || ""
            highlighted: userList.highlightedIndex === index
            hoverEnabled: true

            contentItem: StyledText {
                text: parent.text
                color: parent.highlighted ? root.colPrimary : root.colOnSurfaceVariant
                font.pixelSize: root.fontSizeXLarge
                verticalAlignment: Text.AlignVCenter
                leftPadding: 12 * scaleFactor
                rightPadding: 12 * scaleFactor
                elide: Text.ElideRight
            }

            background: Rectangle {
                color: {
                    if (parent.down)
                        return Qt.rgba(root.colPrimary.r, root.colPrimary.g, root.colPrimary.b, 0.12);

                    if (parent.hovered)
                        return Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.08);

                    return "transparent";
                }

                Behavior on color {
                    CAnim {
                    }

                }

            }

        }

        indicator: MaterialSymbol {
            x: userList.width - width - (12 * scaleFactor)
            y: userList.topPadding + (userList.availableHeight - height) / 2
            text: "arrow_drop_down"
            font.pixelSize: 24 * scaleFactor
            color: root.colOnSurfaceVariant
            rotation: userList.popup.visible ? 180 : 0

            Behavior on rotation {
                Anim {
                }

            }

        }

        background: Rectangle {
            color: root.colSurfaceVariant
            radius: root.radiusM
            border.width: userList.visualFocus ? 2 * scaleFactor : 0
            border.color: root.colPrimary
            layer.enabled: userList.down || userList.hovered

            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 1 * scaleFactor
                radius: 2 * scaleFactor
                samples: 9
                color: Qt.rgba(0, 0, 0, 0.15)
                transparentBorder: true
            }

            Behavior on color {
                CAnim {
                }

            }

        }

        contentItem: StyledText {
            leftPadding: 12 * scaleFactor
            rightPadding: userList.indicator.width + (12 * scaleFactor)
            text: userList.displayText || ""
            font.pixelSize: root.fontSizeXLarge
            color: root.colOnSurfaceVariant
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        popup: Controls.Popup {
            y: userList.height + (4 * scaleFactor)
            width: userList.width
            implicitHeight: Math.min(contentItem.implicitHeight, 280 * scaleFactor)
            padding: 0
            topPadding: 8 * scaleFactor
            bottomPadding: 8 * scaleFactor

            enter: Transition {
                ParallelAnimation {
                    Anim {
                        property: "opacity"
                        from: 0
                        to: 1
                    }

                    Anim {
                        property: "scale"
                        from: 0.9
                        to: 1
                    }

                }

            }

            exit: Transition {
                Anim {
                    property: "opacity"
                    from: 1
                    to: 0
                }

            }

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: userList.popup.visible ? userList.delegateModel : null
                currentIndex: userList.highlightedIndex
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    active: true
                    policy: Controls.ScrollBar.AsNeeded
                    width: 12 * scaleFactor

                    contentItem: Rectangle {
                        implicitWidth: 8 * scaleFactor
                        radius: width / 2
                        color: parent.pressed ? root.colOnSurfaceVariant : Qt.rgba(root.colOnSurfaceVariant.r, root.colOnSurfaceVariant.g, root.colOnSurfaceVariant.b, 0.38)

                        Behavior on color {
                            CAnim {
                            }

                        }

                    }

                }

            }

            background: Rectangle {
                color: root.colSurface
                radius: root.radiusM
                layer.enabled: true

                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2 * scaleFactor
                    radius: 6 * scaleFactor
                    samples: 17
                    color: Qt.rgba(0, 0, 0, 0.15)
                    transparentBorder: true
                }

            }

        }

    }

    Controls.ComboBox {
        id: sessionList

        model: sessionModel
        textRole: "name"
        currentIndex: sessionModel.lastIndex
        implicitWidth: 200 * scaleFactor
        implicitHeight: 56 * scaleFactor

        anchors {
            bottom: powerControls.bottom
            right: powerControls.left
            rightMargin: powerControls.spacing + 2
        }

        delegate: Controls.ItemDelegate {
            width: sessionList.width
            height: 48 * scaleFactor
            text: model.name || ""
            highlighted: sessionList.highlightedIndex === index
            hoverEnabled: true

            contentItem: StyledText {
                text: parent.text
                color: parent.highlighted ? root.colPrimary : root.colOnSurfaceVariant
                font.pixelSize: root.fontSizeXLarge
                verticalAlignment: Text.AlignVCenter
                leftPadding: 12 * scaleFactor
                rightPadding: 12 * scaleFactor
                elide: Text.ElideRight
            }

            background: Rectangle {
                color: {
                    if (parent.down)
                        return Qt.rgba(root.colPrimary.r, root.colPrimary.g, root.colPrimary.b, 0.12);

                    if (parent.hovered)
                        return Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.08);

                    return "transparent";
                }

                Behavior on color {
                    CAnim {
                    }

                }

            }

        }

        indicator: MaterialSymbol {
            x: sessionList.width - width - (12 * scaleFactor)
            y: sessionList.topPadding + (sessionList.availableHeight - height) / 2
            text: "arrow_drop_down"
            font.pixelSize: 24 * scaleFactor
            color: root.colOnSurfaceVariant
            rotation: sessionList.popup.visible ? 180 : 0

            Behavior on rotation {
                Anim {
                }

            }

        }

        background: Rectangle {
            color: root.colSurfaceVariant
            radius: root.radiusM
            border.width: sessionList.visualFocus ? 2 * scaleFactor : 0
            border.color: root.colPrimary
            layer.enabled: sessionList.down || sessionList.hovered

            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 1 * scaleFactor
                radius: 2 * scaleFactor
                samples: 9
                color: Qt.rgba(0, 0, 0, 0.15)
                transparentBorder: true
            }

            Behavior on color {
                CAnim {
                }

            }

        }

        contentItem: StyledText {
            leftPadding: 12 * scaleFactor
            rightPadding: sessionList.indicator.width + (12 * scaleFactor)
            text: sessionList.displayText || ""
            font.pixelSize: root.fontSizeXLarge
            color: root.colOnSurfaceVariant
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        popup: Controls.Popup {
            y: sessionList.height + (4 * scaleFactor)
            width: sessionList.width
            implicitHeight: Math.min(contentItem.implicitHeight, 280 * scaleFactor)
            padding: 0
            topPadding: 8 * scaleFactor
            bottomPadding: 8 * scaleFactor

            enter: Transition {
                ParallelAnimation {
                    Anim {
                        property: "opacity"
                        from: 0
                        to: 1
                    }

                    Anim {
                        property: "scale"
                        from: 0.9
                        to: 1
                    }

                }

            }

            exit: Transition {
                Anim {
                    property: "opacity"
                    from: 1
                    to: 0
                }

            }

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: sessionList.popup.visible ? sessionList.delegateModel : null
                currentIndex: sessionList.highlightedIndex
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    active: true
                    policy: Controls.ScrollBar.AsNeeded
                    width: 12 * scaleFactor

                    contentItem: Rectangle {
                        implicitWidth: 8 * scaleFactor
                        radius: width / 2
                        color: parent.pressed ? root.colOnSurfaceVariant : Qt.rgba(root.colOnSurfaceVariant.r, root.colOnSurfaceVariant.g, root.colOnSurfaceVariant.b, 0.38)

                        Behavior on color {
                            CAnim {
                            }

                        }

                    }

                }

            }

            background: Rectangle {
                color: root.colSurface
                radius: root.radiusM
                layer.enabled: true

                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2 * scaleFactor
                    radius: 6 * scaleFactor
                    samples: 17
                    color: Qt.rgba(0, 0, 0, 0.15)
                    transparentBorder: true
                }

            }

        }

    }

    Rectangle {
        id: bottomCard

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(640 * scaleFactor, parent.width * 0.9)
        height: 75 * scaleFactor
        radius: root.radiusL
        color: root.colSurface
        layer.enabled: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12 * scaleFactor
            anchors.leftMargin: 14 * scaleFactor
            anchors.rightMargin: 14 * scaleFactor
            spacing: 10 * scaleFactor

            Item {
                id: avatarContainer

                // FIXED: Get username from lastUser and update on user change
                property string userName: userModel.lastUser

                Layout.preferredWidth: parent.height
                Layout.preferredHeight: parent.height

                // Update userName when user changes
                Connections {
                    function onCurrentIndexChanged() {
                        if (userList.currentIndex >= 0 && userList.currentIndex < userModel.count)
                            avatarContainer.userName = userModel.data(userModel.index(userList.currentIndex, 0), Qt.DisplayRole);

                    }

                    target: userList
                }

                Rectangle {
                    id: avatarBackground

                    anchors.fill: parent
                    radius: width / 2
                    color: root.colSurfaceVariant

                    Image {
                        id: avatar

                        anchors.fill: parent
                        source: {
                            var username = avatarContainer.userName;
                            if (!username)
                                return "";

                            // Try AccountsService path first
                            return "file:///var/lib/AccountsService/icons/" + username;
                        }
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready
                        layer.enabled: true
                        // Fallback to .face.icon
                        onStatusChanged: {
                            if (status === Image.Error) {
                                var username = avatarContainer.userName;
                                if (username) {
                                    var home = "/home/" + username;
                                    source = "file://" + home + "/.face.icon";
                                }
                            }
                        }

                        layer.effect: OpacityMask {

                            maskSource: Rectangle {
                                width: avatar.width
                                height: avatar.height
                                radius: width / 2
                            }

                        }

                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "person"
                        font.pixelSize: parent.width * 0.5
                        color: root.colOnSurfaceVariant
                        visible: avatar.status !== Image.Ready && avatar.status !== Image.Loading
                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: root.colSurfaceVariant
                radius: root.radiusM

                TextInput {
                    id: passwordBox

                    anchors.fill: parent
                    anchors.margins: 15 * scaleFactor
                    verticalAlignment: Text.AlignVCenter
                    echoMode: TextInput.Password
                    color: root.colOnSurface
                    font.pixelSize: root.fontSizeLarge
                    font.family: "Rubik"
                    renderType: Text.QtRendering
                    font.hintingPreference: Font.PreferFullHinting
                    focus: true
                    onAccepted: sddm.login(avatarContainer.userName, text, sessionList.currentIndex)
                }

                StyledText {
                    anchors.fill: parent
                    anchors.margins: 15 * scaleFactor
                    verticalAlignment: Text.AlignVCenter
                    text: "Password..."
                    color: Qt.rgba(root.colOnSurfaceVariant.r, root.colOnSurfaceVariant.g, root.colOnSurfaceVariant.b, 0.5)
                    font.pixelSize: root.fontSizeXLarge
                    visible: !passwordBox.text && !passwordBox.activeFocus
                }

            }

            Controls.Button {
                Layout.preferredWidth: height
                Layout.fillHeight: true
                onClicked: sddm.login(avatarContainer.userName, passwordBox.text, sessionList.currentIndex)

                background: Rectangle {
                    color: parent.down ? Qt.darker(root.colPrimary, 1.2) : root.colPrimary
                    radius: root.radiusM
                }

                contentItem: MaterialSymbol {
                    text: "send"
                    font.pixelSize: 26 * scaleFactor
                    color: root.colOnPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

            }

        }

        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4 * scaleFactor
            radius: 8 * scaleFactor
            samples: 17
            color: Qt.rgba(0, 0, 0, 0.25)
            transparentBorder: true
            spread: 0.1
        }

        Anim on anchors.bottomMargin {
            from: -30 * scaleFactor - height
            to: 30 * scaleFactor
        }

    }

    ColumnLayout {
        id: powerControls

        spacing: 8 * scaleFactor
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14 * scaleFactor

        PowerButton {
            materialIcon: "dark_mode"
            onClicked: sddm.suspend()
        }

        PowerButton {
            materialIcon: "restart_alt"
            onClicked: sddm.reboot()
        }

        PowerButton {
            materialIcon: "power_settings_new"
            onClicked: sddm.powerOff()
        }

    }

    Rectangle {
        width: errorMessage.implicitWidth + 40 * scaleFactor
        height: 50 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomCard.top
        anchors.bottomMargin: 20 * scaleFactor
        radius: root.radiusL
        color: root.colError
        visible: errorMessage.text !== ""

        StyledText {
            id: errorMessage

            anchors.centerIn: parent
            color: "#1e1418"
            font.pixelSize: root.fontSizeSmall
            font.bold: true
        }

    }

    Connections {
        function onLoginFailed() {
            passwordBox.text = "";
            errorMessage.text = "Authentication failed";
        }

        target: sddm
    }

    component PowerButton: Controls.Button {
        id: powerBtn

        property string materialIcon

        Layout.preferredHeight: 64
        Layout.preferredWidth: height

        MaterialSymbol {
            text: powerBtn.materialIcon
            font.pixelSize: root.fontSizeHuge
            color: parent.hovered ? root.colOnPrimary : root.colOnSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.centerIn: parent

            Behavior on color {
                CAnim {
                }

            }

        }

        background: Rectangle {
            color: parent.hovered ? root.colPrimary : root.colSurfaceVariant
            radius: root.radiusCircle

            Behavior on color {
                CAnim {
                }

            }

        }

    }

    component StyledText: Text {
        font.family: "Rubik"
        font.pixelSize: root.fontSizeMedium
        color: root.colOnSurfaceVariant
        renderType: Text.QtRendering
        antialiasing: true
        font.hintingPreference: Font.PreferFullHinting
        smooth: true
    }

    component MaterialSymbol: Text {
        font.family: "Material Symbols Rounded"
        font.pixelSize: root.fontSizeMedium
    }

    component CAnim: ColorAnimation {
        duration: 450
        easing.bezierCurve: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
    }

    component Anim: NumberAnimation {
        duration: 350
        easing.bezierCurve: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
    }

}
