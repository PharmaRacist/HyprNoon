import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    // Meta
    property string icon: "dock"
    property string name: ""
    property string key: ""
    property string hint: ""
    property string type: "button" // button | switch | spin | slider | combobox | text | action
    property string actionName: ""
    property bool reloadOnChange: false
    property bool enabled: true
    property bool subOption: false
    property bool useStates: false
    property bool enableTooltip: true
    property bool hideTitle: type === "field"
    property string condition: ""
    property string dependsOn: ""
    property string id: ""
    // Values
    property int customItemHeight: 0
    property int itemValue: 0
    property int minValue: 0
    property int maxValue: 100
    property int intValue: itemValue
    property real sliderMinValue: 0
    property real sliderMaxValue: 1
    property real sliderValue: 0.5
    property int sliderDecimals: 2
    property string sliderSuffix: ""
    property real realValue: sliderValue
    property var comboBoxValues: []
    property int comboBoxCurrentIndex: 0
    property string comboBoxCurrentValue: comboBoxValues.length > 0 ? comboBoxValues[0] : ""
    property bool toggledState: false
    property bool fillHeight: false
    property string textValue: ""
    property string textPlaceholder: "Enter text..."
    // Colors
    property color backgroundColor: Colors.colLayer2
    property color backgroundHoverColor: Colors.colLayer1Hover
    property color backgroundDisabledColor: Qt.rgba(Colors.colLayer1.r, Colors.colLayer1.g, Colors.colLayer1.b, 0.5)
    property color backgroundPressedColor: Qt.darker(Colors.colLayer1, 1.2)
    property color iconBackgroundColor: Colors.colLayer3
    property color iconBackgroundActiveColor: Colors.m3.m3primaryContainer
    property color iconColor: Colors.colOnLayer2
    property color iconActiveColor: Colors.m3.m3onPrimaryContainer
    property color textColor: Colors.colOnLayer0
    property color textDisabledColor: Qt.rgba(Colors.colOnLayer0.r, Colors.colOnLayer0.g, Colors.colOnLayer0.b, 0.5)
    property color spinBoxBackgroundColor: Colors.colLayer2
    property color spinBoxTextColor: Colors.colOnLayer2
    property color spinBoxButtonColor: Colors.colLayer2
    property color spinBoxButtonHoverColor: Colors.colLayer2Hover
    property color spinBoxButtonActiveColor: Colors.colLayer2Active
    property color sliderHighlightColor: Colors.colPrimary
    property color sliderTrackColor: Colors.colSecondaryContainer
    property color sliderHandleColor: Colors.m3.m3onSecondaryContainer
    property color switchActiveColor: Colors.colPrimary
    property color switchInactiveColor: Colors.colSurfaceContainerHighest
    property color switchActiveBorderColor: Colors.colPrimary
    property color switchInactiveBorderColor: Colors.m3.m3outline
    property color switchButtonActiveColor: Colors.m3.m3onPrimary
    property color switchButtonColor: Colors.m3.m3outline
    property color switchIconActiveColor: Colors.m3.m3primary
    property color switchIconColor: "transparent"
    property color comboBoxBackgroundColor: Colors.colLayer2
    property color comboBoxTextColor: Colors.colOnLayer2
    property color comboBoxBorderColor: Colors.colOutline
    property color comboBoxHoverColor: Colors.colLayer2Hover
    property color comboBoxArrowColor: Colors.colOnLayer2
    property bool _ready: false
    property var _pendingValue: null
    property string _pendingType: ""

    signal valueChanged(var newValue)
    signal clicked()

    function debouncedSetValue(value, valueType) {
        _pendingValue = value;
        _pendingType = valueType;
        debounceTimer.restart();
    }

    function getConfigValue() {
        if (key === "" || !Mem)
            return undefined;

        // Use ternary to select root object
        let root = useStates ? Mem.states : Mem.options;
        if (!root)
            return undefined;

        let keys = key.split('.');
        let current = root;
        for (let i = 0; i < keys.length; i++) {
            if (current === undefined || current === null)
                return undefined;

            current = current[keys[i]];
        }
        return current;
    }

    function setConfigValue(value) {
        if (key === "" || !Mem || !_ready)
            return ;

        // Use ternary to select root object
        let root = useStates ? Mem.states : Mem.options;
        if (!root)
            return ;

        let keys = key.split('.');
        let current = root;
        for (let i = 0; i < keys.length - 1; i++) {
            if (!current[keys[i]])
                current[keys[i]] = {
            };

            current = current[keys[i]];
        }
        current[keys[keys.length - 1]] = value;
    }

    onValueChanged: function(newValue) {
        if (reloadOnChange && _ready)
            Qt.callLater(() => {
            return Quickshell.reload(true);
        });

    }
    Component.onCompleted: {
        _ready = false; // Ensure it's false first
        let val = getConfigValue();
        if (val !== undefined && val !== null) {
            if (type === "spin") {
                intValue = Math.max(minValue, Math.min(maxValue, parseInt(val) || minValue));
            } else if (type === "slider") {
                // FIX: Set realValue without triggering the change handler
                realValue = Math.max(sliderMinValue, Math.min(sliderMaxValue, parseFloat(val) || sliderMinValue));
            } else if (type === "combobox") {
                let idx = comboBoxValues.indexOf(val);
                if (idx >= 0) {
                    comboBoxCurrentIndex = idx;
                    comboBoxCurrentValue = val;
                }
            } else if (type === "text" || type === "field") {
                textValue = String(val);
            } else {
                toggledState = Boolean(val);
            }
        }
        // Enable change tracking only AFTER initial values are loaded
        Qt.callLater(() => {
            return _ready = true;
        });
    }
    Layout.fillHeight: fillHeight
    Layout.preferredHeight: (root.fillHeight && mainLoader.item) ? mainLoader.item.implicitHeight + 2 * Padding.normal : 65
    Layout.fillWidth: true
    color: {
        if (!enabled)
            return backgroundDisabledColor;

        if (mouseArea.pressed)
            return backgroundPressedColor;

        if (mouseArea.containsMouse)
            return backgroundHoverColor;

        return backgroundColor;
    }
    radius: 12
    opacity: enabled ? 1 : 0.6

    Timer {
        id: debounceTimer

        interval: 100
        repeat: false
        onTriggered: {
            if (_pendingValue !== null) {
                root.setConfigValue(_pendingValue);
                root.valueChanged(_pendingValue);
                _pendingValue = null;
                _pendingType = "";
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled && (type === "button")
        onClicked: {
            if (type === "button") {
                toggledState = !toggledState;
                debounceTimer.stop();
                setConfigValue(toggledState);
                root.valueChanged(toggledState);
                root.clicked();
            }
        }
        onPressed: feedbackAnimation.start()
    }

    SequentialAnimation {
        id: feedbackAnimation

        ScaleAnimator {
            target: root
            from: 1
            to: 0.98
            duration: 50
        }

        ScaleAnimator {
            target: root
            from: 0.98
            to: 1
            duration: 100
        }

    }

    Loader {
        active: root.enableTooltip

        sourceComponent: StyledToolTip {
            extraVisibleCondition: hint !== "" && mouseArea.containsMouse
            content: hint
        }

    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Rectangle {
            readonly property bool isActive: {
                switch (type) {
                case "button":
                case "switch":
                    return toggledState;
                case "slider":
                    return realValue > sliderMinValue;
                case "spin":
                    return intValue > minValue;
                case "combobox":
                    return comboBoxCurrentIndex > 0;
                case "text":
                case "field":
                    return textValue !== "";
                default:
                    return false;
                }
            }

            visible: !root.hideTitle
            Layout.preferredHeight: 40
            Layout.preferredWidth: 40
            radius: 10
            color: isActive ? iconBackgroundActiveColor : iconBackgroundColor

            MaterialSymbol {
                id: iconSymbol

                fill: 1
                font.pixelSize: icon === "" ? 14 : 22
                text: icon
                font.family: Fonts.family.iconMaterial
                color: parent.isActive ? iconActiveColor : iconColor
                anchors.centerIn: parent

                SequentialAnimation {
                    id: iconAnimation

                    running: false

                    RotationAnimator {
                        target: iconSymbol
                        from: 0
                        to: 360
                        duration: 250
                        easing.type: Easing.OutQuad
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }

                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }

            }

        }

        StyledText {
            visible: !root.hideTitle
            text: name
            color: enabled ? textColor : textDisabledColor
            font.pixelSize: Fonts.sizes.normal
        }

        Item {
            visible: !root.hideTitle
            Layout.fillWidth: true
        }

        Loader {
            id: mainLoader

            sourceComponent: {
                switch (type) {
                case "spin":
                    return spinComponent;
                case "slider":
                    return sliderComponent;
                case "combobox":
                    return comboboxComponent;
                case "field":
                    return plainFieldComponent;
                case "text":
                    return textFieldComponent;
                case "action":
                    return actionComponent;
                case "switch":
                    return switchComponent;
                case "button":
                default:
                    return switchComponent;
                }
            }
            Layout.minimumWidth: root.hideTitle ? parent.width : type === "slider" ? 120 : type === "combobox" ? 165 : type === "text" ? 165 : item ? item.width : 40
            Layout.preferredWidth: root.type === "field" ? parent.width : Layout.minimumWidth
            Layout.fillHeight: root.fillHeight
        }

        Component {
            id: spinComponent

            StyledSpinBox {
                value: root.intValue
                from: root.minValue
                to: root.maxValue
                enabled: root.enabled
                backgroundColor: root.spinBoxBackgroundColor
                textColor: root.spinBoxTextColor
                buttonColor: root.spinBoxButtonColor
                buttonHoverColor: root.spinBoxButtonHoverColor
                buttonActiveColor: root.spinBoxButtonActiveColor
                onValueChanged: {
                    if (value !== root.intValue) {
                        root.intValue = value;
                        root.debouncedSetValue(value, "spin");
                    }
                }
            }

        }

        Component {
            id: sliderComponent

            StyledSlider {
                Layout.minimumWidth: 140
                Layout.fillWidth: true
                from: root.sliderMinValue
                to: root.sliderMaxValue
                value: root.realValue
                enabled: root.enabled
                highlightColor: root.sliderHighlightColor
                trackColor: root.sliderTrackColor
                handleColor: root.sliderHandleColor
                enableTooltip: root.enableTooltip
                onMoved: {
                    if (root._ready) {
                        root.realValue = value;
                        root.debouncedSetValue(value, "slider");
                    }
                }
            }

        }

        Component {
            id: comboboxComponent

            StyledComboBox {
                Layout.minimumWidth: 140
                implicitHeight: 40
                enabled: root.enabled
                model: root.comboBoxValues
                currentIndex: root.comboBoxCurrentIndex
                onActivated: function(index) {
                    if (index >= 0 && index < root.comboBoxValues.length && index !== root.comboBoxCurrentIndex) {
                        root.comboBoxCurrentIndex = index;
                        root.comboBoxCurrentValue = root.comboBoxValues[index];
                        debounceTimer.stop();
                        root.setConfigValue(root.comboBoxCurrentValue);
                        root.valueChanged(root.comboBoxCurrentValue);
                        iconAnimation.start();
                    }
                }
            }

        }

        Component {
            id: plainFieldComponent

            MaterialTextField {
                enabled: root.enabled
                text: root.textValue
                font.pixelSize: Fonts.sizes.verylarge
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter
                placeholderText: root.textPlaceholder
                onTextChanged: {
                    if (text !== root.textValue) {
                        root.textValue = text;
                        root.debouncedSetValue(text, "text");
                    }
                }
                onAccepted: {
                    debounceTimer.stop();
                    if (_pendingValue !== null) {
                        root.setConfigValue(_pendingValue);
                        root.valueChanged(_pendingValue);
                        _pendingValue = null;
                    }
                    iconAnimation.start();
                }
                Keys.onEscapePressed: focus = false
            }

        }

        Component {
            id: textFieldComponent

            MaterialTextField {
                Layout.minimumWidth: 160
                Layout.preferredHeight: 40
                implicitHeight: 40
                enabled: root.enabled
                text: root.textValue
                placeholderText: {
                    let val = root.getConfigValue();
                    return (val !== undefined && val !== null) ? String(val) : root.textPlaceholder;
                }
                horizontalAlignment: Text.AlignHCenter
                onTextChanged: {
                    if (text !== root.textValue) {
                        root.textValue = text;
                        root.debouncedSetValue(text, "text");
                    }
                }
                onAccepted: {
                    debounceTimer.stop();
                    if (_pendingValue !== null) {
                        root.setConfigValue(_pendingValue);
                        root.valueChanged(_pendingValue);
                        _pendingValue = null;
                    }
                    iconAnimation.start();
                }
            }

        }

        Component {
            id: actionComponent

            RippleButton {
                width: 45
                height: width
                colBackground: Colors.colLayer3
                releaseAction: function() {
                    let cmd = Directories.scriptsDir + "/" + root.actionName;
                    Noon.execDetached(cmd);
                    Noon.callIpc("sidebar hide");
                }

                MaterialSymbol {
                    font.pixelSize: 24
                    fill: 1
                    anchors.centerIn: parent
                    text: "play_arrow"
                    color: Colors.colOnLayer1
                }

            }

        }

        Component {
            id: switchComponent

            StyledSwitch {
                Layout.alignment: Qt.AlignRight
                checked: root.toggledState
                scale: 0.85
                enabled: root.enabled
                activeColor: root.switchActiveColor
                inactiveColor: root.switchInactiveColor
                activeBorderColor: root.switchActiveBorderColor
                inactiveBorderColor: root.switchInactiveBorderColor
                buttonActiveColor: root.switchButtonActiveColor
                buttonColor: root.switchButtonColor
                iconActiveColor: root.switchIconActiveColor
                iconColor: root.switchIconColor
                onCheckedChanged: {
                    if (checked !== root.toggledState) {
                        root.toggledState = checked;
                        debounceTimer.stop();
                        root.setConfigValue(checked);
                        root.valueChanged(checked);
                        iconAnimation.start();
                    }
                }
            }

        }

    }

    Behavior on color {
        CAnim {
        }

    }

    Behavior on opacity {
        Anim {
        }

    }

}
