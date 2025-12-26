import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    id: root

    showButtonName: false
    hasDialog: true
    onRequestDialog: GlobalStates.showRecordingDialog = true
    buttonName: RecordingService.isRecording ? `${qsTr("Recording")} ${RecordingService.getFormattedDuration()}` : qsTr("Record")
    toggled: RecordingService.isRecording
    buttonIcon: RecordingService.isRecording ? "radio_button_checked" : "radio_button_unchecked"
    onClicked: RecordingService.toggleRecording()
    holdAction: () => {
        if (RecordingService.isRecording)
            RecordingService.stopRecording();
        else
            Noon.exec("xdg-open ~/Videos");
    }

    StyledToolTip {
        extraVisibleCondition: RecordingService.isRecording
        content: StringUtils.format(qsTr("Recording {0} | Right-click to stop"), RecordingService.getFormattedDuration())
    }

}
