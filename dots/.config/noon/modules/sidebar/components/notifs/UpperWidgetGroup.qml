import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import "quickToggles"
import "sliders"

Item {
    id: root

    property var panelWindow

    implicitHeight: contentLayout.implicitHeight + Padding.large

    ColumnLayout {
        id: contentLayout

        spacing: Padding.normal

        anchors {
            fill: parent
            bottomMargin: Padding.large
            topMargin: Padding.normal
        }

        UptimeRow {
        }

        ColumnLayout {
            visible: Mem.options.sidebar.appearance.showSliders ?? false
            spacing: Padding.small
            Layout.fillWidth: true
            Layout.rightMargin: Padding.normal

            BrightnessSlider {
            }

            VolumeOutputSlider {
            }

            VolumeInputSlider {
            }

        }

        Grid {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Padding.normal
            columnSpacing: Padding.normal

            NetworkToggle {
            }

            BluetoothToggle {
            }

            NightLightToggle {
            }

            AppearanceToggle {
            }

            KdeConnectToggle {
            }

            TransparencyToggle {
            }

        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter

            CaffieneToggle {
            }

            EasyEffectsToggle {
            }

            RecordToggle {
            }

            GameModeToggle {
            }

            InputToggle {
            }

            BacklightToggle {
            }

        }

    }

    component UptimeRow: StyledText {
        font.pixelSize: Fonts.sizes.verylarge
        color: Colors.colOnLayer0
        text: StringUtils.format(qsTr("Awake for {0}"), DateTimeService.uptime)
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignLeft
    }

}
