import QtQuick

Row {
    id: root
    property string label: ""
    property bool checked: false
    signal toggled(bool value)

    width: parent ? parent.width : 200
    height: 26
    spacing: 10

    Text {
        text: root.label
        color: Theme.active.fg
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 50
    }

    Rectangle {
        width: 38; height: 20; radius: 10
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Theme.active.accent : Qt.rgba(Theme.active.fg.r, Theme.active.fg.g, Theme.active.fg.b,0.14)
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 16; height: 16; radius: 8
            y: 2
            x: root.checked ? parent.width - width - 2 : 2
            color: "#ffffff"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }
}
