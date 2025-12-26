import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.services
pragma Singleton

Singleton {
    property QtObject m3
    property real transparency: Mem.options.appearance.transparency.enabled ? Mem.options.appearance.transparency.scale : 0
    property real contentTransparency: Mem.options.appearance.transparency.scale
    // --- Base / Background Colors ---
    property color colOnBackground: WallpaperService.shellMode === "light" ? colLayer0 : colOnLayer0
    property color colSubtext: m3.m3outline
    property color colLayer0: ColorUtils.transparentize(m3.m3background, transparency)
    property color colOnLayer0: m3.m3onBackground
    property color colLayer0Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, 0.9), contentTransparency)
    property color colLayer0Active: ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, 0.8), contentTransparency)
    property color colLayer0Border: ColorUtils.mix(m3.m3outlineVariant, colLayer0, 0.4)
    // --- Layer 1 ---
    property color colLayer1: ColorUtils.transparentize(ColorUtils.mix(m3.m3surfaceContainerLow, m3.m3background, 0.8), contentTransparency)
    property color colOnLayer1: m3.m3onSurfaceVariant
    property color colOnLayer1Inactive: ColorUtils.mix(colOnLayer1, colLayer1, 0.45)
    property color colLayer1Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.92), contentTransparency)
    property color colLayer1Active: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.85), contentTransparency)
    // --- Layer 2 ---
    property color colLayer2: ColorUtils.transparentize(ColorUtils.mix(m3.m3surfaceContainer, m3.m3surfaceContainerHigh, 0.7), contentTransparency)
    property color colOnLayer2: m3.m3onSurface
    property color colOnLayer2Disabled: ColorUtils.mix(colOnLayer2, m3.m3background, 0.4)
    property color colLayer2Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, 0.9), contentTransparency)
    property color colLayer2Active: ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, 0.8), contentTransparency)
    property color colLayer2Disabled: ColorUtils.transparentize(ColorUtils.mix(colLayer2, m3.m3background, 0.8), contentTransparency)
    // --- Layer 3 ---
    property color colLayer3: ColorUtils.transparentize(ColorUtils.mix(m3.m3surfaceContainerHigh, m3.m3onSurface, 0.96), contentTransparency)
    property color colOnLayer3: m3.m3onSurface
    property color colLayer3Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer3, colOnLayer3, 0.9), contentTransparency)
    property color colLayer3Active: ColorUtils.transparentize(ColorUtils.mix(colLayer3, colOnLayer3, 0.8), contentTransparency)
    // --- Layer 4 ---
    property color colLayer4: ColorUtils.transparentize(m3.m3surfaceContainerHighest, contentTransparency)
    property color colOnLayer4: m3.m3onSurface
    property color colLayer4Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer4, colOnLayer4, 0.9), contentTransparency)
    property color colLayer4Active: ColorUtils.transparentize(ColorUtils.mix(colLayer4, colOnLayer4, 0.8), contentTransparency)
    // --- Primary ---
    property color colPrimary: m3.m3primary
    property color colOnPrimary: m3.m3onPrimary
    property color colPrimaryHover: ColorUtils.mix(colPrimary, colLayer1Hover, 0.87)
    property color colPrimaryActive: ColorUtils.mix(colPrimary, colLayer1Active, 0.7)
    property color colPrimaryContainer: m3.m3primaryContainer
    property color colPrimaryContainerHover: ColorUtils.mix(colPrimaryContainer, colLayer1Hover, 0.7)
    property color colPrimaryContainerActive: ColorUtils.mix(colPrimaryContainer, colLayer1Active, 0.6)
    property color colOnPrimaryContainer: m3.m3onPrimaryContainer
    // --- Secondary ---
    property color colSecondary: m3.m3secondary
    property color colOnSecondary: m3.m3onSecondary
    property color colSecondaryHover: ColorUtils.mix(colSecondary, colLayer1Hover, 0.85)
    property color colSecondaryActive: ColorUtils.mix(colSecondary, colLayer1Active, 0.4)
    property color colSecondaryContainer: ColorUtils.transparentize(m3.m3secondaryContainer, contentTransparency)
    property color colSecondaryContainerHover: ColorUtils.mix(colSecondaryContainer, colLayer1Hover, 0.6)
    property color colSecondaryContainerActive: ColorUtils.mix(colSecondaryContainer, colLayer1Active, 0.54)
    property color colOnSecondaryContainer: m3.m3onSecondaryContainer
    // --- Surface & OnSurface Variants ---
    property color colOnSurface: m3.m3onSurface
    property color colOnSurfaceVariant: m3.m3onSurfaceVariant
    property color colOnSurfaceDisabled: ColorUtils.mix(colOnSurface, m3.m3background, 0.4)
    property color colOnSurfaceLowEmphasis: ColorUtils.mix(colOnSurface, colOnSurfaceVariant, 0.6)
    property color colInverseSurface: m3.m3inverseSurface
    property color colInverseOnSurface: m3.m3inverseOnSurface
    // --- Tertiary ---
    property color colTertiary: m3.m3tertiary
    property color colTertiaryContainer: ColorUtils.transparentize(m3.m3tertiaryContainer, contentTransparency)
    property color colTertiaryHover: ColorUtils.mix(colTertiary, colLayer1Hover, 0.85)
    property color colTertiaryActive: ColorUtils.mix(colTertiary, colLayer1Active, 0.4)
    property color colTertiaryContainerHover: ColorUtils.mix(colTertiaryContainer, colLayer1Hover, 0.7)
    property color colTertiaryContainerActive: ColorUtils.mix(colTertiaryContainer, colLayer1Active, 0.6)
    // --- Surface Containers ---
    property color colSurfaceContainerLow: ColorUtils.transparentize(m3.m3surfaceContainerLow, contentTransparency)
    property color colSurfaceContainer: ColorUtils.transparentize(m3.m3surfaceContainer, contentTransparency)
    property color colSurfaceContainerHigh: ColorUtils.transparentize(m3.m3surfaceContainerHigh, contentTransparency)
    property color colSurfaceContainerHighest: ColorUtils.transparentize(m3.m3surfaceContainerHighest, contentTransparency)
    property color colSurfaceContainerHighestHover: ColorUtils.mix(m3.m3surfaceContainerHighest, m3.m3onSurface, 0.95)
    property color colSurfaceContainerHighestActive: ColorUtils.mix(m3.m3surfaceContainerHighest, m3.m3onSurface, 0.85)
    // --- Error Colors ---
    property color colError: m3.m3error
    property color colOnError: m3.m3onError
    property color colErrorHover: ColorUtils.mix(colError, colLayer1Hover, 0.85)
    property color colErrorActive: ColorUtils.mix(colError, colLayer1Active, 0.7)
    property color colErrorContainer: m3.m3errorContainer
    property color colErrorContainerHover: ColorUtils.mix(colErrorContainer, m3.m3onErrorContainer, 0.9)
    property color colErrorContainerActive: ColorUtils.mix(colErrorContainer, m3.m3onErrorContainer, 0.7)
    property color colOnErrorContainer: m3.m3onErrorContainer
    // --- Misc / Utility ---
    property color colOutline: ColorUtils.transparentize(m3.m3outline, 0.85)
    property color colOutlineVariant: m3.m3outlineVariant
    property color colTooltip: m3.darkmode ? ColorUtils.mix(m3.m3background, "#3C4043", 0.5) : "#3C4043"
    property color colOnTooltip: "#F8F9FA"
    property color colScrim: ColorUtils.transparentize(m3.m3scrim, 0.45)
    property color colShadow: ColorUtils.transparentize(m3.m3surface, 0.7)

    m3: QtObject {
        property bool darkmode: WallpaperService.shellMode === "dark"
        property bool transparent: false
        property color m3background: "#141313"
        property color m3onBackground: "#e6e1e1"
        property color m3surface: "#141313"
        property color m3surfaceDim: "#141313"
        property color m3surfaceBright: "#3a3939"
        property color m3surfaceContainerLowest: "#0f0e0e"
        property color m3surfaceContainerLow: "#1c1b1c"
        property color m3surfaceContainer: "#201f20"
        property color m3surfaceContainerHigh: "#2b2a2a"
        property color m3surfaceContainerHighest: "#363435"
        property color m3onSurface: "#e6e1e1"
        property color m3surfaceVariant: "#49464a"
        property color m3onSurfaceVariant: "#cbc5ca"
        property color m3inverseSurface: "#e6e1e1"
        property color m3inverseOnSurface: "#313030"
        property color m3outline: "#948f94"
        property color m3outlineVariant: "#49464a"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#cbc4cb"
        property color m3primary: "#cbc4cb"
        property color m3onPrimary: "#322f34"
        property color m3primaryContainer: "#2d2a2f"
        property color m3onPrimaryContainer: "#bcb6bc"
        property color m3inversePrimary: "#615d63"
        property color m3secondary: "#cac5c8"
        property color m3onSecondary: "#323032"
        property color m3secondaryContainer: "#4d4b4d"
        property color m3onSecondaryContainer: "#ece6e9"
        property color m3tertiary: "#d1c3c6"
        property color m3onTertiary: "#372e30"
        property color m3tertiaryContainer: "#31292b"
        property color m3onTertiaryContainer: "#c1b4b7"
        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3primaryFixed: "#e7e0e7"
        property color m3primaryFixedDim: "#cbc4cb"
        property color m3onPrimaryFixed: "#1d1b1f"
        property color m3onPrimaryFixedVariant: "#49454b"
        property color m3secondaryFixed: "#e6e1e4"
        property color m3secondaryFixedDim: "#cac5c8"
        property color m3onSecondaryFixed: "#1d1b1d"
        property color m3onSecondaryFixedVariant: "#484648"
        property color m3tertiaryFixed: "#eddfe1"
        property color m3tertiaryFixedDim: "#d1c3c6"
        property color m3onTertiaryFixed: "#211a1c"
        property color m3onTertiaryFixedVariant: "#4e4447"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
        property color term0: "#EDE4E4"
        property color term1: "#B52755"
        property color term2: "#A97363"
        property color term3: "#AF535D"
        property color term4: "#A67F7C"
        property color term5: "#B2416B"
        property color term6: "#8D76AD"
        property color term7: "#272022"
        property color term8: "#0E0D0D"
        property color term9: "#B52755"
        property color term10: "#A97363"
        property color term11: "#AF535D"
        property color term12: "#A67F7C"
        property color term13: "#B2416B"
        property color term14: "#8D76AD"
        property color term15: "#221A1A"
    }

}
