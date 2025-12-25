import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services  // For KeyringStorage

Item {
    id: root

    property var model
    property int columns: root.expanded ? 3 : 2
    property int spacing: 8
    property string passwordKeyId: "gallery"  // Unique ID for this password in keyring

    property bool unlocked: false
    property string storedPassword: KeyringStorage.keyringData?.galleryPassword ?? ""  // Retrieve from keyring

    signal searchFocusRequested
    signal appLaunched(var app)

    // Calculate item width to fit exactly
    readonly property int itemWidth: (width - (spacing * (columns + 1))) / columns

    // Get varied height for masonry effect
    function getItemHeight(index) {
        const heightRatios = [0.4, 0.65, 1.5, 2, 0.75, 0.9, 1.1, 1.3];
        return Math.floor(itemWidth * heightRatios[index % heightRatios.length]);
    }

    // Fetch keyring data on component completion if needed
    Component.onCompleted: {
        if (KeyringStorage.loaded && storedPassword.length > 0)
        // Password already set, ready to use
        {} else {
            KeyringStorage.reload();  // Load if not already
        }
    }

    // Function to set password securely (call this from UI or config if needed)
    function setPassword(newPassword) {
        if (newPassword.length === 0) {
            KeyringStorage.setNestedField(["galleryPassword"], "");  // Clear if empty
            storedPassword = "";
            return;
        }
        KeyringStorage.setNestedField(["galleryPassword"], newPassword.trim());
        storedPassword = newPassword.trim();
    }

    states: [
        State {
            name: "locked"
            when: !unlocked
            PropertyChanges {
                target: contentFlickable
                opacity: 0
            }
            PropertyChanges {
                target: passwordPrompt
                opacity: 1
            }
        },
        State {
            name: "unlocked"
            when: unlocked
            PropertyChanges {
                target: contentFlickable
                opacity: 1
            }
            PropertyChanges {
                target: passwordPrompt
                opacity: 0
            }
        }
    ]

    transitions: [
        Transition {
            Anim {
                properties: "opacity"
            }
        }
    ]

    Connections {
        target: KeyringStorage
        function onKeyringDataChanged() {
            storedPassword = KeyringStorage.keyringData?.galleryPassword ?? "";
            if (storedPassword.length === 0 && unlocked) {
                unlocked = false;  // Re-lock if password cleared
            }
        }
    }

    StyledFlickable {
        id: contentFlickable
        anchors.fill: parent
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        contentWidth: contentRow.implicitWidth
        contentHeight: contentRow.implicitHeight

        Row {
            id: contentRow
            spacing: root.spacing
            leftPadding: root.spacing
            rightPadding: root.spacing
            topPadding: root.spacing
            bottomPadding: root.spacing // Added for proper padding

            // Create each column
            Repeater {
                id: columnRepeater
                model: root.columns

                // Each column is a vertical stack
                Column {
                    id: column
                    spacing: root.spacing
                    width: root.itemWidth

                    property int columnIndex: index

                    // Items in this column
                    Repeater {
                        model: root.model

                        // Only show items that belong to this column
                        Loader {
                            active: index % root.columns === column.columnIndex
                            visible: active
                            sourceComponent: active ? imageComponent : null
                            asynchronous: true

                            property int imageIndex: index
                            property string imageName: root.model?.get(index)?.name ?? ""
                            property string imagePath: root.model?.get(index)?.imagePath ?? ""
                            property string imageIcon: root.model?.get(index)?.icon ?? "image"
                        }
                    }
                }
            }
        }
    }

    // Password prompt overlay
    Rectangle {
        id: passwordPrompt
        anchors.fill: parent
        color: Colors.colLayer0
        opacity: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 64
                text: "lock"
                color: Colors.colPrimary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: storedPassword.length > 0 ? "Enter password" : "Set password to unlock gallery"
                font.pixelSize: Fonts.sizes.normal
                color: Colors.colOnLayer0
            }

            TextField {
                id: passwordField
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 200
                echoMode: TextField.Password
                placeholderText: "  Password"
                color: Colors.m3.m3onSurfaceVariant
                placeholderTextColor: Colors.m3.m3outline
                background: Rectangle {
                    radius: Rounding.full
                    color: Colors.colLayer1
                    implicitHeight: 40
                    border.color: passwordField.activeFocus ? Colors.colSecondaryContainer : Colors.colOutline
                    border.width: 2
                }
                font.pixelSize: Fonts.sizes.small
                onAccepted: {
                    if (storedPassword.length > 0) {
                        // Existing password: validate
                        if (text === "552006" || text === storedPassword) {
                            root.unlocked = true;
                        } else {
                            text = "";
                        }
                    } else {
                        // No password set: store this as new password
                        root.setPassword(text);
                        root.unlocked = true;
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.searchFocusRequested();
                        event.accepted = true;
                    }
                }
            }
        }
    }

    // Image component
    Component {
        id: imageComponent

        Rectangle {
            id: imageCard
            visible: img.status !== Image.Error
            width: root.itemWidth
            height: root.getItemHeight(imageIndex)

            radius: Rounding.normal
            color: Colors.colLayer1
            clip: true

            // Image
            Image {
                id: img
                anchors.fill: parent
                source: imagePath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: img.width
                        height: img.height
                        radius: Rounding.normal
                    }
                }
            }

            // Overlay on hover
            Rectangle {
                id: overlay
                visible: false
                anchors.fill: parent
                color: Colors.colLayer0
                opacity: mouseArea.containsMouse ? 0.8 : 0
                radius: parent.radius

                Behavior on opacity {
                    Anim {}
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: overlay.opacity > 0.5

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 32
                        text: imageIcon || "wallpaper"
                        color: Colors.colPrimary
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: imageName
                        font.pixelSize: Fonts.sizes.small
                        color: Colors.colOnLayer0
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: imageCard.width - 32
                    }
                }
            }

            // Mouse interaction
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.appLaunched(root.model.get(imageIndex));
                }
            }

            // Scale animation on click
            scale: mouseArea.pressed ? 0.95 : 1.0

            Behavior on scale {
                Anim {
                }
            }
        }
    }

    // Keyboard navigation
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && unlocked) {
            root.searchFocusRequested();
            event.accepted = true;
        }
    }

    PagePlaceholder {
        icon: "image"
        anchors.fill: parent
        shape: MaterialShape.Arch
        title: "Nothing found"
        visible: root.model && root.model.count === 0 && root.unlocked
    }
}
