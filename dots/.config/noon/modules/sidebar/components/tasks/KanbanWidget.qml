import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property bool quarters: false
    property bool showAddDialog: false
    property bool showAddButton: true
    property int editIndex: -1
    property int fabSize: 48
    property int fabMargins: 14
    property bool requestDockShow: false
    property bool showHeader: false
    property int dialogMargins: 20
    // Column configuration model
    readonly property var columnConfigs: [{
        "show": true,
        "status": TodoService.status_todo,
        "shape": MaterialShape.Cookie4Sided,
        "icon": "timer",
        "title": qsTr("Todo tasks"),
        "model": todoTasksModel
    }, {
        "show": root.quarters,
        "status": TodoService.status_in_progress,
        "shape": MaterialShape.Ghostish,
        "icon": "hourglass_empty",
        "title": qsTr("In progress tasks"),
        "model": inProgressTasksModel
    }, {
        "show": root.quarters,
        "status": TodoService.status_final_touches,
        "shape": MaterialShape.Slanted,
        "icon": "build",
        "title": qsTr("Final touches"),
        "model": finalTouchesTasksModel
    }, {
        "show": true,
        "status": TodoService.status_done,
        "shape": MaterialShape.Cookie7Sided,
        "icon": "check_circle",
        "title": qsTr("Completed tasks"),
        "model": doneTasksModel
    }]
    // Backward compatibility aliases
    readonly property var todoColumn: getColumnByStatus(TodoService.status_todo)
    readonly property var inProgressColumn: getColumnByStatus(TodoService.status_in_progress)
    readonly property var finalTouchesColumn: getColumnByStatus(TodoService.status_final_touches)
    readonly property var doneColumn: getColumnByStatus(TodoService.status_done)

    signal requestReveal()

    function updateTaskModels() {
        todoTasksModel.clear();
        inProgressTasksModel.clear();
        finalTouchesTasksModel.clear();
        doneTasksModel.clear();
        for (var i = 0; i < TodoService.list.length; i++) {
            var item = TodoService.list[i];
            var modelItem = {
                "originalIndex": i,
                "content": item.content,
                "status": item.status,
                "todoistId": item.todoistId || ""
            };
            switch (item.status) {
            case TodoService.status_todo:
                todoTasksModel.append(modelItem);
                break;
            case TodoService.status_in_progress:
                inProgressTasksModel.append(modelItem);
                break;
            case TodoService.status_final_touches:
                finalTouchesTasksModel.append(modelItem);
                break;
            case TodoService.status_done:
                doneTasksModel.append(modelItem);
                break;
            }
        }
    }

    function syncModelsToTodo() {
        var newList = [];
        const appendModel = (m) => {
            for (var i = 0; i < m.count; i++) {
                var it = m.get(i);
                newList.push({
                    "content": it.content,
                    "status": it.status,
                    "todoistId": it.todoistId
                });
            }
        };
        appendModel(todoTasksModel);
        appendModel(inProgressTasksModel);
        appendModel(finalTouchesTasksModel);
        appendModel(doneTasksModel);
        TodoService.list = newList;
        updateTaskModels();
    }

    function getStatusNum(status) {
        if (status === TodoService.status_todo)
            return 0;

        if (status === TodoService.status_in_progress)
            return 1;

        if (status === TodoService.status_final_touches)
            return 2;

        if (status === TodoService.status_done)
            return 3;

        return -1;
    }

    function changeStatus(index, currentStatus, targetStatus) {
        var currentNum = getStatusNum(currentStatus);
        var targetNum = getStatusNum(targetStatus);
        var diff = targetNum - currentNum;
        var func = diff > 0 ? TodoService.nextStatus : TodoService.previousStatus;
        diff = Math.abs(diff);
        for (var i = 0; i < diff; i++) {
            func(index);
        }
    }

    function isOver(item, x, y) {
        var p = item.mapFromItem(overlay, x, y);
        return p.x >= 0 && p.x < item.width && p.y >= 0 && p.y < item.height;
    }

    function getColorForStatus(status) {
        switch (status) {
        case TodoService.status_todo:
            return Colors.colLayer2;
        case TodoService.status_in_progress:
            return Colors.colPrimaryContainer;
        case TodoService.status_final_touches:
            return Colors.colSecondaryContainer;
        case TodoService.status_done:
            return Colors.colSurfaceContainerHigh;
        default:
            return Colors.colLayer2;
        }
    }

    // Helper functions to access columns by status
    function getColumnByStatus(status) {
        for (var i = 0; i < columnRepeater.count; i++) {
            var item = columnRepeater.itemAt(i);
            if (item && item.targetStatus === status)
                return item;

        }
        return null;
    }

    Component.onCompleted: {
        commandBar.forceActiveFocus();
        updateTaskModels();
    }

    ListModel {
        id: todoTasksModel
    }

    ListModel {
        id: inProgressTasksModel
    }

    ListModel {
        id: finalTouchesTasksModel
    }

    ListModel {
        id: doneTasksModel
    }

    Item {
        id: overlay

        anchors.fill: parent
        z: 100
    }

    QuickSettingsSplitButton {
        id: commandBar

        property bool timerMode: false
        property bool editMode: false

        implicitHeight: 45
        showThird: false
        placeholderText: {
            if (editMode)
                return "Edit task name";

            return timerMode ? "how long ?" : "Add..?";
        }
        firstIcon: {
            if (editMode)
                return "check";

            return timerMode ? "timer" : "add";
        }
        secondIcon: editMode ? "close" : "timer"
        thirdIcon: {
            switch (TodoService.syncState) {
            case TodoService.SyncState.Offline:
                return "cloud_off";
            case TodoService.SyncState.Idle:
                return "sync";
            case TodoService.SyncState.Syncing:
                return "sync";
            case TodoService.SyncState.Error:
                return "error";
            default:
                return "sync";
            }
        }
        buttonExpanded: {
            if (editMode)
                return 200;

            return timerMode ? 130 : 200;
        }
        thirdAction: () => {
            if (editMode)
                return ;

            thirdBgColor = Colors.m3.m3success;
            successTimer.running = true;
            return TodoService.syncWithTodoist();
        }
        secondAction: () => {
            if (editMode) {
                editMode = false;
                root.editIndex = -1;
                commandBar.searchToggled = false;
                timerMode = false;
                return ;
            }
            timerMode = !timerMode;
            commandBar.searchToggled = !commandBar.searchToggled;
        }
        secondPressHoldAction: () => {
            if (editMode)
                return ;

            root.requestReveal();
        }
        firstAction: () => {
            if (editMode)
                // This triggers when clicking the check icon in edit mode
                // The searchAction will handle the actual save
                return ;

        }
        searchAction: (text) => {
            if (editMode) {
                // Save edit
                if (text.length > 0 && root.editIndex >= 0) {
                    TodoService.editItem(root.editIndex, text);
                    updateTaskModels();
                }
                editMode = false;
                root.editIndex = -1;
                timerMode = false;
                text = "";
                return ;
            }
            if (!timerMode) {
                TodoService.addTask(text);
                updateTaskModels();
                text = "";
                return ;
            }
            const duration = TimerService.parseTimeString(text);
            if (duration > 0) {
                const id = TimerService.addTimer("Focus Time", duration);
                TimerService.startTimer(id);
                text = "";
            } else {
                text = "";
            }
        }

        Connections {
            function onEditIndexChanged() {
                if (root.editIndex >= 0 && root.editIndex < TodoService.list.length) {
                    // Enter edit mode
                    commandBar.timerMode = false;
                    commandBar.editMode = true;
                    // Get the current task content
                    var taskContent = TodoService.list[root.editIndex].content;
                    // Open the search field first
                    commandBar.searchToggled = true;
                    // Try multiple approaches to set the text value
                    Qt.callLater(function() {
                        // Try different property names
                        if (commandBar.hasOwnProperty('searchText'))
                            commandBar.searchText = taskContent;
                        else if (commandBar.hasOwnProperty('text'))
                            commandBar.text = taskContent;
                        else if (commandBar.hasOwnProperty('inputText'))
                            commandBar.inputText = taskContent;
                        else if (commandBar.hasOwnProperty('value'))
                            commandBar.value = taskContent;
                        // Try to find and set the text field directly
                        var textField = commandBar.findChild("textField");
                        if (!textField)
                            textField = commandBar.findChild("searchField");

                        if (!textField)
                            textField = commandBar.findChild("input");

                        if (textField && textField.hasOwnProperty('text')) {
                            textField.text = taskContent;
                            textField.forceActiveFocus();
                            textField.selectAll();
                        }
                    });
                } else if (root.editIndex === -1) {
                    commandBar.editMode = false;
                }
            }

            target: root
        }

        Timer {
            id: successTimer

            interval: 500
            onTriggered: commandBar.thirdBgColor = commandBar.defaultColors
        }

        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 30
        }

    }

    GridLayout {
        // columns: width > Screen.width / 2.5 ? 4 : 1
        // rows: columns === 4 ? 1 : 4

        id: taskGrid

        anchors.fill: parent
        columnSpacing: 10
        rowSpacing: 10
        columns: quarters ? 2 : 1
        rows: quarters ? 2 : 2

        Repeater {
            id: columnRepeater

            model: root.columnConfigs

            TaskList {
                required property var modelData
                required property int index

                visible: modelData.show ?? true
                // Assign IDs based on status for backward compatibility
                objectName: {
                    switch (modelData.status) {
                    case TodoService.status_todo:
                        return "todoColumn";
                    case TodoService.status_in_progress:
                        return "inProgressColumn";
                    case TodoService.status_final_touches:
                        return "finalTouchesColumn";
                    case TodoService.status_done:
                        return "doneColumn";
                    default:
                        return "";
                    }
                }
                shape: modelData.shape
                Layout.fillWidth: true
                Layout.fillHeight: true
                listBottomPadding: root.fabSize + root.fabMargins * 2
                emptyPlaceholderIcon: modelData.icon
                emptyPlaceholderText: modelData.title
                targetStatus: modelData.status
                taskListModel: modelData.model
                onEditRequested: function(idx, currentContent) {
                    root.editIndex = idx;
                }
            }

        }

    }

    StyledRectangularShadow {
        target: timers
        visible: target.visible
        radius: Rounding.normal
    }

    TimerItem {
        id: timers

        extraVisibleCondition: quarters
        anchors.bottom: parent.bottom
        anchors.margins: root.fabMargins
        anchors.left: parent.left
    }

    Component {
        id: dragTaskComponent

        Rectangle {
            id: dragRect

            property var taskData

            width: 100
            height: 60
            radius: Rounding.large
            opacity: 0.9

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                spacing: 15

                MaterialSymbol {
                    text: {
                        switch (taskData.status) {
                        case TodoService.status_todo:
                            return "radio_button_unchecked";
                        case TodoService.status_in_progress:
                            return "work_history";
                        case TodoService.status_final_touches:
                            return "auto_fix_high";
                        case TodoService.status_done:
                            return "check_circle";
                        default:
                            return "radio_button_unchecked";
                        }
                    }
                    color: {
                        switch (taskData.status) {
                        case TodoService.status_todo:
                            return Colors.colOnLayer1;
                        case TodoService.status_in_progress:
                            return Colors.colPrimary;
                        case TodoService.status_final_touches:
                            return Colors.colSecondary;
                        case TodoService.status_done:
                            return Colors.m3.m3success;
                        default:
                            return Colors.colOnLayer1;
                        }
                    }
                    font.pixelSize: Fonts.sizes.normal
                }

                Column {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 6

                        StyledText {
                            width: 180
                            text: taskData.content
                            wrapMode: Text.Wrap
                            opacity: taskData.status === TodoService.status_done ? 0.7 : 1
                            font.strikeout: taskData.status === TodoService.status_done
                            maximumLineCount: 2
                        }

                        MaterialSymbol {
                            visible: taskData.todoistId !== "" && taskData.todoistId !== null
                            text: "cloud_done"
                            font.pixelSize: 14
                            color: Colors.colPrimary
                            opacity: 0.5
                        }

                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            switch (taskData.status) {
                            case TodoService.status_todo:
                                return "Not Started";
                            case TodoService.status_in_progress:
                                return "In Progress";
                            case TodoService.status_final_touches:
                                return "Final Touches";
                            case TodoService.status_done:
                                return "Finished";
                            default:
                                return "Not Started";
                            }
                        }
                        opacity: taskData.status === TodoService.status_done ? 0.3 : 0.45
                        font.pixelSize: 11
                    }

                }

                Item {
                    Layout.fillWidth: true
                }

            }

        }

    }

}
