pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    property string time: {
        if (Mem.options.services.time.use12HourFormat) {
            return Qt.formatDateTime(clock.date, "hh:mm ap");
        } else {
            return Qt.formatDateTime(clock.date, "HH:mm");
        }
    }

    property string date: Qt.formatDateTime(clock.date, "dddd, dd/MM")
    property string day: Qt.formatDateTime(clock.date, "dd")
    property string month: Qt.formatDateTime(clock.date, "MMMM")
    property string year: Qt.formatDateTime(clock.date, "yyyy")

    property string hour: {
        if (Mem.options.services.time.use12HourFormat) {
            return Qt.formatDateTime(clock.date, "hh AP").split(" ")[0];
        } else {
            return Qt.formatDateTime(clock.date, "HH");
        }
    }

    property string cleanHour: {
        if (Mem.options.services.time.use12HourFormat) {
            var hourStr = Qt.formatDateTime(clock.date, "hh AP").split(" ")[0];
            return String(parseInt(hourStr));
        } else {
            var hourStr = Qt.formatDateTime(clock.date, "HH");
            return String(parseInt(hourStr));
        }
    }

    property string minute: Qt.formatDateTime(clock.date, "mm")

    property string cleanMinute: String(parseInt(Qt.formatDateTime(clock.date, "mm")))

    property string dayTime: {
        if (Mem.options.services.time.use12HourFormat) {
            return Qt.formatDateTime(clock.date, "hh AP").split(" ")[1];
        } else {
            return "";
        }
    }

    // Arabic week day name
    property string arabicDayName: clock.date.toLocaleDateString(Qt.locale("ar_SA"), "dddd")

    property string uptime: "0h, 0m"
    property string collapsedCalendarFormat: Qt.formatDateTime(clock.date, "dd MMMM yyyy")

    property string gnomeClockWidgetFormat: {
        var monthName = Qt.formatDateTime(clock.date, "MMMM");
        var timeFormat = Mem.options.services.time.use12HourFormat ? " dd hh:mm ap " : " dd HH:mm ";
        var rest = Qt.formatDateTime(clock.date, timeFormat);
        return monthName.charAt(0).toUpperCase() + monthName.slice(1) + rest;
    }
    // Relative time formatting function
    function getRelativeTime(timestamp) {
        var now = new Date();
        var savedTime = new Date(timestamp);
        var diff = Math.floor((now - savedTime) / 1000); // difference in seconds

        if (diff < 60) {
            return diff + "s ago";
        } else if (diff < 3600) {
            return Math.floor(diff / 60) + "m ago";
        } else if (diff < 86400) {
            return Math.floor(diff / 3600) + "h ago";
        } else {
            // More than a day, show the date
            return Qt.formatDate(savedTime, "MMM d, yyyy");
        }
    }

    /**
     * Vertical-friendly compact date format (e.g. "25\nOct\n2025")
     */
    property string verticalDate: {
        const dayStr = Qt.formatDateTime(clock.date, "dd");
        const monthStr = Qt.formatDateTime(clock.date, "MMM");
        return `${dayStr}\n${monthStr}`;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Timer {
        id: uptimeRefresh
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            fileUptime.reload();
            const textUptime = fileUptime.text();
            const uptimeSeconds = Number(textUptime.split(" ")[0] ?? 0);

            // Convert seconds to days, hours, and minutes
            const days = Math.floor(uptimeSeconds / 86400);
            const hours = Math.floor((uptimeSeconds % 86400) / 3600);
            const minutes = Math.floor((uptimeSeconds % 3600) / 60);

            // Build formatted uptime string
            let formatted = "";
            if (days > 0)
                formatted += `${days}d`;
            if (hours > 0)
                formatted += `${formatted ? ", " : ""}${hours}h`;
            if (minutes > 0 || !formatted)
                formatted += `${formatted ? ", " : ""}${minutes}m`;
            uptime = formatted;
            // Every 10 min
            interval = 60 *1000 ;
        }
    }

    FileView {
        id: fileUptime
        path: "/proc/uptime"
    }
}
