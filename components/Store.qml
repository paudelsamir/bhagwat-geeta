pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User state that is NOT part of Omarchy's native settings form: favourites,
// per-verse notes and the read-streak calendar.
//
// Per the plugin docs you described, widget *settings* can live inline in
// shell.json (via `omarchy bar set`), but arbitrary app *state* like this
// needs a file of our own. We use the documented fallback path:
//   ~/.config/omarchy/geeta-bar/settings.json
// If third-party plugins are actually sandboxed to a different writable
// directory, change `statePath` below — nothing else references the path.
QtObject {
    id: store

    readonly property string statePath: Quickshell.env("HOME") + "/.config/omarchy/geeta-bar/settings.json"

    property var favorites: ({})     // "ch.vs" -> { note: string, savedAt: number }
    property var readDays: ({})      // "YYYY-MM-DD" -> true
    property var readVerses: ({})    // "ch.vs" -> true (for Browse progress meters)
    property bool loaded: false

    property FileView _file: FileView {
        path: store.statePath
        printErrors: false
        // Plugins can't run install hooks; if the file doesn't exist yet we
        // just start from empty state and create it on first write.
        onLoaded: store._applyLoaded(text())
        onLoadFailed: (error) => { store.loaded = true }
    }

    function _applyLoaded(text) {
        try {
            var obj = JSON.parse(text)
            favorites = obj.favorites || {}
            readDays = obj.readDays || {}
            readVerses = obj.readVerses || {}
        } catch (e) {
            // corrupt or empty file — start fresh rather than crash the widget
        }
        loaded = true
    }

    function _persist() {
        var payload = {
            favorites: favorites,
            readDays: readDays,
            readVerses: readVerses
        }
        _file.setText(JSON.stringify(payload, null, 2))
    }

    function isFavorite(ch, vs) {
        return !!favorites[ch + "." + vs]
    }

    function toggleFavorite(ch, vs) {
        var key = ch + "." + vs
        var next = Object.assign({}, favorites)
        if (next[key]) delete next[key]
        else next[key] = { note: "", savedAt: Date.now() }
        favorites = next
        _persist()
    }

    function setNote(ch, vs, note) {
        var key = ch + "." + vs
        if (!favorites[key]) return
        var next = Object.assign({}, favorites)
        next[key] = { note: note, savedAt: next[key].savedAt }
        favorites = next
        _persist()
    }

    function dateKey(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0")
    }

    // Toggle a verse read/unread with the same call. Values carry the read
    // date going forward, so unmarking can truthfully unlight today when
    // nothing else was read today (legacy `true` entries count as read but
    // undated, so they never hold a day lit by themselves).
    function toggleRead(ch, vs) {
        var key = ch + "." + vs
        var nextV = Object.assign({}, readVerses)
        if (nextV[key]) delete nextV[key]
        else nextV[key] = dateKey(new Date())
        readVerses = nextV
        var today = dateKey(new Date())
        var anyToday = false
        for (var k in nextV)
            if (nextV[k] === today) { anyToday = true; break }
        var nextD = Object.assign({}, readDays)
        if (anyToday) nextD[today] = true
        else delete nextD[today]
        readDays = nextD
        _persist()
    }

    function isReadToday() {
        return !!readDays[dateKey(new Date())]
    }

    // Consecutive days with reads, ending today (or yesterday if today is
    // still unread) — the "X-day streak".
    function currentStreak() {
        var d = new Date()
        if (!readDays[dateKey(d)]) {
            d.setDate(d.getDate() - 1)
            if (!readDays[dateKey(d)]) return 0
        }
        var n = 0
        while (readDays[dateKey(d)]) {
            n++
            d.setDate(d.getDate() - 1)
        }
        return n
    }

    function chapterReadCount(ch) {
        var n = 0
        for (var key in readVerses)
            if (key.indexOf(ch + ".") === 0) n++
        return n
    }

    function clearHistory() {
        readDays = {}
        readVerses = {}
        _persist()
    }

    function exportFavoritesJson() {
        return JSON.stringify(favorites, null, 2)
    }
}
