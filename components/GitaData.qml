pragma Singleton
import QtQuick
import Quickshell.Io

// Loads the bundled, offline dataset once and exposes lookup helpers.
// FileView is Quickshell.Io's file facade: `path` may be a resolved file URL,
// `text()` returns content, `onLoaded`/`onLoadFailed` report the outcome.
// Both files ship with the plugin under data/, so reads always succeed
// after install; writes never happen here (state lives in Store).
QtObject {
    id: gitaData

    readonly property url versesUrl: Qt.resolvedUrl("../data/gita.json")
    readonly property url chaptersUrl: Qt.resolvedUrl("../data/chapters.json")

    property var verses: []          // flat array, index = position in file (NOT chapter/verse)
    property var chapters: []        // 18 entries: { chapter, name, meaning, summary, verseCount }
    property var _byKey: ({})        // "ch.vs" -> verse object
    property bool ready: false
    property string loadError: ""

    property FileView _versesFile: FileView {
        path: gitaData.versesUrl
        onLoaded: {
            try {
                gitaData.verses = JSON.parse(text())
                gitaData._reindex()
            } catch (e) {
                gitaData.loadError = "Failed to parse gita.json: " + e
            }
            gitaData._maybeReady()
        }
        onLoadFailed: (error) => {
            gitaData.loadError = "Could not read gita.json: " + error
            gitaData._maybeReady()
        }
    }

    property FileView _chaptersFile: FileView {
        path: gitaData.chaptersUrl
        onLoaded: {
            try {
                gitaData.chapters = JSON.parse(text())
            } catch (e) {
                gitaData.loadError = "Failed to parse chapters.json: " + e
            }
            gitaData._maybeReady()
        }
        onLoadFailed: (error) => {
            gitaData.loadError = "Could not read chapters.json: " + error
            gitaData._maybeReady()
        }
    }

    property int _loadedCount: 0
    function _maybeReady() {
        gitaData._loadedCount += 1
        if (gitaData._loadedCount >= 2)
            gitaData.ready = true
    }

    function _reindex() {
        var map = {}
        for (var i = 0; i < verses.length; i++) {
            var v = verses[i]
            map[v.chapter + "." + v.verse] = v
        }
        _byKey = map
    }

    function verseCount() {
        return verses.length
    }

    function byIndex(i) {
        if (i < 0 || i >= verses.length) return null
        return verses[i]
    }

    function byChapterVerse(ch, vs) {
        return _byKey[ch + "." + vs] || null
    }

    function chapterMeta(ch) {
        for (var i = 0; i < chapters.length; i++)
            if (chapters[i].chapter === ch) return chapters[i]
        return null
    }

    // Sequential "one per day" index derived from the epoch day number so it
    // is stable across restarts without persisting a running counter.
    function dailyIndex() {
        if (verses.length === 0) return 0
        var epochDay = Math.floor(Date.now() / 86400000)
        return epochDay % verses.length
    }

    function randomIndex() {
        if (verses.length === 0) return 0
        return Math.floor(Math.random() * verses.length)
    }

    function search(query) {
        query = (query || "").toLowerCase().trim()
        if (query.length === 0) return []
        var out = []
        for (var i = 0; i < verses.length; i++) {
            var v = verses[i]
            var hay = ((v.translations && v.translations.purohit) || "") + " " +
                      ((v.translations && v.translations.sivananda) || "")
            if (hay.toLowerCase().indexOf(query) !== -1) {
                out.push(i)
                if (out.length >= 100) break
            }
        }
        return out
    }
}
