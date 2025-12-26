pragma Singleton
import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions

/* Bundled Custom QS Functions For Noon */

Singleton {
    id: root
    readonly property var avilableSystemCommands: Mem.states.misc.systemCommands
    readonly property var avilableIpcCommands: Mem.states.misc.ipcCommands
    property bool ipcReady: false
    property bool commandsReady: false

    function iconPath(icon: string): string {
        let iconName;
        if (Mem.states.desktop.appearance.mode === "dark") {
            iconName = "noon-dark.png";
        } else
            iconName = "noon-light.png";
        return Quickshell.iconPath(icon, iconName);
    }

    function sudoExec(content: var) {
        Quickshell.execDetached(["pkexec", contentorg.hyprnoon]);
    }
    function playSound(name: string, volumeLevel, pack, repeat: int) {
        if (Mem.ready && Mem.options.desktop.behavior.sounds.enabled && !Mem.options.services.notifications.silent) {
            let packName = pack || "ui/";
            let path = Directories.sounds + packName + name + ".ogg";
            let volume = (volumeLevel || Mem.options.desktop.behavior.sounds.level) * 65536;
            let repeats = repeat || 1;

            // Loop with paplay for repeat > 1, single play otherwise
            let cmd = repeats > 1 ? `for i in {1..${repeats}}; do paplay --client-name "HyprNoon" --volume ${volume} ${path}; done` : `paplay --client-name "HyprNoon" --volume ${volume} ${path}`;

            exec(cmd);
        }
    }
    function wake(name: string) {
        // Start alarm sound (infinite loop until stopped)
        let path = Directories.sounds + "ui/alarm.ogg";
        let volume = 1.0 * 65536;
        let cmd = `while true; do paplay --client-name "HyprNoon-Alarm" --volume ${volume} ${path}; done`;

        exec(cmd);

        // Send notification with "Got it" button that stops the sound
        let icon = Directories.assets + "/icons/logo-symbolic.svg";
        let notifyCmd = `notify-send -i ${icon} -a "HyprNoon" -u critical -A "stop=Got it" "Wake Up !" "${name}" && pkill -f "paplay.*HyprNoon-Alarm"`;

        Quickshell.execDetached(["bash", "-c", notifyCmd]);
    }

    function notify(content: string, title: string) {
        let icon = Directories.assets + "/icons/logo-symbolic.svg";
        let titleStr = title || "HyprNoon";
        exec(`notify-send -i ${icon} -a ${titleStr} ${content}`);
    }
    function notifyPhone(content: string) {
        KdeConnectService.pingSelectedDevice(content);
    }
    function callIpc(request: string) {
        const cmd = `qs -c ~/.config/noon ipc call ${request}`;
        Quickshell.execDetached(["bash", "-c", cmd]);
    }
    function execDetached(command: var) {
        Quickshell.execDetached(command);
    }
    function exec(command: string) {
        execProc.command = ["bash", "-c", command];
        execProc.running = true;
    }
    function setHyprKey(key: string, value: string) {
        Quickshell.execDetached(["hyprctl", "keyword", key, value]);
    }
    function installPkg(app: string) {
        const terminal = Mem.options.apps.terminal || "kitty";
        Quickshell.execDetached(["kitty", "-e", "fish", "-c", ` yay -S --noconfirm  ${app}`]);
    }

    Process {
        id: execProc
    }
    function fetchCommands() {
        if (!commandsReady)
            commandLoader.running = true;
    }
    function fetchIpcCommands() {
        if (!ipcReady)
            ipcCommands.running = true;
    }
    Process {
        id: ipcCommands
        running: false
        command: ["bash", "-c", `qs -c ${FileUtils.trimFileProtocol(Directories.config)}/noon  ipc  show`]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                const parsed = [];
                const blocks = out.split("target ").map(b => b.trim()).filter(b => b.length > 0);
                for (let i = 0; i < blocks.length; ++i) {
                    const block = blocks[i];
                    const targetMatch = block.match(/^([^\s,]+)/);
                    if (!targetMatch)
                        continue;
                    const target = targetMatch[1];
                    const funcRegex = /function\s+([^\(]+)\(/g;
                    let m;
                    while ((m = funcRegex.exec(block)) !== null) {
                        const fn = m[1].trim();
                        parsed.push(target + " " + fn);
                    }
                }

                Mem.states.misc.ipcCommands = parsed;
                root.commandsReady = true;
                console.log("[Noon] fetched IPC commands");
            }
        }
    }
    Process {
        id: commandLoader
        running: false
        command: ["bash", "-c", "compgen -c | sort -u "]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                if (out.length === 0) {
                    Mem.states.misc.systemCommands = [];
                    root.commandsReady = true;
                    return;
                }
                Mem.states.misc.systemCommands = out.split("\n");
                root.commandsReady = true;
                console.log("[Noon] fetched Bash commands");
            }
        }
    }
}
