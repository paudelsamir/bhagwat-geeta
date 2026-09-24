import QtQuick
import ".."

Item {
    id: root

    property var settings // ref to the widget's live settings object
    property var copyVerseFn: function(v) {} // injected by GeetaPopup -> Widget.qml copyVerse
    property int verseIndex: 0
    readonly property var verse: GitaData.byIndex(verseIndex)
    readonly property var chapMeta: verse ? GitaData.chapterMeta(verse.chapter) : null
    property string translator: (settings && settings.translator) || "purohit"

    // Shell settings may come back as "true"/"false" strings; normalize.
    function isOn(v, dflt) {
        if (v === undefined || v === null) return dflt
        if (typeof v === "string") return v === "true" || v === "1"
        return !!v
    }

    // Dataset loads async; sync to the daily verse once ready.
    Connections {
        target: GitaData
        function onReadyChanged() {
            if (GitaData.ready && GitaData.verseCount() > 0) root.verseIndex = GitaData.dailyIndex()
        }
    }
    Component.onCompleted: {
        if (GitaData.ready && GitaData.verseCount() > 0) verseIndex = GitaData.dailyIndex()
    }

    function currentTranslation() {
        if (!verse || !verse.translations) return ""
        return verse.translations[translator] || verse.translations.purohit || verse.translations.sivananda || ""
    }

    function next() { verseIndex = Math.min(verseIndex + 1, GitaData.verseCount() - 1) }
    function prev() { verseIndex = Math.max(verseIndex - 1, 0) }
    function randomVerse() { verseIndex = GitaData.randomIndex() }

    // Floating actions: pinned below the scroll area, always visible.
    Row {
        id: actionBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        spacing: 8
        IconButton { glyph: "\uf104"; tooltipText: Strings.prev; onClicked: root.prev() }
        IconButton { glyph: "\uf105"; tooltipText: Strings.next; onClicked: root.next() }
        IconButton {
            glyph: "\uf00c"
            tooltipText: root.verse && Store.readVerses[root.verse.chapter + "." + root.verse.verse] !== undefined ? Strings.markUnread : Strings.markRead
            active: root.verse ? Store.readVerses[root.verse.chapter + "." + root.verse.verse] !== undefined : false
            onClicked: if (root.verse) Store.toggleRead(root.verse.chapter, root.verse.verse)
        }
        IconButton { glyph: "\uf074"; tooltipText: Strings.random; onClicked: root.randomVerse() }
        IconButton {
            glyph: "\uf0c5"
            tooltipText: Strings.copy
            onClicked: if (root.verse) root.copyVerseFn(root.verse)
        }
        IconButton {
            glyph: "\uf004"
            tooltipText: Strings.save
            active: root.verse ? Store.isFavorite(root.verse.chapter, root.verse.verse) : false
            activeColor: Theme.active.saffron
            onClicked: if (root.verse) Store.toggleFavorite(root.verse.chapter, root.verse.verse)
        }
    }

    Flickable {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height - actionBar.height - 10
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 14
            topPadding: 6

            // Chapter chip + streak
            Row {
                width: parent.width
                spacing: 10
                Rectangle {
                    radius: 10
                    color: Qt.rgba(Theme.active.gold.r, Theme.active.gold.g, Theme.active.gold.b, 0.14)
                    height: 26
                    width: chapChipText.implicitWidth + 20
                    Text {
                        id: chapChipText
                        anchors.centerIn: parent
                        color: Theme.active.gold
                        font.pixelSize: 11
                        text: root.chapMeta ? ("Ch. " + root.verse.chapter + " \u2022 " + root.chapMeta.name) : ""
                    }
                }
            }

            // Devanagari — plain Text, NOT PixelText: letter-spacing would
            // break conjunct shaping in complex-script rendering.
            Text {
                width: parent.width
                visible: root.isOn(settings ? settings.showDevanagari : undefined, true)
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.family: "Tiro Devanagari Sanskrit, Noto Serif Devanagari, serif"
                font.pixelSize: 22
                color: Theme.active.fg
                text: root.verse ? root.verse.sanskrit : ""
            }

            // Transliteration
            Text {
                width: parent.width
                visible: root.isOn(settings ? settings.showTransliteration : undefined, true)
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.italic: true
                font.pixelSize: 12
                color: Theme.active.fgDim
                text: root.verse ? root.verse.transliteration : ""
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.08) }

            // Translation + translator switcher
            Column {
                width: parent.width
                spacing: 8

                Row {
                    spacing: 6
                    Repeater {
                        model: [ { id: "purohit", label: "Purohit" }, { id: "sivananda", label: "Sivananda" } ]
                        delegate: Rectangle {
                            required property var modelData
                            radius: 8
                            height: 22
                            width: tLabel.implicitWidth + 16
                            color: root.translator === modelData.id
                                   ? Theme.active.accent
                                   : Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.06)
                            Text {
                                id: tLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 10
                                color: root.translator === modelData.id ? Theme.active.bg0 : Theme.active.fgDim
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.translator = modelData.id
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: 14
                    lineHeight: 1.3
                    color: Theme.active.fg
                    text: root.currentTranslation()
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.08) }



            Item { width: 1; height: 8 }
        }
    }
}
