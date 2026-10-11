pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// end4's hover overlays on artwork.
NumberAnimation {
    duration: Appearance.duration(350)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.curves.standard
}
