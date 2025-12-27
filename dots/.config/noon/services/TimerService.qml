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

    // Direct binding to JsonAdapter
    property var availableSounds: Mem.states.services.ambientSounds.availableSounds
    property var activeSounds: Mem.states.services.ambientSounds.activeSounds
    property real masterVolume: Mem.states.services.ambientSounds.masterVolume
    property bool muted: Mem.states.services.ambientSounds.muted
    property bool masterPaused: Mem.states.services.ambientSounds.masterPaused

    // Computed property
    readonly property var activeSoundsList: activeSounds.map(soundData => ({
        id: soundData.id,
        name: soundData.name,
        volume: soundData.volume,
        isPlaying: soundData.player.playbackState === MediaPlayer.PlayingState
    }))

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
    onMasterVolumeChanged: { updateAllVolumes(); saveState() }
    onMutedChanged: { updateAllVolumes(); saveState() }
    onMasterPausedChanged: { updateAllPlayback(); saveState() }

    // === Public API ===

    function playSound(soundId, volume = null) {
        if (activeSounds.some(s => s.id === soundId)) return

        const sound = availableSounds.find(s => s.id === soundId)
        if (!sound) {
            console.error("AmbientSound: Sound not found:", soundId)
            return
        }

        const player = playerComponent.createObject(root, {
            source: sound.filePath,
            "audioOutput.volume": calculateVolume(volume ?? masterVolume)
        })

        if (!player) return

        masterPaused ? player.pause() : player.play()

        activeSounds.push({
            id: soundId,
            player: player,
            volume: volume ?? masterVolume,
            name: sound.name
        })
        activeSoundsChanged()
        saveState()
    }

    function stopSound(soundId) {
        const index = activeSounds.findIndex(s => s.id === soundId)
        if (index === -1) return

        const soundData = activeSounds[index]
        soundData.player.stop()
        soundData.player.destroy()
        activeSounds.splice(index, 1)
        activeSoundsChanged()
        saveState()
    }

    function toggleSound(soundId, volume = null) {
        const isActive = activeSounds.some(s => s.id === soundId)
        isActive ? stopSound(soundId) : playSound(soundId, volume)
    }

    function setSoundVolume(soundId, volume) {
        const soundData = activeSounds.find(s => s.id === soundId)
        if (!soundData) return

        const clampedVolume = Math.max(0, Math.min(1, volume))
        soundData.volume = clampedVolume
        soundData.player.audioOutput.volume = calculateVolume(clampedVolume)
        activeSoundsChanged()
        saveState()
    }

    function toggleMasterPause() {
        masterPaused = !masterPaused
    }

    function toggleMute() {
        muted = !muted
    }

    function stopAll() {
        activeSounds.forEach(s => {
            s.player.stop()
            s.player.destroy()
        })
        activeSounds = []
        masterPaused = false
        activeSoundsChanged()
        saveState()
    }

    function refresh() {
        audioFolderModel.folder = ""
        Qt.callLater(() => audioFolderModel.folder = Qt.resolvedUrl(root.audioDir))
    }

    function isPlaying(soundId) {
        return activeSounds.some(s => s.id === soundId)
    }

    function getSoundVolume(soundId) {
        const soundData = activeSounds.find(s => s.id === soundId)
        return soundData?.volume ?? masterVolume
    }

    // === Private Functions ===

    function reload() {
        loadState()
        if (availableSounds.length === 0) {
            audioFolderModel.folder = Qt.resolvedUrl(root.audioDir)
        }
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

        availableSounds = sounds
        saveState()
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
        activeSounds.forEach(soundData => {
            soundData.player.audioOutput.volume = calculateVolume(soundData.volume)
        })
    }

    function updateAllPlayback() {
        activeSounds.forEach(soundData => {
            masterPaused ? soundData.player.pause() : soundData.player.play()
        })
    }

    function saveState() {
        Mem.states.services.ambientSounds = {
            masterVolume: masterVolume,
            muted: muted,
            masterPaused: masterPaused,
            availableSounds: availableSounds,
            activeSounds: activeSounds.map(soundData => ({
                id: soundData.id,
                volume: soundData.volume,
                name: soundData.name
            }))
        }
    }

    function loadState() {
        // State is auto-loaded via binding to Mem.states.services.ambientSounds
    }
}
