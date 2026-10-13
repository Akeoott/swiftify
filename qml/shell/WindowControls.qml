pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// minimise, maximise and close, for compositors that do not draw their own,
// each on a shape of its own as the top bar's other buttons are
Row {
    id: root

    required property Window window
    property bool compact: false

    spacing: 4

    ToolbarButton {
        size: root.compact ? 28 : 36
        iconSize: root.compact ? 15 : 18
        shape: "pill"
        turnsOnHover: false
        symbol: "remove"
        onClicked: root.window.showMinimized()
    }
    ToolbarButton {
        size: root.compact ? 28 : 36
        iconSize: root.compact ? 14 : 16
        shape: "cookie6"
        symbol: root.window.visibility === Window.Maximized ? "close_fullscreen" : "open_in_full"
        onClicked: root.window.visibility === Window.Maximized ? root.window.showNormal() : root.window.showMaximized()
    }
    ToolbarButton {
        size: root.compact ? 28 : 36
        iconSize: root.compact ? 15 : 18
        shape: "cookie9"
        shapeHoverColor: Appearance.colors.errorContainer
        shapePressedColor: Appearance.colors.errorContainerActive
        symbol: "close"
        onClicked: root.window.close()
    }
}
