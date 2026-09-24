import QtQuick

Item {
    id: root
    signal clicked()
    property string glyph: "\uf00c" // Nerd Font codepoint, caller supplies
    // Theme-following defaults: readable on dark and light palettes alike.
    property color fg: Theme.active.fg
    property color bg: Qt.rgba(fg.r, fg.g, fg.b, 0.06)
    property color bgHover: Qt.rgba(fg.r, fg.g, fg.b, 0.14)
    property bool active: false
    property color activeColor: "#d4af37"
    property string tooltipText: ""

    implicitWidth: 30
    implicitHeight: 30

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: height / 2
        color: mouse.containsMouse ? root.bgHover : root.bg
        border.width: root.active ? 1.4 : 0
        border.color: root.activeColor

        Behavior on color { ColorAnimation { duration: 120 } }

        // Discrete input feedback — a Behavior, not a looping animation.
        scale: mouse.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: "Symbols Nerd Font, sans-serif"
        font.pixelSize: 14
        color: root.active ? root.activeColor : root.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
