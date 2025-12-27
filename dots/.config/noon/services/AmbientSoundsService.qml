pragma Singleton
import QtQuick
import QtMultimedia
import Quickshell
import Qt.labs.folderlistmodel
import qs.common
import qs.common.utils

Singleton {
    id: root

    // Constants
    readonly property string audioDir: Directories.sounds + "ambient"
    readonly property var iconMap: ({
        "rain": "water_drop",
        "storm": "thunderstorm",
        "waves": "waves",
        "ocean": "waves",
        "fire": "local_fire_department",
        "fireplace": "local_fire_department",
        "wind": "air",
        "birds": "flutter_dash",
        "bird": "flutter_dash",
        "stream": "water",
        "river": "water",
        "water": "water",
        "white": "graphic_eq",
        "pink": "graphic_eq",
        "noise": "graphic_eq",
        "coffee": "local_cafe",
        "cafe": "local_cafe",
        "shop": "local_cafe",
        "train": "train",
        "boat": "sailing",
        "ship": "sailing",
        "night": "nightlight",
        "summer": "wb_sunny",
        "city": "location_city",
        "urban": "location_city"
    })

    // State bindings
    property var availableSounds: Mem.states.services.ambientSounds.availableSounds
    property var activeSounds: Mem.states.services.ambientSounds.activeSounds
    property real masterVolume: Mem.states.services.ambientSounds.masterVolume
    property bool muted: Mem.states.services.ambientSounds.muted
    property bool masterPaused: Mem.states.services.ambientSounds.masterPaused

    // Players map (not persisted - QML objects can't be serialized)
    property var players: ({})

    // Folder scanner
    FolderListModel {
        id: audioFolderModel
        folder: Qt.resolvedUrl(root.audioDir)
        nameFilters: ["*.mp3", "*.ogg", "*.wav", "*.flac", "*.m4a"]
        showDirs: false
        onCountChanged: if (count > 0) scanAudioFiles()
    }

    // MediaPlayer component
    Component {
        id: playerComponent
        MediaPlayer {
            loops: MediaPlayer.Infinite
            audioOutput: AudioOutput {}
        }
    }

    // Change handlers
    onMasterVolumeChanged: updateAllVolumes()
    onMutedChanged: updateAllVolumes()
    onMasterPausedChanged: updateAllPlayback()

    // === Public API ===

    function playSound(soundId, volume = null) {
        const existing = activeSounds.find(s => s.id === soundId)
        if (existing) return

        const sound = availableSounds.find(s => s.id === soundId)
        if (!sound) return

        const vol = volume ?? masterVolume
        const player = playerComponent.createObject(root, {
            source: sound.filePath,
            "audioOutput.volume": calculateVolume(vol)
        })

        if (!player) return

        masterPaused ? player.pause() : player.play()
        players[soundId] = player

        Mem.states.services.ambientSounds.activeSounds.push({
            id: soundId,
            volume: vol,
            name: sound.name
        })
    }

    function stopSound(soundId) {
        const index = activeSounds.findIndex(s => s.id === soundId)
        if (index === -1) return

        // Destroy the player
        const player = players[soundId]
        if (player) {
            player.stop()
            player.destroy()
            delete players[soundId]
        }

        // Remove from state
        Mem.states.services.ambientSounds.activeSounds.splice(index, 1)
    }

    function toggleSound(soundId, volume = null) {
        activeSounds.find(s => s.id === soundId) ? stopSound(soundId) : playSound(soundId, volume)
    }

    function setSoundVolume(soundId, volume) {
        const soundData = activeSounds.find(s => s.id === soundId)
        if (!soundData) return

        const clampedVolume = Math.max(0, Math.min(1, volume))
        soundData.volume = clampedVolume
        
        const player = players[soundId]
        if (player) {
            player.audioOutput.volume = calculateVolume(clampedVolume)
        }
    }

    function toggleMasterPause() {
        Mem.states.services.ambientSounds.masterPaused = !masterPaused
    }

    function toggleMute() {
        Mem.states.services.ambientSounds.muted = !muted
    }

    function stopAll() {
        for (let i = activeSounds.length - 1; i >= 0; i--) {
            stopSound(activeSounds[i].id)
        }
        Mem.states.services.ambientSounds.masterPaused = false
    }

    function isPlaying(soundId) {
        return !!players[soundId]
    }

    function getSoundVolume(soundId) {
        return activeSounds.find(s => s.id === soundId)?.volume ?? masterVolume
    }

    function getPlayer(soundId) {
        return players[soundId]
    }

    function refresh() {
        audioFolderModel.folder = ""
        Qt.callLater(() => audioFolderModel.folder = Qt.resolvedUrl(root.audioDir))
    }

    // === Private Functions ===

    function reload() {
        if (availableSounds.length === 0) {
            audioFolderModel.folder = Qt.resolvedUrl(root.audioDir)
        } else {
            restorePlayers()
        }
    }

    function restorePlayers() {
        Qt.callLater(() => {
            for (let i = 0; i < activeSounds.length; i++) {
                const soundData = activeSounds[i]
                if (players[soundData.id]) continue

                const sound = availableSounds.find(s => s.id === soundData.id)
                if (!sound) continue

                const player = playerComponent.createObject(root, {
                    source: sound.filePath,
                    "audioOutput.volume": calculateVolume(soundData.volume)
                })

                if (player) {
                    masterPaused ? player.pause() : player.play()
                    players[soundData.id] = player
                }
            }
        })
    }

    function scanAudioFiles() {
        const sounds = []

        for (let i = 0; i < audioFolderModel.count; i++) {
            const fileName = audioFolderModel.get(i, "fileName")
            const nameWithoutExt = fileName.replace(/\.[^.]+$/, '')
            const soundId = nameWithoutExt.toLowerCase().replace(/[^a-z0-9]/g, '_')

            sounds.push({
                id: soundId,
                name: formatDisplayName(nameWithoutExt),
                icon: getIconForName(nameWithoutExt.toLowerCase()),
                filePath: audioFolderModel.get(i, "fileUrl"),
                fileName: fileName
            })
        }

        Mem.states.services.ambientSounds.availableSounds = sounds
        restorePlayers()
    }

    function formatDisplayName(name) {
        return name.replace(/[_-]/g, ' ')
            .split(' ')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join(' ')
    }

    function getIconForName(lowerName) {
        for (const [key, value] of Object.entries(iconMap)) {
            if (lowerName.includes(key)) return value
        }
        return "music_note"
    }

    function calculateVolume(soundVolume) {
        return muted ? 0 : soundVolume * masterVolume
    }

    function updateAllVolumes() {
        for (let i = 0; i < activeSounds.length; i++) {
            const soundData = activeSounds[i]
            const player = players[soundData.id]
            if (player) {
                player.audioOutput.volume = calculateVolume(soundData.volume)
            }
        }
    }

    function updateAllPlayback() {
        for (let i = 0; i < activeSounds.length; i++) {
            const soundData = activeSounds[i]
            const player = players[soundData.id]
            if (player) {
                masterPaused ? player.pause() : player.play()
            }
        }
    }
}