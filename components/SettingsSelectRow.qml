import QtQuick

Column {
    id: root
    property string label: ""
    property string value: ""
    property var options: [] // [{ id, label }]
    signal selected(string id)

    width: parent ? parent.width : 200
    spacing: 6

    Text { text: root.label; color: Theme.active.fgDim; font.pixelSize: 11 }

    Flow {
        width: root.width
        spacing: 6
        Repeater {
            model: root.options
            delegate: Rectangle {
                required property var modelData
                readonly property bool isCurrent: modelData.id === root.value
                radius: 8
                height: 24
                width: optLabel.implicitWidth + 16
                color: isCurrent ? Theme.active.accent : Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.06)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    id: optLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    font.pixelSize: 10
                    color: isCurrent ? Theme.active.bg0 : Theme.active.fgDim
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(modelData.id)
                }
            }
        }
    }
}
