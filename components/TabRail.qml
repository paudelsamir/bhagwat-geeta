import QtQuick

Item {
    id: root
    property var tabs: []          // [{ id, label, glyph }]
    property string currentId: tabs.length ? tabs[0].id : ""
    property color fg: Theme.active.fg
    property color accent: "#d4af37"
    signal tabSelected(string id)

    implicitHeight: 46

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.18)
        radius: 14
    }

    Row {
        anchors.fill: parent
        anchors.margins: 4

        Repeater {
            model: root.tabs
            delegate: Item {
                required property var modelData
                readonly property bool isCurrent: modelData.id === root.currentId
                width: root.width / root.tabs.length
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 10
                    color: isCurrent ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16) : "transparent"
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.glyph
                        font.family: "Symbols Nerd Font, sans-serif"
                        font.pixelSize: 15
                        color: isCurrent ? root.accent : root.fg
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        font.pixelSize: 10
                        color: isCurrent ? root.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.65)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tabSelected(modelData.id)
                }
            }
        }
    }
}
