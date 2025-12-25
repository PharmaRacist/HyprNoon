pragma Singleton
import QtQuick
import QtMultimedia
import Quickshell
import Qt.labs.folderlistmodel
import qs.modules.common
import qs.modules.common.utils

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

    // State properties
    property var availableSounds: []
    property var activeSounds: ({})
    property real masterVolume: 1.0
    property bool muted: false
    property bool masterPaused: false

    // Computed property
    readonly property var activeSoundsList: Object.keys(activeSounds).map(soundId => ({
        id: soundId,
        name: activeSounds[soundId].name,
        volume: activeSounds[soundId].volume,
        isPlaying: activeSounds[soundId].player.playbackState === MediaPlayer.PlayingState
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
        if (activeSounds[soundId]) return

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

        activeSounds[soundId] = {
            player: player,
            volume: volume ?? masterVolume,
            name: sound.name
        }
        activeSoundsChanged()
        saveState()
    }

    function stopSound(soundId) {
        const soundData = activeSounds[soundId]
        if (!soundData) return

        soundData.player.stop()
        soundData.player.destroy()
        delete activeSounds[soundId]
        activeSoundsChanged()
        saveState()
    }

    function toggleSound(soundId, volume = null) {
        activeSounds[soundId] ? stopSound(soundId) : playSound(soundId, volume)
    }

    function setSoundVolume(soundId, volume) {
        const soundData = activeSounds[soundId]
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
        Object.keys(activeSounds).forEach(stopSound)
        masterPaused = false
    }

    function refresh() {
        audioFolderModel.folder = ""
        Qt.callLater(() => audioFolderModel.folder = Qt.resolvedUrl(root.audioDir))
    }

    function isPlaying(soundId) {
        return !!activeSounds[soundId]
    }

    function getSoundVolume(soundId) {
        return activeSounds[soundId]?.volume ?? masterVolume
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
        Object.values(activeSounds).forEach(soundData => {
            soundData.player.audioOutput.volume = calculateVolume(soundData.volume)
        })
    }

    function updateAllPlayback() {
        Object.values(activeSounds).forEach(soundData => {
            masterPaused ? soundData.player.pause() : soundData.player.play()
        })
    }

    function saveState() {
        Mem.states.services.ambientSounds = {
            masterVolume: masterVolume,
            muted: muted,
            masterPaused: masterPaused,
            availableSounds: availableSounds,
            activeSounds: Object.keys(activeSounds).map(soundId => ({
                id: soundId,
                volume: activeSounds[soundId].volume,
                name: activeSounds[soundId].name
            }))
        }
    }

    function loadState() {
        const state = Mem.states.services.ambientSounds
        if (!state) return

        masterVolume = state.masterVolume ?? 1.0
        muted = state.muted ?? false
        masterPaused = state.masterPaused ?? false
        availableSounds = state.availableSounds ?? []

        if (state.activeSounds?.length > 0) {
            Qt.callLater(() => {
                state.activeSounds.forEach(soundData => {
                    if (availableSounds.find(s => s.id === soundData.id)) {
                        playSound(soundData.id, soundData.volume)
                    }
                })
            })
        }
    }
}
