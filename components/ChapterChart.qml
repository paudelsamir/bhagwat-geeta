import QtQuick

// The 18 chapters as a two-row countdown grid: one box per chapter, gold
// tick when complete, dim otherwise with a faint fill by progress.
// Clicking a box opens that chapter. Fully static — no animation.
Item {
    id: root

    property color litColor: "#d4af37"
    property color dimColor: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b, 0.10)
    property var openChapterFn: function(ch) {}
    property real gap: 5
    property real maxCell: 20

    readonly property int cols: 9
    readonly property real cell: Math.max(0, Math.min(maxCell, (width - (cols - 1) * gap) / cols))
    implicitHeight: 2 * cell + gap

    Repeater {
        model: GitaData.chapters
        delegate: Item {
            required property var modelData
            required property int index
            readonly property int col: index % root.cols
            readonly property int row: Math.floor(index / root.cols)
            readonly property real progress: modelData.verseCount > 0
                ? Math.min(1, Store.chapterReadCount(modelData.chapter) / modelData.verseCount) : 0
            readonly property bool done: modelData.verseCount > 0 && progress >= 1

            x: col * (root.cell + root.gap)
            y: row * (root.cell + root.gap)
            width: root.cell
            height: root.cell

            Rectangle {
                anchors.fill: parent
                radius: 7
                color: done ? Qt.rgba(root.litColor.r, root.litColor.g, root.litColor.b, 0.22)
                            : Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b, 0.04 + 0.08 * progress)
                border.width: done ? 1.4 : 1
                border.color: done ? root.litColor : Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b, 0.14)

                Text {
                    anchors.centerIn: parent
                    text: modelData.chapter + (done ? "\n\u2713" : "")
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: done ? 9 : 11
                    font.bold: done
                    color: done ? root.litColor : Theme.active.fgDim
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openChapterFn(modelData.chapter)
                }
            }
        }
    }
}
