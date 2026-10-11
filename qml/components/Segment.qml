pragma ComponentBehavior: Bound
import QtQuick

// one choice in a SegmentedControl: a glyph, a label or both.
QtObject {
    final property string text
    final property string symbol
    final property string tooltip
    final property bool enabled: true
}
