pragma Singleton
import QtQuick

// Central palette store. `active` is recomputed whenever `paletteName` or the
// live Omarchy bar colors change, so every component binds to Theme.active.*
// instead of resolving a palette itself.
QtObject {
    id: theme

    // Set by Widget.qml from the injected `bar` facade. Never mutated here.
    property color omarchyForeground: "#e6e6e6"
    property color omarchyBackground: "#1a1a1a"
    property color omarchyUrgent: "#e06c75"

    // "followOmarchy" | "krishnaBlue" | "peacock" | "gold" | "monochrome"
    property string paletteName: "followOmarchy"
    property int animationLevel: 2 // 0 none, 1 reduced, 2 full

    readonly property var palettes: ({
        followOmarchy: {
            name: "Follow Omarchy",
            bg0: omarchyBackground,
            bg1: Qt.darker(omarchyBackground, 1.15),
            accent: omarchyForeground,
            gold: "#d4af37",
            saffron: "#e07a2f",
            fg: omarchyForeground,
            fgDim: Qt.rgba(omarchyForeground.r, omarchyForeground.g, omarchyForeground.b, 0.6),
            glow: omarchyForeground
        },
        krishnaBlue: {
            name: "Krishna Blue",
            bg0: "#0b1030",
            bg1: "#161c4a",
            accent: "#4d6fe0",
            gold: "#f2c14e",
            saffron: "#e8813a",
            fg: "#eef0ff",
            fgDim: "#9aa2d6",
            glow: "#6f8bff"
        },
        peacock: {
            name: "Peacock",
            bg0: "#04211d",
            bg1: "#0c3b34",
            accent: "#1fae8e",
            gold: "#e8c34a",
            saffron: "#3fd0c3",
            fg: "#eafff8",
            fgDim: "#8fd9c9",
            glow: "#2be0c0"
        },
        gold: {
            name: "Gold",
            bg0: "#1c1508",
            bg1: "#372711",
            accent: "#d4af37",
            gold: "#ffd777",
            saffron: "#e0952f",
            fg: "#fff6df",
            fgDim: "#cbb27f",
            glow: "#ffce5c"
        },
        monochrome: {
            name: "Monochrome",
            bg0: "#111111",
            bg1: "#1d1d1d",
            accent: "#e8e8e8",
            gold: "#cfcfcf",
            saffron: "#9a9a9a",
            fg: "#f2f2f2",
            fgDim: "#8a8a8a",
            glow: "#ffffff"
        }
    })

    readonly property var active: palettes[paletteName] || palettes.followOmarchy

    // Spring-ish easing curve shared by every pop/close animation.
    readonly property int springDuration: animationLevel === 0 ? 0 : (animationLevel === 1 ? 120 : 320)
    readonly property int easingType: Easing.OutBack
    readonly property real easingOvershoot: animationLevel === 2 ? 1.15 : 1.0
}
