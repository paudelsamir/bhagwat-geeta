pragma Singleton
import QtQuick

// Single source of truth for every user-facing string.
// Keeping this in one file makes future localisation and copy review trivial.
QtObject {
    readonly property string appName: "Bhagwat Geeta"

    // Bar
    readonly property string tooltipReadHint: "Click to open \u2022 Right-click: new verse \u2022 Middle-click: copy \u2022 Scroll: prev/next"
    readonly property string tooltipReadState: "\u2713 Read today"
    readonly property string tooltipUnreadState: "\u25CB Unread \u2014 click the bar to read"
    readonly property string markedRead: "Marked as read"
    readonly property string copied: "Verse copied to clipboard"

    // Tabs
    readonly property string tabToday: "Today"
    readonly property string tabBrowse: "Browse"
    readonly property string tabSaved: "Saved"
    readonly property string tabSettings: "Settings"

    // Today tab
    readonly property string prev: "Previous"
    readonly property string next: "Next"
    readonly property string random: "Random"
    readonly property string save: "Save"
    readonly property string unsave: "Unsave"
    readonly property string copy: "Copy"
    readonly property string markRead: "Mark as read"
    readonly property string markUnread: "Mark as unread"
    readonly property string transliterationLabel: "Transliteration"
    readonly property string sanskritLabel: "Sanskrit"
    readonly property string translationLabel: "Translation"
    readonly property string streakLabel: "Reading streak"
    readonly property string streakDaysLabel: "day streak"
    readonly property string chaptersCompleteLabel: "chapters complete"
    readonly property string versesReadLabel: "verses read"

    // Browse tab
    readonly property string searchPlaceholder: "Search English translations\u2026"
    readonly property string chapterProgress: "verses read"
    readonly property string chapterComplete: "Complete"
    readonly property string noResults: "No verses match your search."
    readonly property string browseOpenToday: "Open in Today"

    // Saved tab
    readonly property string savedEmpty: "Verses you save appear here."
    readonly property string noteLabel: "Note"
    readonly property string exportFavorites: "Export favourites"


    // Settings tab
    readonly property string settingsBarSection: "Bar"
    readonly property string settingsDisplayMode: "Bar content"
    readonly property string settingsIconStyle: "Bar icon"
    readonly property string settingsIconSize: "Icon size"
    readonly property string settingsGlow: "Unread highlight"
    readonly property string settingsVerseSection: "Verse"
    readonly property string settingsChapter: "Chapter"
    readonly property string settingsAppearanceSection: "Appearance"
    readonly property string settingsReminderSection: "Reminder"
    readonly property string settingsDataSection: "Data"
    readonly property string settingsTheme: "Theme"
    readonly property string settingsFontSize: "Font size"
    readonly property string settingsShowDevanagari: "Show Devanagari"
    readonly property string settingsShowTransliteration: "Show transliteration"
    readonly property string settingsAnimation: "Animation level"
    readonly property string settingsTranslator: "Translator"
    readonly property string settingsVerseMode: "Verse mode"
    readonly property string settingsReminder: "Daily reminder"
    readonly property string settingsReminderTime: "Reminder time"
    readonly property string settingsScroll: "Scroll behaviour"
    readonly property string settingsClearHistory: "Clear reading history"
    readonly property string settingsReset: "Reset to defaults"
    readonly property string settingsAbout: "About & licenses"

    readonly property string aboutBody:
        "Geeta Bar bundles verse text and English translations from the " +
        "Bhagavad Gita API (vedicscriptures/bhagavad-gita-api, MIT licensed), " +
        "translations by Shri Purohit Swami and Swami Sivananda. " +
        "Devanagari rendered with Tiro Devanagari Sanskrit / Noto Serif Devanagari (SIL OFL 1.1). "

    readonly property var chapterNames: [
        "Arjuna Vishada Yoga", "Sankhya Yoga", "Karma Yoga", "Jnana Yoga",
        "Karma Vairagya Yoga", "Dhyana Yoga", "Jnana Vijnana Yoga", "Akshara Brahma Yoga",
        "Raja Vidya Yoga", "Vibhuti Yoga", "Vishvarupa Darshana Yoga", "Bhakti Yoga",
        "Kshetra Kshetrajna Vibhaga Yoga", "Gunatraya Vibhaga Yoga", "Purushottama Yoga",
        "Daivasura Sampad Vibhaga Yoga", "Shraddhatraya Vibhaga Yoga", "Moksha Sannyasa Yoga"
    ]
}
