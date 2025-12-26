pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import Quickshell
import Quickshell.Hyprland
import Qt.labs.platform
import QtQuick

/**
 * Enhanced to-do list manager with Todoist API integration.
 * Supports bidirectional sync between local storage and Todoist.
 * Each item has "content", "status", and optional "todoistId" properties.
 * Status workflow: todo -> in_progress -> final_touches -> done
 **/

Singleton {
    id: root

    property var list: []
    property string todoistApiToken: KeyringStorage?.keyringData.todoistApiKey
    property bool todoistEnabled: Mem.options.services.todo.enableTodoist ?? false
    property bool syncEnabled: todoistEnabled && todoistApiToken.length > 0
    property int syncInterval: 10000
    property var pendingSyncIds: []

    // Sync state enum
    enum SyncState {
        Offline,    // No token or disabled
        Idle,       // Ready to sync but not currently syncing
        Syncing,    // Currently syncing with Todoist
        Error       // Last sync failed
    }
    property int syncState: {
        if (!syncEnabled)
            return TodoService.SyncState.Offline;
        return TodoService.SyncState.Idle;
    }

    readonly property int status_todo: 0
    readonly property int status_in_progress: 1
    readonly property int status_final_touches: 2
    readonly property int status_done: 3
    readonly property var statusNames: ["Not Started", "In Progress", "Final Touches", "Finished"]
    readonly property var statusLabels: ["todo", "in_progress", "final_touches", "done"]

    onTodoistApiTokenChanged: {
        todoistApiToken = todoistApiToken.trim();
        if (syncEnabled && syncState !== TodoService.SyncState.Syncing) {
            syncWithTodoist();
        }
        updateSyncState();
    }

    onTodoistEnabledChanged: {
        if (syncEnabled && syncState !== TodoService.SyncState.Syncing) {
            syncWithTodoist();
        }
        updateSyncState();
    }

    function updateSyncState() {
        if (!syncEnabled) {
            syncState = TodoService.SyncState.Offline;
        } else if (syncState === TodoService.SyncState.Syncing)
        // Keep syncing state
        {} else {
            syncState = TodoService.SyncState.Idle;
        }
    }

    Timer {
        interval: root.syncInterval
        running: root.syncState === TodoService.SyncState.Idle
        repeat: true
        onTriggered: root.syncWithTodoist()
    }

    // Storage Operations
    function saveToConfig() {
        Mem.todo.tasks = root.list;
    }

    function loadFromConfig() {
        const savedTasks = Mem.todo.tasks;
        if (savedTasks.length > 0 && savedTasks[0].hasOwnProperty('done')) {
            root.list = migrateOldFormat(savedTasks);
            saveToConfig();
        } else {
            root.list = savedTasks;
        }
    }

    // Local Operations
    function addTask(desc) {
        const newTask = {
            content: desc,
            status: status_todo
        };

        list.push(newTask);
        root.list = list.slice(0);
        saveToConfig();
        Noon.playSound("task_added");

        if (syncEnabled) {
            const tempId = "pending_" + Date.now() + "_" + Math.random();
            const index = list.length - 1;
            list[index]._tempId = tempId;
            pendingSyncIds.push(tempId);
            syncItemToTodoist(index, tempId);
        }
    }

    function editItem(index, newContent) {
        if (index >= 0 && index < list.length && newContent.trim() !== "") {
            list[index].content = newContent.trim();
            root.list = list.slice(0);
            saveToConfig();
            if (syncEnabled && list[index].todoistId)
                updateTodoistItem(index);
            return true;
        }
        return false;
    }

    function setStatus(index, status) {
        if (index >= 0 && index < list.length && status >= status_todo && status <= status_done) {
            list[index].status = status;
            root.list = list.slice(0);
            saveToConfig();
            if (syncEnabled && list[index].todoistId)
                updateTodoistItem(index);
        }
    }

    function nextStatus(index) {
        if (index >= 0 && index < list.length) {
            const currentStatus = list[index].status;
            if (currentStatus < status_done)
                setStatus(index, currentStatus + 1);
        }
    }

    function previousStatus(index) {
        if (index >= 0 && index < list.length) {
            const currentStatus = list[index].status;
            if (currentStatus > status_todo)
                setStatus(index, currentStatus - 1);
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            const todoistId = list[index].todoistId;
            const tempId = list[index]._tempId;

            if (tempId)
                pendingSyncIds = pendingSyncIds.filter(id => id !== tempId);
            list.splice(index, 1);
            root.list = list.slice(0);
            saveToConfig();
            Noon.playSound("task_completed");

            if (syncEnabled && todoistId)
                deleteTodoistItem(todoistId);
        }
    }

    function refresh() {
        loadFromConfig();
    }

    // Todoist API Operations
    function syncWithTodoist() {
        if (!syncEnabled || syncState === TodoService.SyncState.Syncing)
            return;
        syncState = TodoService.SyncState.Syncing;

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        mergeTodoistTasks(JSON.parse(xhr.responseText));
                        syncState = TodoService.SyncState.Idle;
                    } catch (e) {
                        console.log("Failed to parse Todoist tasks:", e);
                        syncState = TodoService.SyncState.Error;
                    }
                } else {
                    console.log("Failed to fetch tasks (HTTP " + xhr.status + ")");
                    syncState = TodoService.SyncState.Error;
                }
            }
        };
        xhr.open("GET", "https://api.todoist.com/rest/v2/tasks");
        xhr.setRequestHeader("Authorization", "Bearer " + todoistApiToken);
        xhr.send();
    }

    function mergeTodoistTasks(todoistTasks) {
        const localTasksMap = new Map();
        list.forEach((item, index) => {
            if (item.todoistId)
                localTasksMap.set(item.todoistId, index);
        });

        todoistTasks.forEach(task => {
            const status = task.is_completed ? status_done : getStatusFromLabels(task.labels);
            const existingIndex = localTasksMap.get(task.id);

            if (existingIndex !== undefined) {
                list[existingIndex].content = task.content;
                list[existingIndex].status = status;
            } else {
                list.push({
                    content: task.content,
                    status: status,
                    todoistId: task.id
                });
            }
        });

        const todoistIds = new Set(todoistTasks.map(task => task.id));
        list = list.filter(item => !item.todoistId || todoistIds.has(item.todoistId) || (item._tempId && pendingSyncIds.includes(item._tempId)));

        root.list = list.slice(0);
        saveToConfig();

        // Push local tasks without todoistId to Todoist
        list.forEach((item, index) => {
            if (!item.todoistId && !item._tempId) {
                const tempId = "pending_" + Date.now() + "_" + Math.random() + "_" + index;
                list[index]._tempId = tempId;
                pendingSyncIds.push(tempId);
                syncItemToTodoist(index, tempId);
            }
        });
    }

    function syncItemToTodoist(index, tempId) {
        if (index < 0 || index >= list.length)
            return;

        const payload = JSON.stringify({
            content: list[index].content,
            labels: [statusLabels[list[index].status]],
            due_string: "today"
        });

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                pendingSyncIds = pendingSyncIds.filter(id => id !== tempId);
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        const itemIndex = list.findIndex(item => item._tempId === tempId);
                        if (itemIndex >= 0) {
                            list[itemIndex].todoistId = response.id;
                            delete list[itemIndex]._tempId;
                            root.list = list.slice(0);
                            saveToConfig();
                        }
                    } catch (_) {}
                }
            }
        };
        xhr.open("POST", "https://api.todoist.com/rest/v2/tasks");
        xhr.setRequestHeader("Authorization", "Bearer " + todoistApiToken);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(payload);
    }

    function updateTodoistItem(index) {
        if (index < 0 || index >= list.length || !list[index].todoistId)
            return;

        const item = list[index];
        const baseUrl = "https://api.todoist.com/rest/v2/tasks/" + item.todoistId;

        var xhr = new XMLHttpRequest();
        xhr.open("POST", baseUrl);
        xhr.setRequestHeader("Authorization", "Bearer " + todoistApiToken);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({
            content: item.content,
            labels: [statusLabels[item.status]]
        }));

        var xhrComplete = new XMLHttpRequest();
        xhrComplete.open("POST", baseUrl + (item.status === status_done ? "/close" : "/reopen"));
        xhrComplete.setRequestHeader("Authorization", "Bearer " + todoistApiToken);
        xhrComplete.send();
    }

    function deleteTodoistItem(todoistId) {
        var xhr = new XMLHttpRequest();
        xhr.open("DELETE", "https://api.todoist.com/rest/v2/tasks/" + todoistId);
        xhr.setRequestHeader("Authorization", "Bearer " + todoistApiToken);
        xhr.send();
    }

    function getStatusFromLabels(labels) {
        for (let i = statusLabels.length - 1; i >= 0; i--) {
            if (labels.includes(statusLabels[i]))
                return i;
        }
        return status_todo;
    }

    // Utility Functions
    function getStatusName(status) {
        return statusNames[status] || "Unknown";
    }
    function getTasksByStatus(status) {
        return list.filter(item => item.status === status);
    }
    function getTaskCount() {
        return list.length;
    }
    function getTaskCountByStatus(status) {
        return list.filter(item => item.status === status).length;
    }
    function getProgress() {
        return list.length === 0 ? 0 : getTaskCountByStatus(status_done) / list.length;
    }
    function getItemContent(index) {
        return index >= 0 && index < list.length ? list[index].content : "";
    }
    function getItemStatus(index) {
        return index >= 0 && index < list.length ? list[index].status : status_todo;
    }

    function migrateOldFormat(oldList) {
        return oldList.map(item => {
            if (item.hasOwnProperty('done')) {
                return {
                    content: item.content,
                    status: item.done ? status_done : status_todo
                };
            }
            return {
                content: item.content,
                status: item.status ?? status_todo,
                todoistId: item.todoistId
            };
        });
    }
    Component.onCompleted: {
        loadFromConfig();
        if (syncEnabled) {
             syncWithTodoist();
        }
    }
}
