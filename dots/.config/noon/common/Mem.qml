import qs.common.utils
import qs.store
pragma Singleton

Singleton {
    id: root

    property bool ready: todoView.loaded && optionsView.loaded && statesView.loaded && timersView.loaded
    property alias states: statesView.data
    property alias options: optionsView.data
    property alias timers: timersView.data
    property alias todo: todoView.data

    ConfigFileView {
        id: optionsView

        state: false
        fileName: "options"

        OptionsSchema {
        }

    }

    ConfigFileView {
        id: todoView

        fileName: "todo"

        TodoSchema {
        }

    }

    ConfigFileView {
        id: statesView

        fileName: "states"

        StatesSchema {
        }

    }

    ConfigFileView {
        id: timersView

        fileName: "timers"

        TimersSchema {
        }

    }

}
