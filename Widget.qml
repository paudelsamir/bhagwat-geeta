import QtQuick
import Quickshell
import qs.Ui
import "components"

// Omarchy bar-widget entry point: a native glyph + verse readout.
//
// Host contract (verified against /usr/share/omarchy/shell):
//   - Root extends qs.Ui Panel, which provides `bar` (PluginBarApi facade),
//     `moduleName`, `settings`, open()/close()/toggle() and `opened`.
//   - WidgetButton (qs.Ui) is the native bar-button surface: hover tracking,
//     tooltip plumbing and click-target registration come free.
//   - bar.showTooltip(target, text) / bar.hideTooltip(target)
//   - bar.run(command) -> bash -lc (shell features like pipes work)
//   - Popup content lives in a KeyboardPanel (own window); the bar window
//     clips oversized children, so the popup must NOT be a bar child.
//
// Perf rule: nothing infinite may animate in the bar. The unread glow is a
// finite loop that replays on verse change; the snippet scroller only runs
// while visible.
Panel {
    id: root

    moduleName: "paudelsamir.bhagwat-geeta"
    ipcTarget: "paudelsamir.bhagwat-geeta"

    implicitWidth: root.bar && root.bar.vertical ? root.bar.barSize : button.implicitWidth
    implicitHeight: root.bar && root.bar.vertical ? root.bar.barSize : button.implicitHeight

    readonly property bool vertical: root.bar ? !!root.bar.vertical : false
    readonly property var liveSettings: settings || ({})

    // ---- Setting accessors (every key adjustable; see Settings tab) ------
    readonly property string displayMode: liveSettings.displayMode || "icon-and-verse"
    // Bar icon, nerd-font style like the rest of the bar. Legacy vector names
    // (peacock/flute/lotus) fall through to the Om glyph.
    readonly property string iconStyle: liveSettings.iconStyle || "om"
    readonly property string glyph: iconStyle === "book" ? "\uf02d"
                                    : iconStyle === "flame" ? "\uf06d"
                                    : iconStyle === "none" ? "" : "\u0950"
    // Nerd-font glyphs are drawn to a baseline grid with bottom-heavy ink,
    // while the Om glyph comes from a top-heavy fallback font — each needs
    // its own nudge to sit on the text line (measured from screenshots).
    readonly property int glyphNudge: (iconStyle === "book" || iconStyle === "flame") ? 0 : 2
    readonly property string fontScale: liveSettings.fontSize || "medium"
    // Booleans round-trip through shell.json and may come back as "true" /
    // "false" strings (the CLI stores raw strings unless --json is passed),
    // so every toggle reads through this normalizer.
    function flag(v, dflt) {
        if (v === undefined || v === null) return dflt
        if (typeof v === "string") return v === "true" || v === "1"
        return !!v
    }

    // "glow" now means a static gold highlight while unread (no animation,
    // so the bar never repaints while idle).
    readonly property bool highlightUnread: flag(liveSettings.glow, true)
    readonly property string translatorKey: liveSettings.translator || "purohit"
    readonly property string verseMode: liveSettings.verseMode || "daily"
    readonly property int verseChapter: parseInt(liveSettings.chapter || "1", 10) || 1

    readonly property int versePx: fontScale === "small" ? 11 : (fontScale === "large" ? 14 : 12)
    readonly property int iconPx: (liveSettings.iconSize || "medium") === "small" ? 12
                                  : ((liveSettings.iconSize || "medium") === "large" ? 18 : 15)
    readonly property bool showRef: !vertical && displayMode !== "icon-only"
    readonly property bool showIcon: glyph !== ""
    // Unread verses read gold; read ones sit in the normal bar foreground.
    readonly property color verseColor: (!readToday && highlightUnread) ? Theme.active.gold
                                        : (root.bar ? root.bar.barForeground : Theme.active.fg)

    // ---- Theme ------------------------------------------------------------
    onLiveSettingsChanged: syncTheme()
    Component.onCompleted: {
        syncTheme()
        // FileView cannot create files under a missing directory; ensure it.
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.config/omarchy/geeta-bar"])
        syncReadState()
        refreshDaily()
    }
    Connections {
        target: root.bar
        function onForegroundChanged() { root.syncTheme() }
        function onBackgroundChanged() { root.syncTheme() }
    }
    function syncTheme() {
        if (root.bar) {
            Theme.omarchyForeground = root.bar.foreground
            Theme.omarchyBackground = root.bar.background
            Theme.omarchyUrgent = root.bar.urgent
        }
        Theme.paletteName = liveSettings.theme || "followOmarchy"
        Theme.animationLevel = (liveSettings.animationLevel === "none") ? 0
                              : (liveSettings.animationLevel === "reduced") ? 1 : 2
    }

    // ---- Current verse state ----------------------------------------------
    property int verseIndex: 0
    readonly property var currentVerse: GitaData.byIndex(verseIndex)
    property bool readToday: false

    // Resolve which verse the bar shows, honouring the verse mode setting:
    // daily (stable rotation), random (stable per-day draw), chapter (daily
    // rotation inside the chosen chapter).
    function resolveIndex() {
        var n = GitaData.verseCount()
        if (!(GitaData.ready && n > 0)) return 0
        if (verseMode === "random") {
            var d = new Date()
            var seed = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate()
            return ((seed * 1103515245 + 12345) & 0x7fffffff) % n
        }
        if (verseMode === "chapter") {
            var list = []
            var verses = GitaData.verses
            for (var i = 0; i < verses.length; i++)
                if (verses[i].chapter === verseChapter) list.push(i)
            if (list.length === 0) return GitaData.dailyIndex()
            return list[Math.floor(Date.now() / 86400000) % list.length]
        }
        return GitaData.dailyIndex()
    }

    function refreshDaily() {
        var next = resolveIndex()
        if (next !== verseIndex) verseIndex = next
        syncReadState()
    }

    function syncReadState() { readToday = Store.isReadToday() }
    onOpenedChanged: if (!opened) syncReadState() // popup may have marked read

    // Dataset loads async via FileView; pick the verse once ready.
    Connections {
        target: GitaData
        function onReadyChanged() { root.refreshDaily() }
    }
    // Re-check at most once a minute for the day to roll over without a full reload.
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.refreshDaily() }

    // ---- Reminder (QML Timer + notify-send; no systemd unit) ---------------
    Timer {
        interval: 60000
        running: root.flag(liveSettings.reminderEnabled, false)
        repeat: true
        onTriggered: {
            var now = new Date()
            var hhmm = String(now.getHours()).padStart(2, "0") + ":" + String(now.getMinutes()).padStart(2, "0")
            if (hhmm === (liveSettings.reminderTime || "07:00") && !root.readToday) {
                var v = root.currentVerse
                if (v && root.bar && root.bar.run) {
                    var body = (v.translations && (v.translations.purohit || v.translations.sivananda)) || ""
                    var safeBody = body.replace(/'/g, "'\\''")
                    root.bar.run("notify-send " +
                        "'Bhagwat Geeta \u2014 " + v.chapter + "." + v.verse + "' " +
                        "'" + safeBody + "'")
                }
            }
        }
    }

    // ---- Bar content: plain glyph + text, like every other widget --------
    // No pill, no background, no border: the bar stays visually consistent.
    // Unread verses highlight gold (static — zero idle repaints); read ones
    // sit in the normal bar foreground.
    WidgetButton {
        id: button
        bar: root.bar
        labelVisible: false
        hasVisualContent: true
        tooltipText: root.tooltipText()
        fixedWidth: rowContent.implicitWidth + 8

        onPressed: function (btn) {
            if (btn === Qt.LeftButton) {
                root.togglePopup()
            } else if (btn === Qt.RightButton) {
                root.verseIndex = GitaData.randomIndex()
            } else if (btn === Qt.MiddleButton) {
                root.copyVerse(root.currentVerse)
            }
        }
        onWheelMoved: function (delta) {
            if (delta > 0)
                root.verseIndex = Math.max(0, root.verseIndex - 1)
            else if (delta < 0)
                root.verseIndex = Math.min(GitaData.verseCount() - 1, root.verseIndex + 1)
        }

        Row {
            id: rowContent
            anchors.centerIn: parent
            spacing: 6

            Text {
                visible: root.showIcon
                anchors.verticalCenter: parent.verticalCenter
                // The Om glyph comes from a fallback font with top-heavy
                // metrics, so it needs a nudge to sit on the text line.
                anchors.verticalCenterOffset: root.glyphNudge
                text: root.glyph
                color: root.verseColor
                font.family: button.fontFamily
                font.pixelSize: root.iconPx
                renderType: Text.NativeRendering
            }

            Text {
                visible: root.showRef
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentVerse ? (root.currentVerse.chapter + "." + root.currentVerse.verse) : "\u2014"
                color: root.verseColor
                font.family: button.fontFamily
                font.pixelSize: root.versePx
                renderType: Text.NativeRendering
            }

        }
    }

    function translationOf(v) {
        if (!v || !v.translations) return ""
        return v.translations[translatorKey] || v.translations.purohit || v.translations.sivananda || ""
    }

    function tooltipText() {
        var v = root.currentVerse
        if (!v || !v.translations) return Strings.appName
        var body = translationOf(v)
        if (body.length > 140) body = body.slice(0, 140).replace(/\s+$/, "") + "\u2026"
        return v.chapter + "." + v.verse + " \u00B7 " + body
    }

    function copyText(text, note) {
        if (!root.bar || !root.bar.run) return
        // Shell-quoted single-arg pipe: never interpolate unescaped text into a command string.
        var escaped = String(text).replace(/'/g, "'\\''")
        root.bar.run("bash -c \"printf '%s' '" + escaped + "' | wl-copy\"")
        if (root.bar.showTooltip) root.bar.showTooltip(button, note || Strings.copied)
    }

    function copyVerse(v) {
        if (!v) return
        var body = v.translations ? (v.translations.purohit || v.translations.sivananda || "") : ""
        copyText(v.sanskrit + "\n" + v.transliteration + "\n" + body
                 + "  (Bhagavad Gita " + v.chapter + "." + v.verse + ")")
    }

    // ---- Popup (KeyboardPanel window anchored to the button) -----------------
    function togglePopup() { root.opened ? root.close() : root.open() }
    function closePopup() { root.close() }

    KeyboardPanel {
        id: pop
        anchorItem: button
        bar: root.bar
        owner: root
        open: root.opened
        contentWidth: pop.fittedContentWidth(340)
        contentHeight: pop.fittedContentHeight(460)

        GeetaPopup {
            id: popup
            anchors.fill: parent
            settings: root.liveSettings
            applySettingFn: root.applySetting
            resetSettingsFn: root.resetSettings
            copyVerseFn: root.copyVerse
            copyTextFn: root.copyText
            openVerseFn: root.openVerse
        }
    }

    function openVerse(ch, vs) {
        var v = GitaData.byChapterVerse(ch, vs)
        if (v) {
            var idx = GitaData.verses.indexOf(v)
            if (idx !== -1) verseIndex = idx
        }
        if (popup) popup.currentTab = "today"
    }

    function applySetting(key, value) {
        // Persist natively via the Omarchy CLI (bar.run -> bash -lc), which
        // writes the widget's inline shell.json entry. The shell then pushes
        // the new `settings` object back into this widget.
        if (root.bar && root.bar.run) {
            var safeKey = String(key).replace(/'/g, "")
            var safeVal = String(value).replace(/'/g, "'\\''")
            // --json keeps booleans/numbers typed in shell.json instead of
            // degrading them to "true"/"false" strings.
            var jsonFlag = (typeof value === "boolean" || typeof value === "number") ? " --json" : ""
            root.bar.run("omarchy bar set '" + root.moduleName + "' '" + safeKey + "' '" + safeVal + "'" + jsonFlag)
        }
        // Update the live in-memory copy immediately so the UI feels instant
        // even before the round-trip above completes.
        var next = Object.assign({}, root.liveSettings)
        next[key] = value
        settings = next
        syncTheme()
    }

    function resetSettings() {
        for (var k in defaultSettings) applySetting(k, defaultSettings[k])
    }

    readonly property var defaultSettings: ({
        displayMode: "icon-only", iconStyle: "book", fontSize: "small",
        iconSize: "small", glow: true,
        translator: "purohit", verseMode: "daily", chapter: 2,
        theme: "peacock", animationLevel: "none",
        reminderEnabled: false, reminderTime: "07:00",
        showDevanagari: true, showTransliteration: false
    })
}
