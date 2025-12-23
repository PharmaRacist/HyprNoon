import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
pragma Singleton

Singleton {
    readonly property var palettes: ["w11", "ayu_dark", "catppuccin_latte", "catppuccin_mocha", "cobalt2", "dracula", "github_dark", "gruvbox_dark", "gruvbox_light", "high_contrast_dark", "high_contrast_light", "material_dark", "material_light", "monokai", "nord", "night_owl", "one_dark", "palen_night", "shades_of_purple", "solarized_dark", "solarized_light", "synthwave84", "tokyo_night"]
    property var themes: [{
        "name": "Monochromatic",
        "value": "bw",
        "icon": "contrast"
    }, {
        "name": "Arc Dark",
        "value": "arcdark",
        "icon": "gradient"
    }, {
        "name": "Catppuccin",
        "value": "catppuccin",
        "icon": "palette"
    }, {
        "name": "Cyberpunk",
        "value": "cyberpunk",
        "icon": "computer"
    }, {
        "name": "Dracula",
        "value": "dracula",
        "icon": "dark_mode"
    }, {
        "name": "Everforest",
        "value": "everforest",
        "icon": "eco"
    }, {
        "name": "GitHub Light",
        "value": "github-light",
        "icon": "code"
    }, {
        "name": "Gruvbox",
        "value": "gruvbox",
        "icon": "texture"
    }, {
        "name": "Kanagawa",
        "value": "kanagawa",
        "icon": "waves"
    }, {
        "name": "Material",
        "value": "material",
        "icon": "design_services"
    }, {
        "name": "Monokai",
        "value": "monokai",
        "icon": "contrast"
    }, {
        "name": "Night Owl",
        "value": "night-owl",
        "icon": "nights_stay"
    }, {
        "name": "Nord",
        "value": "nord",
        "icon": "ac_unit"
    }, {
        "name": "Oceanic Next",
        "value": "oceanic-next",
        "icon": "water"
    }, {
        "name": "One Dark",
        "value": "onedark",
        "icon": "circle"
    }, {
        "name": "Rose Pine",
        "value": "rose-pine",
        "icon": "spa"
    }, {
        "name": "Shades of Purple",
        "value": "shades-of-purple",
        "icon": "color_lens"
    }, {
        "name": "Solarized",
        "value": "solarized",
        "icon": "wb_sunny"
    }, {
        "name": "Srcery",
        "value": "srcery",
        "icon": "brush"
    }, {
        "name": "Synthwave '84",
        "value": "synthwave-84",
        "icon": "graphic_eq"
    }, {
        "name": "Tokyo Storm",
        "value": "tokyo-storm",
        "icon": "thunderstorm"
    }]
    property var modes: [{
        "name": "Tonal Spot",
        "value": "scheme-tonal-spot",
        "icon": "palette"
    }, {
        "name": "Neutral",
        "value": "scheme-neutral",
        "icon": "contrast"
    }, {
        "name": "Expressive",
        "value": "scheme-expressive",
        "icon": "colorize"
    }, {
        "name": "Fidelity",
        "value": "scheme-fidelity",
        "icon": "image"
    }, {
        "name": "Content",
        "value": "scheme-content",
        "icon": "image"
    }, {
        "name": "Monochrome",
        "value": "scheme-monochrome",
        "icon": "monochrome_photos"
    }, {
        "name": "Rainbow",
        "value": "scheme-rainbow",
        "icon": "gradient"
    }, {
        "name": "Fruit Salad",
        "value": "scheme-fruit-salad",
        "icon": "nature"
    }, {
        "name": "Vibrant",
        "value": "scheme-vibrant",
        "icon": "palette"
    }]
}
