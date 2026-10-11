pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// a material 3 common button: filled, tonal, outlined, text or elevated, with
// an optional leading symbol. pressing squares the corners off a little, the
// expressive shape change, unless the button is `wavy`: the buttons that
// play things are scalloped pills that keep their shape and squish instead.
RippleButton {
    id: root

    enum Variant {
        Filled,
        Tonal,
        Outlined,
        Text,
        Elevated
    }

    property int variant: TextButton.Filled
    property string symbol
    property bool busy: false
    property bool wavy: false
    /// a burst of shapes when clicked (UiState.burst): play, pin, ...
    property string burst
    property color labelColor: {
        switch (variant) {
        case TextButton.Filled: return scheme.onPrimary
        case TextButton.Tonal: return scheme.onSecondaryContainer
        default: return scheme.primary
        }
    }

    implicitHeight: 40
    leftPadding: symbol.length > 0 ? 16 : 24
    rightPadding: 24
    buttonRadius: Appearance.rounding.full
    buttonRadiusPressed: wavy ? buttonRadius : Appearance.rounding.small
    rippleEnabled: !wavy
    backgroundItem.visible: !wavy
    colBackground: {
        switch (variant) {
        case TextButton.Filled: return scheme.primary
        case TextButton.Tonal: return scheme.secondaryContainer
        case TextButton.Elevated: return scheme.surfaceContainerLow
        default: return "transparent"
        }
    }
    colBackgroundHover: {
        switch (variant) {
        case TextButton.Filled: return scheme.primaryHover
        case TextButton.Tonal: return scheme.secondaryContainerHover
        case TextButton.Elevated: return scheme.layer1Hover
        default: return Qt.rgba(scheme.primary.r, scheme.primary.g, scheme.primary.b, 0.08)
        }
    }
    colRipple: {
        switch (variant) {
        case TextButton.Filled: return scheme.primaryActive
        case TextButton.Tonal: return scheme.secondaryContainerActive
        default: return Qt.rgba(scheme.primary.r, scheme.primary.g, scheme.primary.b, 0.14)
        }
    }
    backgroundItem.border.width: variant === TextButton.Outlined ? 1 : (visualFocus ? 2 : 0)
    backgroundItem.border.color: variant === TextButton.Outlined && !visualFocus ? scheme.outlineVariant : scheme.secondary

    WavyPill {
        anchors.fill: parent
        z: -1
        visible: root.wavy
        hovered: root.hovered
        pressed: root.down
        color: root.down ? root.colRipple : (root.hovered ? root.colBackgroundHover : root.colBackground)

        Behavior on color {
            ElementMoveFastColor {}
        }
    }

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            opacity: root.busy ? 0 : 1

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.symbol.length > 0
                text: root.symbol
                iconSize: 18
                fill: 1
                color: root.labelColor
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.text
                font.pixelSize: Appearance.fontSize.small
                font.weight: Font.DemiBold
                color: root.labelColor
            }
        }

        LoadingSpinner {
            anchors.centerIn: parent
            width: 20
            height: 20
            running: root.busy
            Reveal.shown: root.busy
            color: root.labelColor
            trackColor: "transparent"
        }
    }

    onClicked: if (burst.length > 0) UiState.burst(root, burst)
}
