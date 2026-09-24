import QtQuick
import ".."

Item {
    id: root
    property var openVerseFn: function(ch, vs) {}
    property var copyVerseFn: function(v) {}
    property var settings

    property string searchQuery: ""
    property int selectedChapter: -1 // -1 = chapter list view
    property var selectedVerse: null // {ch, vs} = in-place detail view
    readonly property var detailData: detailVerse()

    // Shell settings may come back as "true"/"false" strings; normalize.
    function isOn(v, dflt) {
        if (v === undefined || v === null) return dflt
        if (typeof v === "string") return v === "true" || v === "1"
        return !!v
    }

    function translatorKey() { return (settings && settings.translator) || "purohit" }
    function detailVerse() {
        if (!selectedVerse) return null
        return GitaData.byChapterVerse(selectedVerse.ch, selectedVerse.vs)
    }
    function detailTranslation(v) {
        if (!v || !v.translations) return ""
        return v.translations[translatorKey()] || v.translations.purohit || v.translations.sivananda || ""
    }
    function clearNav() { selectedChapter = -1; searchQuery = ""; selectedVerse = null }

    function chaptersDone() {
        var n = 0
        var chs = GitaData.chapters
        for (var i = 0; i < chs.length; i++)
            if (chs[i].verseCount > 0 && Store.chapterReadCount(chs[i].chapter) >= chs[i].verseCount) n++
        return n
    }
    function versesReadCount() { return Object.keys(Store.readVerses).length }

    function detailCount() {
        if (!selectedVerse) return 0
        var meta = GitaData.chapterMeta(selectedVerse.ch)
        return meta ? meta.verseCount : 0
    }
    function stepVerse(delta) {
        if (!selectedVerse) return
        var n = detailCount()
        if (n <= 0) return
        var vs = Math.min(n, Math.max(1, selectedVerse.vs + delta))
        if (vs !== selectedVerse.vs) selectedVerse = { ch: selectedVerse.ch, vs: vs }
    }

    Column {
        id: topCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // Search
        Rectangle {
            width: parent.width
            height: 30
            radius: 15
            color: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.06)
            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6
                Text { text: "\uf002"; font.family: "Symbols Nerd Font, sans-serif"; color: Theme.active.fgDim; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 12 }
                TextInput {
                    width: parent.width - 30
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.active.fg
                    font.pixelSize: 12
                    clip: true
                    text: root.searchQuery
                    onTextChanged: root.searchQuery = text
                    Keys.onEscapePressed: { text = ""; root.searchQuery = "" }
                    Text {
                        visible: parent.text.length === 0
                        text: Strings.searchPlaceholder
                        color: Theme.active.fgDim
                        font.pixelSize: 12
                    }
                }
            }
        }

        // Back button when a chapter or search is open (detail has its own
        // floating header below, same slot so the layout never jumps)
        Row {
            visible: root.selectedVerse === null && (root.selectedChapter !== -1 || root.searchQuery.length > 0)
            spacing: 6
            IconButton {
                glyph: "\uf060"
                tooltipText: "Back"
                onClicked: root.clearNav()
            }
        }

        // Floating detail header: back + live chapter/verse indicator.
        // Lives outside the Flickable so it never scrolls away.
        Row {
            visible: root.selectedVerse !== null
            spacing: 8
            IconButton {
                glyph: "\uf060"
                tooltipText: "Back"
                onClicked: root.clearNav()
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.selectedVerse ? ("Ch. " + root.selectedVerse.ch + " \u00B7 " + root.selectedVerse.vs + "/" + root.detailCount()) : ""
                color: Theme.active.gold
                font.pixelSize: 12
                font.bold: true
            }
        }

        // Floating detail actions: pinned under the header, never scroll away.
        Row {
            id: detailActions
            visible: root.selectedVerse !== null
            spacing: 8
            IconButton {
                glyph: "\uf104"
                tooltipText: Strings.prev
                onClicked: root.stepVerse(-1)
            }
            IconButton {
                glyph: "\uf105"
                tooltipText: Strings.next
                onClicked: root.stepVerse(1)
            }
            IconButton {
                glyph: "\uf00c"
                tooltipText: root.detailData && Store.readVerses[root.detailData.chapter + "." + root.detailData.verse] !== undefined ? Strings.markUnread : Strings.markRead
                active: root.detailData ? Store.readVerses[root.detailData.chapter + "." + root.detailData.verse] !== undefined : false
                onClicked: if (root.detailData) Store.toggleRead(root.detailData.chapter, root.detailData.verse)
            }
            IconButton {
                glyph: "\uf0c5"
                tooltipText: Strings.copy
                onClicked: if (root.detailData) root.copyVerseFn(root.detailData)
            }
            IconButton {
                glyph: "\uf004"
                tooltipText: Strings.save
                active: root.detailData ? Store.isFavorite(root.detailData.chapter, root.detailData.verse) : false
                activeColor: Theme.active.saffron
                onClicked: if (root.detailData) Store.toggleFavorite(root.detailData.chapter, root.detailData.verse)
            }
            IconButton {
                glyph: "\uf08e"
                tooltipText: Strings.browseOpenToday
                onClicked: if (root.detailData) root.openVerseFn(root.detailData.chapter, root.detailData.verse)
            }
        }
    }
        Flickable {
            id: chapterFlick
            anchors.top: topCol.bottom
            anchors.topMargin: 8
            anchors.bottom: browseFooter.top
            anchors.bottomMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            contentHeight: listColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: listColumn
                width: parent.width
                spacing: 6

                // In-place verse detail — reading here stays on Browse.
                // Only the "open in Today" action switches tabs.
                Column {
                    visible: root.selectedVerse !== null
                    width: listColumn.width
                    spacing: 10
                    
                    Text {
                        visible: root.detailData !== null
                        text: root.detailData ? (root.detailData.chapter + "." + root.detailData.verse) : ""
                        color: Theme.active.gold
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        visible: root.detailData !== null && root.isOn(settings ? settings.showDevanagari : undefined, true)
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: root.detailData ? root.detailData.sanskrit : ""
                        color: Theme.active.fg
                        font.pixelSize: 14
                        lineHeight: 1.35
                    }
                    Text {
                        visible: root.detailData !== null && root.isOn(settings ? settings.showTransliteration : undefined, true)
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: root.detailData ? root.detailData.transliteration : ""
                        color: Theme.active.fgDim
                        font.pixelSize: 11
                        font.italic: true
                    }
                    Text {
                        visible: root.detailData !== null
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: root.detailTranslation(root.detailData)
                        color: Theme.active.fg
                        font.pixelSize: 12
                        lineHeight: 1.3
                    }
                }

                // Search results
                Repeater {
                    model: root.selectedVerse === null && root.searchQuery.length > 0 ? GitaData.search(root.searchQuery) : []
                    delegate: Rectangle {
                        required property int modelData
                        readonly property var v: GitaData.byIndex(modelData)
                        width: listColumn.width
                        height: 44
                        radius: 8
                        color: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.05)
                        Column {
                            anchors.fill: parent
                            anchors.margins: 6
                            Text { text: v.chapter + "." + v.verse; color: Theme.active.gold; font.pixelSize: 10 }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: (v.translations && (v.translations.purohit || v.translations.sivananda)) || ""
                                color: Theme.active.fg
                                font.pixelSize: 11
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedVerse = { ch: v.chapter, vs: v.verse } }
                    }
                }
                Text {
                    visible: root.selectedVerse === null && root.searchQuery.length > 0 && GitaData.search(root.searchQuery).length === 0
                    text: Strings.noResults
                    color: Theme.active.fgDim
                    font.pixelSize: 12
                }

                // Chapter list
                Repeater {
                    visible: root.selectedVerse === null && root.searchQuery.length === 0 && root.selectedChapter === -1
                    model: root.selectedVerse === null && root.searchQuery.length === 0 && root.selectedChapter === -1 ? GitaData.chapters : []
                    delegate: Rectangle {
                        required property var modelData
                        width: listColumn.width
                        height: 58
                        radius: 10
                        color: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.05)
                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4
                            Row {
                                spacing: 6
                                Text { text: "Ch. " + modelData.chapter; color: Theme.active.gold; font.pixelSize: 11 }
                                Text { text: modelData.name; color: Theme.active.fg; font.pixelSize: 12; font.bold: true }
                                Text {
                                    visible: modelData.verseCount > 0 && Store.chapterReadCount(modelData.chapter) >= modelData.verseCount
                                    text: "\u2713 " + Strings.chapterComplete
                                    color: Theme.active.gold
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                            BarMeter {
                                width: parent.width
                                segments: 10
                                progress: modelData.verseCount > 0 ? Store.chapterReadCount(modelData.chapter) / modelData.verseCount : 0
                                litColor: Theme.active.gold
                            }
                            Text {
                                text: Store.chapterReadCount(modelData.chapter) + "/" + modelData.verseCount + " " + Strings.chapterProgress
                                color: Theme.active.fgDim
                                font.pixelSize: 9
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedChapter = modelData.chapter }
                    }
                }

                // Verse grid for a selected chapter
                Grid {
                    visible: root.selectedVerse === null && root.selectedChapter !== -1
                    columns: 6
                    spacing: 6
                    width: listColumn.width

                    Repeater {
                        model: root.selectedChapter !== -1
                               ? (GitaData.chapterMeta(root.selectedChapter) ? GitaData.chapterMeta(root.selectedChapter).verseCount : 0)
                               : 0
                        delegate: Rectangle {
                            required property int index
                            readonly property int vs: index + 1
                            readonly property bool read: Store.readVerses[root.selectedChapter + "." + vs] !== undefined
                            width: (listColumn.width - 5 * 6) / 6
                            height: width
                            radius: 6
                            color: read ? Qt.rgba(Theme.active.gold.r, Theme.active.gold.g, Theme.active.gold.b, 0.25) : Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.05)
                            border.width: read ? 1 : 0
                            border.color: Theme.active.gold
                            Text {
                                anchors.centerIn: parent
                                text: vs
                                font.pixelSize: 10
                                color: Theme.active.fg
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedVerse = { ch: root.selectedChapter, vs: vs }
                                Keys.onReturnPressed: root.selectedVerse = { ch: root.selectedChapter, vs: vs }
                            }
                        }
                    }
                }
            }
        }
        // Floating progress footer: pinned to the bottom, always visible.
        Column {
            id: browseFooter
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 4
            Row {
                visible: Store.currentStreak() > 0
                spacing: 5
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf06d"
                    font.family: "Symbols Nerd Font, sans-serif"
                    font.pixelSize: 11
                    color: Theme.active.saffron
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Store.currentStreak() + " " + Strings.streakDaysLabel
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.active.fg
                }
            }
            Text {
                visible: GitaData.chapters.length > 0
                text: root.chaptersDone() + "/" + GitaData.chapters.length + " " + Strings.chaptersCompleteLabel
                      + "  \u00B7  " + root.versesReadCount() + " " + Strings.versesReadLabel
                font.pixelSize: 10
                color: Theme.active.fgDim
            }
            ChapterChart {
                width: parent.width
                litColor: Theme.active.gold
                openChapterFn: function(ch) { root.selectedChapter = ch; root.selectedVerse = null; root.searchQuery = "" }
            }
        }
}
