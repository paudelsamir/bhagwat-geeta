import QtQuick
import QtQuick.Shapes

// A minimal five-petal lotus, built from repeated cubic petals rotated
// around a centre point. Used for the Saved tab and empty states.
Item {
    id: root
    property color petalColor: "#e07a2f"
    property color centerColor: "#e8c34a"

    implicitWidth: 24
    implicitHeight: 24

    Repeater {
        model: 5
        delegate: Shape {
            required property int index
            anchors.fill: parent
            rotation: index * 72
            transformOrigin: Item.Center
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Qt.rgba(root.petalColor.r, root.petalColor.g, root.petalColor.b, 0.85)
                strokeColor: "transparent"
                startX: 12; startY: 12
                PathCubic { control1X: 9; control1Y: 9; control2X: 9; control2Y: 3; x: 12; y: 2 }
                PathCubic { control1X: 15; control1Y: 3; control2X: 15; control2Y: 9; x: 12; y: 12 }
            }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.centerColor
            strokeColor: "transparent"
            startX: 12; startY: 10.3
            PathArc { x: 12; y: 13.7; radiusX: 1.7; radiusY: 1.7; direction: PathArc.Clockwise }
            PathArc { x: 12; y: 10.3; radiusX: 1.7; radiusY: 1.7; direction: PathArc.Clockwise }
        }
    }
}
