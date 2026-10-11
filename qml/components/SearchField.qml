pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// a material 3 search bar: a full pill with a leading magnifier and a clear
// button once there is something to clear.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search"
    signal accepted()

    function focusField() {
        input.forceActiveFocus()
        input.selectAll()
    }

    implicitWidth: 260
    implicitHeight: 40
    radius: height / 2
    color: input.activeFocus ? Appearance.colors.surfaceContainerHighest : Appearance.colors.surfaceContainerHigh
    border.width: input.activeFocus ? 2 : 0
    border.color: Appearance.colors.primary

    Behavior on color {
        ElementMoveFastColor {}
    }

    MaterialSymbol {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: "search"
        iconSize: 20
        color: Appearance.colors.onSurfaceVariant
    }

    TextInput {
        id: input
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: clear.visible ? clear.left : parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        selectByMouse: true
        color: Appearance.colors.onSurface
        selectionColor: Appearance.colors.primary
        selectedTextColor: Appearance.colors.onPrimary
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSize.small
        onAccepted: root.accepted()
        // escape belongs to the field while it is typed in, before the
        // window's escape takes it back a page
        Keys.onShortcutOverride: (event) => event.accepted = event.key === Qt.Key_Escape
        Keys.onEscapePressed: {
            if (text.length > 0) {
                text = ""
            } else {
                focus = false
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            Reveal.shown: input.text.length === 0
            text: root.placeholder
            color: Appearance.colors.onSurfaceVariant
            font.pixelSize: Appearance.fontSize.small
        }
    }

    IconButton {
        id: clear
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        Reveal.shown: input.text.length > 0
        symbol: "close"
        size: 32
        iconSize: 18
        onClicked: {
            input.text = ""
            input.forceActiveFocus()
        }
    }
}
