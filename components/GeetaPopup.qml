import QtQuick
import "./tabs"

// The popup's content. Widget.qml is expected to host this inside whatever
// PopupWindow / bar.requestPopout(owner) surface Omarchy provides, sized and
// anchored per the bar position (see Widget.qml for the anchor logic).
Item {
    id: root

    property var settings
    property var applySettingFn: function(key, value) {}
    property var resetSettingsFn: function() {}
    property var copyVerseFn: function(v) {}
    property var copyTextFn: function(t) {}
    property var openVerseFn: function(ch, vs) {}

    implicitWidth: 340
    implicitHeight: 460

    readonly property var tabModel: [
        { id: "today",    label: Strings.tabToday,    glyph: "\uf073" },
        { id: "browse",   label: Strings.tabBrowse,   glyph: "\uf002" },
        { id: "saved",    label: Strings.tabSaved,    glyph: "\uf004" },
        { id: "settings", label: Strings.tabSettings, glyph: "\uf013" }
    ]
    property string currentTab: "today"

    // Spring-in on creation. Widget.qml is responsible for actually
    // instantiating/destroying this per bar.requestPopout; we just animate
    // our own scale/opacity once we exist.
    scale: 0.9
    opacity: 0
    Component.onCompleted: openAnim.start()

    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: root
            property: "scale"
            from: 0.9; to: 1.0
            duration: Theme.springDuration
            easing.type: Theme.easingType
            easing.overshoot: Theme.easingOvershoot
        }
        NumberAnimation {
            target: root
            property: "opacity"
            from: 0; to: 1
            duration: Math.max(Theme.springDuration - 100, 80)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Theme.active.bg1 }
            GradientStop { position: 1.0; color: Theme.active.bg0 }
        }
        border.width: 1
        border.color: Qt.rgba(Theme.active.gold.r, Theme.active.gold.g, Theme.active.gold.b, 0.25)

        // Faint Om watermark, purely decorative.
        Text {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 6
            text: "\u0950"
            font.pixelSize: 64
            color: Qt.rgba(Theme.active.gold.r, Theme.active.gold.g, Theme.active.gold.b, 0.12)
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 16

            Item {
                width: parent.width
                height: 20
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Strings.appName
                    color: Theme.active.fg
                    font.pixelSize: 15
                    font.bold: true
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u0950"
                    font.pixelSize: 18
                    color: Theme.active.gold
                }
            }

            // Tab content — a Loader per tab keeps each tab lazily built and
            // makes the crossfade below trivial.
            Item {
                width: parent.width
                // Header (20) + two 16px gaps + rail (46) = 98 reserved, so
                // the rail and the action rows inside the tabs sit low with
                // breathing room instead of crowding the bottom edge.
                height: Math.max(120, parent.height - 20 - 46 - 16 * 2)

                Repeater {
                    model: root.tabModel
                    delegate: Loader {
                        required property var modelData
                        anchors.fill: parent
                        active: true
                        visible: modelData.id === root.currentTab
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.springDuration / 2 } }

                        sourceComponent: {
                            switch (modelData.id) {
                                case "today": return todayComp
                                case "browse": return browseComp
                                case "saved": return savedComp
                                case "settings": return settingsComp
                            }
                            return null
                        }
                    }
                }
            }

            TabRail {
                width: parent.width
                tabs: root.tabModel
                currentId: root.currentTab
                fg: Theme.active.fg
                accent: Theme.active.gold
                onTabSelected: (id) => root.currentTab = id
            }
        }
    }

    Component { id: todayComp; TodayTab { settings: root.settings; copyVerseFn: root.copyVerseFn } }
    Component { id: browseComp; BrowseTab { openVerseFn: root.openVerseFn; copyVerseFn: root.copyVerseFn; settings: root.settings } }
    Component { id: savedComp; SavedTab { copyTextFn: root.copyTextFn; settings: root.settings } }
    Component {
        id: settingsComp
        SettingsTab {
            settings: root.settings
            applySettingFn: root.applySettingFn
            resetSettingsFn: root.resetSettingsFn
        }
    }
}
