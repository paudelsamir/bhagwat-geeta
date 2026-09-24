import QtQuick
import ".."

Item {
    id: root
    property var copyTextFn: function(t) {}
    property var settings

    function translatorKey() { return (settings && settings.translator) || "purohit" }
    function cardTranslation(v) {
        if (!v || !v.translations) return ""
        return v.translations[translatorKey()] || v.translations.purohit || v.translations.sivananda || ""
    }

    readonly property var keys: Object.keys(Store.favorites)

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 10

            Row {
                width: parent.width
                Item { width: parent.width - 30; height: 1 }
                IconButton {
                    glyph: "\uf56e"
                    tooltipText: Strings.exportFavorites
                    onClicked: root.copyTextFn(Store.exportFavoritesJson())
                }
            }

            Column {
                visible: root.keys.length === 0
                width: parent.width
                spacing: 4
                Lotus { anchors.horizontalCenter: parent.horizontalCenter; petalColor: Theme.active.saffron }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Strings.savedEmpty
                    color: Theme.active.fgDim
                    font.pixelSize: 12
                }
            }

            Repeater {
                model: root.keys
                delegate: Rectangle {
                    required property string modelData
                    readonly property var parts: modelData.split(".")
                    readonly property var v: GitaData.byChapterVerse(parseInt(parts[0]), parseInt(parts[1]))
                    readonly property var fav: Store.favorites[modelData]

                    width: col.width
                    // Size to content: the inner column's implicit height.
                    // (Never derive from the TextEdit's height — it fills its
                    // box, so that binding would loop and collapse.)
                    height: cardCol.implicitHeight + 20
                    radius: 10
                    color: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.05)

                    Column {
                        id: cardCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        spacing: 6

                        Row {
                            width: parent.width
                            Text {
                                text: v ? (v.chapter + "." + v.verse) : modelData
                                color: Theme.active.gold
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { width: parent.width - 60; height: 1 }
                            IconButton {
                                glyph: "\uf2ed"
                                tooltipText: Strings.unsave
                                implicitWidth: 24; implicitHeight: 24
                                onClicked: v && Store.toggleFavorite(v.chapter, v.verse)
                            }
                        }

                        Text {
                            width: parent.width
                            wrapMode: Text.Wrap
                            font.pixelSize: 12
                            color: Theme.active.fg
                            text: root.cardTranslation(v)
                        }

                        Text { text: Strings.noteLabel; color: Theme.active.fgDim; font.pixelSize: 10 }

                        Rectangle {
                            width: parent.width
                            // Grow with the text, fixed floor — never bound to
                            // the TextEdit that fills this box.
                            height: Math.max(56, noteField.contentHeight + 12)
                            radius: 6
                            color: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.2)
                            TextEdit {
                                id: noteField
                                anchors.fill: parent
                                anchors.margins: 6
                                wrapMode: Text.Wrap
                                font.pixelSize: 11
                                color: Theme.active.fg
                                // Local draft: the Store object is replaced on
                                // every keystroke-save elsewhere, so binding
                                // text straight to it would wipe typing.
                                property string draft: ""
                                Component.onCompleted: draft = fav ? fav.note : ""
                                text: draft
                                onTextChanged: draft = text
                                onEditingFinished: { if (v) Store.setNote(v.chapter, v.verse, draft) }
                            }
                        }
                    }
                }
            }
        }
    }
}
