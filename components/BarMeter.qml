import QtQuick

// Segmented progress meter: a row of small rounded blocks, `filled` of them
// lit. Used for chapter progress in Browse.
Item {
    id: root

    property int segments: 10
    property real progress: 0 // 0..1
    property color litColor: "#d4af37"
    property color dimColor: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b, 0.14)
    property real segmentSpacing: 2

    implicitHeight: 6

    readonly property int filled: Math.round(progress * segments)

    Row {
        anchors.fill: parent
        spacing: root.segmentSpacing

        Repeater {
            model: root.segments
            delegate: Rectangle {
                required property int index
                width: (root.width - (root.segments - 1) * root.segmentSpacing) / root.segments
                height: root.height
                radius: 2
                color: index < root.filled ? root.litColor : root.dimColor

                Behavior on color {
                    ColorAnimation { duration: 200; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
