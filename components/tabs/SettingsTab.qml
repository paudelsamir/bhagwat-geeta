import QtQuick
import ".."

Item {
    id: root
    property var settings          // live settings object (bound back to Omarchy's stored schema where keys overlap)
    property var applySettingFn: function(key, value) {}
    property var resetSettingsFn: function() {}

    // Shell settings may come back as "true"/"false" strings; normalize.
    function isOn(v, dflt) {
        if (v === undefined || v === null) return dflt
        if (typeof v === "string") return v === "true" || v === "1"
        return !!v
    }

    function chapterOptions() {
        var out = []
        var names = Strings.chapterNames
        for (var i = 0; i < 18; i++)
            out.push({ id: String(i + 1), label: (i + 1) + " \u2014 " + (names[i] || "") })
        return out
    }

    function chapterValue() {
        if (settings && settings.chapter !== undefined && settings.chapter !== null
                && String(settings.chapter) !== "")
            return String(settings.chapter)
        return "1"
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 18
            topPadding: 4

            // --- Appearance, with crossfading live preview swatches --------
            Text { text: Strings.settingsAppearanceSection; color: Theme.active.fg; font.pixelSize: 13; font.bold: true }

            Column {
                width: parent.width
                spacing: 8
                Text { text: Strings.settingsTheme; color: Theme.active.fgDim; font.pixelSize: 11 }
                Row {
                    spacing: 8
                    Repeater {
                        model: ["followOmarchy", "krishnaBlue", "peacock", "gold", "monochrome"]
                        delegate: Rectangle {
                            required property string modelData
                            readonly property var pal: Theme.palettes[modelData]
                            width: 54; height: 54
                            radius: 12
                            border.width: Theme.paletteName === modelData ? 2 : 0
                            border.color: pal.gold
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: pal.bg0 }
                                GradientStop { position: 1.0; color: pal.bg1 }
                            }
                            Behavior on border.width { NumberAnimation { duration: 150 } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 14; height: 14; radius: 7
                                color: pal.gold
                            }

                            Text {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: pal.name
                                font.pixelSize: 7
                                color: pal.fgDim
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applySettingFn("theme", modelData)
                            }
                        }
                    }
                }
            }

            SettingsSelectRow {
                label: Strings.settingsAnimation
                value: (settings && settings.animationLevel) || "full"
                options: [ { id: "full", label: "Full" }, { id: "reduced", label: "Reduced" }, { id: "none", label: "None" } ]
                onSelected: (v) => root.applySettingFn("animationLevel", v)
            }

            SettingsDivider {}

            // --- Bar -------------------------------------------------------
            Text { text: Strings.settingsBarSection; color: Theme.active.fg; font.pixelSize: 13; font.bold: true }

            SettingsSelectRow {
                label: Strings.settingsDisplayMode
                value: (settings && settings.displayMode) || "icon-and-verse"
                options: [
                    { id: "icon-only", label: "Icon only" },
                    { id: "icon-and-verse", label: "Icon + verse" }
                ]
                onSelected: (v) => root.applySettingFn("displayMode", v)
            }
            SettingsSelectRow {
                label: Strings.settingsIconStyle
                value: (settings && settings.iconStyle) || "om"
                options: [
                    { id: "om", label: "Om \u0950" },
                    { id: "book", label: "Book" },
                    { id: "flame", label: "Flame" },
                    { id: "none", label: "No icon" }
                ]
                onSelected: (v) => root.applySettingFn("iconStyle", v)
            }
            SettingsSelectRow {
                label: Strings.settingsIconSize
                value: (settings && settings.iconSize) || "medium"
                options: [ { id: "small", label: "Small" }, { id: "medium", label: "Medium" }, { id: "large", label: "Large" } ]
                onSelected: (v) => root.applySettingFn("iconSize", v)
            }
            SettingsSelectRow {
                label: Strings.settingsFontSize
                value: (settings && settings.fontSize) || "medium"
                options: [ { id: "small", label: "Small" }, { id: "medium", label: "Medium" }, { id: "large", label: "Large" } ]
                onSelected: (v) => root.applySettingFn("fontSize", v)
            }
            SettingsToggleRow {
                label: Strings.settingsGlow
                checked: root.isOn(settings ? settings.glow : undefined, true)
                onToggled: (v) => root.applySettingFn("glow", v)
            }

            SettingsDivider {}

            // --- Verse -----------------------------------------------------
            Text { text: Strings.settingsVerseSection; color: Theme.active.fg; font.pixelSize: 13; font.bold: true }

            SettingsSelectRow {
                label: Strings.settingsVerseMode
                value: (settings && settings.verseMode) || "daily"
                options: [
                    { id: "daily", label: "Daily rotation" },
                    { id: "random", label: "Random daily" },
                    { id: "chapter", label: "Chapter focus" }
                ]
                onSelected: (v) => root.applySettingFn("verseMode", v)
            }
            SettingsSelectRow {
                visible: (settings && settings.verseMode) === "chapter"
                label: Strings.settingsChapter
                value: root.chapterValue()
                options: root.chapterOptions()
                onSelected: (v) => root.applySettingFn("chapter", parseInt(v, 10))
            }
            SettingsSelectRow {
                label: Strings.settingsTranslator
                value: (settings && settings.translator) || "purohit"
                options: [ { id: "purohit", label: "Shri Purohit Swami" }, { id: "sivananda", label: "Swami Sivananda" } ]
                onSelected: (v) => root.applySettingFn("translator", v)
            }
            SettingsToggleRow {
                label: Strings.settingsShowDevanagari
                checked: root.isOn(settings ? settings.showDevanagari : undefined, true)
                onToggled: (v) => root.applySettingFn("showDevanagari", v)
            }
            SettingsToggleRow {
                label: Strings.settingsShowTransliteration
                checked: root.isOn(settings ? settings.showTransliteration : undefined, true)
                onToggled: (v) => root.applySettingFn("showTransliteration", v)
            }

            SettingsDivider {}


            // --- Reminder ----------------------------------------------------
            Text { text: Strings.settingsReminderSection; color: Theme.active.fg; font.pixelSize: 13; font.bold: true }

            SettingsToggleRow {
                label: Strings.settingsReminder
                checked: root.isOn(settings ? settings.reminderEnabled : undefined, false)
                onToggled: (v) => root.applySettingFn("reminderEnabled", v)
            }

            Row {
                visible: root.isOn(settings ? settings.reminderEnabled : undefined, false)
                spacing: 8
                Text { text: Strings.settingsReminderTime; color: Theme.active.fgDim; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    width: 70; height: 26; radius: 8
                    color: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.06)
                    TextInput {
                        anchors.centerIn: parent
                        text: (settings && settings.reminderTime) || "07:00"
                        color: Theme.active.fg
                        font.pixelSize: 12
                        validator: RegularExpressionValidator { regularExpression: /^([01]\d|2[0-3]):[0-5]\d$/ }
                        onEditingFinished: root.applySettingFn("reminderTime", text)
                    }
                }
            }

            SettingsDivider {}

            // --- Data ------------------------------------------------------
            Text { text: Strings.settingsDataSection; color: Theme.active.fg; font.pixelSize: 13; font.bold: true }

            Row {
                spacing: 10
                Rectangle {
                    width: dangerLabel.implicitWidth + 20; height: 28; radius: 8
                    color: Qt.rgba(Theme.active.saffron.r, Theme.active.saffron.g, Theme.active.saffron.b, 0.16)
                    Text { id: dangerLabel; anchors.centerIn: parent; text: Strings.settingsClearHistory; color: Theme.active.saffron; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.clearHistory() }
                }
                Rectangle {
                    width: resetLabel.implicitWidth + 20; height: 28; radius: 8
                    color: Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.06)
                    Text { id: resetLabel; anchors.centerIn: parent; text: Strings.settingsReset; color: Theme.active.fg; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.resetSettingsFn() }
                }
            }

            SettingsDivider {}

            // --- About -----------------------------------------------------
            Column {
                width: parent.width
                spacing: 6
                Row {
                    spacing: 8
                    Text {
                        text: "\u0950"
                        font.pixelSize: 16
                        color: Theme.active.gold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text { text: Strings.settingsAbout; color: Theme.active.fg; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: Strings.aboutBody
                    color: Theme.active.fgDim
                    font.pixelSize: 10
                }
            }

            Item { width: 1; height: 10 }
        }
    }
}
