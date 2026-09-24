import QtQuick

// A lightweight "dot matrix" label: a plain Text element rendered with a
// monospace label with slight letter-spacing. Cheap and theme-aware.
Text {
    id: root

    property color dotColor: "#e6e6e6"
    property real dim: 1.0 // 0..1 brightness multiplier, for the "unlit" look

    color: Qt.rgba(dotColor.r, dotColor.g, dotColor.b, dim)
    font.family: "JetBrains Mono, Iosevka, monospace"
    font.letterSpacing: 1
    renderType: Text.NativeRendering
    antialiasing: true

    Behavior on color {
        enabled: dim !== undefined
        ColorAnimation { duration: 150 }
    }
}
