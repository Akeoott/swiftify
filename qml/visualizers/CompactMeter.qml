pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// the six-bar meter in the player bar and over the playing row, at the
// display's rate like every visualizer
SpectrumView {
    kind: SpectrumView.Compact
    sensitivity: Settings.visualizerSensitivity
}
