pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions

Singleton {
    id: root

    property bool adaptiveTheme: Mem.options.mediaPlayer.adaptiveTheme
    property color artDominantColor: quantizerLoader.item?.colors[0] ?? Colors.m3.m3secondaryContainer
    property color gradColor: Qt.darker(ColorUtils.mix(colors.colSecondary, root.artDominantColor, 0.2), 1.4)
    property bool backgroundIsDark: artDominantColor.hslLightness < 0.7

    Loader {
        id: quantizerLoader
        active: adaptiveTheme
        onLoaded:item && item !== null ? art.source : BeatsService.artUrl
        sourceComponent: ColorQuantizer {
            id: colorQuantizer
            depth: 0
            rescaleSize: 1
        }
    }

    readonly property QtObject colors: QtObject {
        property color colLayer0: root.adaptiveTheme ? ColorUtils.mix(Colors.colLayer0, Qt.darker(root.artDominantColor, 2), 0.1) : Colors.colLayer0
        property color colLayer1: root.adaptiveTheme ? ColorUtils.mix(Colors.colLayer1, Qt.darker(root.artDominantColor, 1.2), 0.35) : Colors.colLayer1
        property color colLayer2: root.adaptiveTheme ? ColorUtils.mix(Colors.colLayer2, root.artDominantColor, 0.34) : Colors.colLayer2
        property color colLayer3: root.adaptiveTheme ? ColorUtils.mix(Colors.colLayer3, root.artDominantColor, 0.2) : Colors.colLayer3

        // Surface hover/pressed states
        property color colLayer1Hover: root.adaptiveTheme ? ColorUtils.mix(Colors.colLayer1Hover, root.artDominantColor, 0.4) : Colors.colLayer1Hover
        property color colLayer1Active: root.adaptiveTheme ? ColorUtils.mix(Colors.colLayer1Active, root.artDominantColor, 0.5) : Colors.colLayer1Active
        property color colLayer2Hover: root.adaptiveTheme ? ColorUtils.mix(Colors.colLayer2Hover, root.artDominantColor, 0.3) : Colors.colLayer2Hover
        property color colLayer2Active: root.adaptiveTheme ? ColorUtils.mix(Colors.colLayer2Active, root.artDominantColor, 0.4) : Colors.colLayer2Active

        // Text colors
        property color colOnLayer0: root.adaptiveTheme ? ColorUtils.mix(Colors.colOnLayer0, root.artDominantColor, 0.7) : Colors.colOnLayer0
        property color colOnLayer1: root.adaptiveTheme ? ColorUtils.mix(Colors.colOnLayer1, root.artDominantColor, 0.5) : Colors.colOnLayer1
        property color colOnLayer2: root.adaptiveTheme ? ColorUtils.mix(Colors.colOnLayer2, root.artDominantColor, 0.45) : Colors.colOnLayer2
        property color colSubtext: root.adaptiveTheme ? ColorUtils.mix(Colors.colOnLayer1, root.artDominantColor, 0.7) : Colors.colSubtext

        // Primary colors
        property color colPrimary: root.adaptiveTheme ? ColorUtils.mix(ColorUtils.adaptToAccent(Colors.colPrimary, root.artDominantColor), root.artDominantColor, 1) : Colors.colPrimary
        property color colLyrics: ColorUtils.mix(ColorUtils.adaptToAccent(Colors.colPrimary, root.artDominantColor), root.artDominantColor, 0.85)
        property color colLyricsActive: ColorUtils.mix(colOnSecondaryContainer, colOnPrimary)
        property color colPrimaryHover: root.adaptiveTheme ? ColorUtils.mix(ColorUtils.adaptToAccent(Colors.colPrimaryHover, root.artDominantColor), root.artDominantColor, 1) : Colors.colPrimaryHover
        property color colPrimaryActive: root.adaptiveTheme ? ColorUtils.mix(ColorUtils.adaptToAccent(Colors.colPrimaryActive, colSecondaryActive), root.artDominantColor, 1) : Colors.colPrimaryActive
        property color colOnPrimary: root.adaptiveTheme ? ColorUtils.mix(ColorUtils.adaptToAccent(Colors.m3.m3onPrimary, root.artDominantColor), root.artDominantColor, 0.7) : Colors.m3.m3onPrimary

        // Secondary colors
        property color colSecondary: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3secondary, root.artDominantColor, 0.2) : Colors.m3.m3secondary
        property color colSecondaryHover: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3secondary, root.artDominantColor, 0.76) : Qt.lighter(Colors.m3.m3secondary, 1.1)
        property color colSecondaryActive: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3secondary, root.artDominantColor, 0.5) : Qt.darker(Colors.m3.m3secondary, 1.1)
        property color colOnSecondary: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3onSecondary, root.artDominantColor, 0.95) : Colors.m3.m3onSecondary

        // Secondary containers
        property color colSecondaryContainer: root.adaptiveTheme ? Qt.darker(colSecondary, 1.4) : Colors.m3.m3secondaryContainer
        property color colSecondaryContainerHover: root.adaptiveTheme ? ColorUtils.mix(Colors.colSecondaryContainerHover, root.artDominantColor, 0.5) : Colors.colSecondaryContainerHover
        property color colSecondaryContainerActive: root.adaptiveTheme ? ColorUtils.mix(Colors.colSecondaryContainerActive, root.artDominantColor, 0.5) : Colors.colSecondaryContainerActive
        property color colOnSecondaryContainer: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3onSurface, root.artDominantColor, 0.6) : Colors.m3.m3onSurface

        // Tertiary colors
        property color colTertiary: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3tertiary, root.artDominantColor, 0.4) : Colors.m3.m3tertiary
        property color colTertiaryContainer: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3tertiaryContainer, root.artDominantColor, 0.2) : Colors.m3.m3tertiaryContainer
        property color colOnTertiary: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3onTertiary, root.artDominantColor, 0.5) : Colors.m3.m3onTertiary
        property color colOnTertiaryContainer: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3onTertiaryContainer, root.artDominantColor, 0.5) : Colors.m3.m3onTertiaryContainer

        // Error colors
        property color colError: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3error, root.artDominantColor, 0.3) : Colors.m3.m3error
        property color colErrorContainer: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3errorContainer, root.artDominantColor, 0.15) : Colors.m3.m3errorContainer
        property color colOnError: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3onError, root.artDominantColor, 0.5) : Colors.m3.m3onError
        property color colOnErrorContainer: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3onErrorContainer, root.artDominantColor, 0.5) : Colors.m3.m3onErrorContainer

        // Surface variants
        property color colOnSurface: root.adaptiveTheme ? ColorUtils.mix(Colors.colOnLayer0, root.artDominantColor, 0.7) : Colors.colOnLayer0
        property color colSurface: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3surface, root.artDominantColor, 0.4) : Colors.m3.m3surface
        property color colSurfaceVariant: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3surfaceVariant, root.artDominantColor, 0.3) : Colors.m3.m3surfaceVariant
        property color colSurfaceContainer: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3surfaceContainer, root.artDominantColor, 0.25) : Colors.m3.m3surfaceContainer
        property color colSurfaceContainerHigh: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3surfaceContainerHigh, root.artDominantColor, 0.2) : Colors.m3.m3surfaceContainerHigh
        property color colSurfaceContainerHighest: root.adaptiveTheme ? ColorUtils.mix(Colors.colSurfaceContainerHighest, root.artDominantColor, 0.15) : Colors.colSurfaceContainerHighest
        property color colSurfaceContainerLow: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3surfaceContainerLow, root.artDominantColor, 0.3) : Colors.m3.m3surfaceContainerLow
        property color colSurfaceContainerLowest: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3surfaceContainerLowest, root.artDominantColor, 0.35) : Colors.m3.m3surfaceContainerLowest

        // Inverse colors
        property color colInverseSurface: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3inverseSurface, root.artDominantColor, 0.4) : Colors.m3.m3inverseSurface
        property color colInverseOnSurface: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3inverseOnSurface, root.artDominantColor, 0.5) : Colors.m3.m3inverseOnSurface
        property color colInversePrimary: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3inversePrimary, root.artDominantColor, 0.4) : Colors.m3.m3inversePrimary

        // Outline colors
        property color colOutline: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3outline, root.artDominantColor, 0.4) : Colors.m3.m3outline
        property color colOutlineVariant: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3outlineVariant, root.artDominantColor, 0.3) : Colors.m3.m3outlineVariant

        // Scrim and shadows
        property color colScrim: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3scrim, root.artDominantColor, 0.2) : Colors.m3.m3scrim
        property color colShadow: root.adaptiveTheme ? ColorUtils.mix(Colors.m3.m3shadow, root.artDominantColor, 0.1) : Colors.m3.m3shadow

        // Additional utility colors for specific components
        property color colDivider: root.adaptiveTheme ? ColorUtils.mix(colOutlineVariant, root.artDominantColor, 0.3) : colOutlineVariant
        property color colDisabled: root.adaptiveTheme ? Qt.rgba(colOnSurface.r, colOnSurface.g, colOnSurface.b, 0.38) : Qt.rgba(Colors.m3.m3onSurface.r, Colors.m3.m3onSurface.g, Colors.m3.m3onSurface.b, 0.38)
        property color colSurfaceDisabled: root.adaptiveTheme ? Qt.rgba(colOnSurface.r, colOnSurface.g, colOnSurface.b, 0.12) : Qt.rgba(Colors.m3.m3onSurface.r, Colors.m3.m3onSurface.g, Colors.m3.m3onSurface.b, 0.12)

        // Focus and state layer colors
        property color colFocusOverlay: root.adaptiveTheme ? Qt.rgba(colPrimary.r, colPrimary.g, colPrimary.b, 0.12) : Qt.rgba(Colors.colPrimary.r, Colors.colPrimary.g, Colors.colPrimary.b, 0.12)
        property color colHoverOverlay: root.adaptiveTheme ? Qt.rgba(colOnSurface.r, colOnSurface.g, colOnSurface.b, 0.08) : Qt.rgba(Colors.m3.m3onSurface.r, Colors.m3.m3onSurface.g, Colors.m3.m3onSurface.b, 0.08)
        property color colPressedOverlay: root.adaptiveTheme ? Qt.rgba(colOnSurface.r, colOnSurface.g, colOnSurface.b, 0.12) : Qt.rgba(Colors.m3.m3onSurface.r, Colors.m3.m3onSurface.g, Colors.m3.m3onSurface.b, 0.12)
        property color colSelectedOverlay: root.adaptiveTheme ? Qt.rgba(colPrimary.r, colPrimary.g, colPrimary.b, 0.08) : Qt.rgba(Colors.colPrimary.r, Colors.colPrimary.g, Colors.colPrimary.b, 0.08)
    }
}
