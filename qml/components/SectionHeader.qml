pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// a shelf's heading: a symbol on a shape, the title drawn round, and a
// squiggle running on to "See All". hovering the heading turns the shape.
Item {
    id: root

    property string title
    property string symbol
    property string iconShape: "cookie9"
    property bool showsSeeAll: false
    signal seeAll()

    implicitHeight: 40
    implicitWidth: titleText.x + titleText.implicitWidth

    HoverHandler {
        id: hover
    }

    ShapeIcon {
        id: badge
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.symbol.length > 0
        size: 34
        iconSize: 18
        shape: root.iconShape
        symbol: root.symbol
        hovered: hover.hovered
    }

    TitleText {
        id: titleText
        x: badge.visible ? badge.width + 12 : 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        font.pixelSize: Appearance.fontSize.title
    }

    WavyLine {
        anchors.left: titleText.right
        anchors.leftMargin: 16
        anchors.right: seeAll.visible ? seeAll.left : parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        height: 8
        visible: width > 24
        color: Appearance.colors.outlineVariant
    }

    TextButton {
        id: seeAll
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showsSeeAll
        variant: TextButton.Tonal
        symbol: "arrow_forward"
        text: "See All"
        onClicked: root.seeAll()
    }
}
