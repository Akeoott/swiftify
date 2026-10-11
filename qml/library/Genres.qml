pragma ComponentBehavior: Bound
import QtQuick

// the featured genres (HomeGenreSuggestion.featured). the gradients are the
// apple system colours the swift app names, in their dark variants.
QtObject {
    readonly property var featured: [
        { name: "Pop", symbol: "music_note", start: "#ff375f", end: "#ff9f0a" },
        { name: "Hip-Hop", symbol: "headphones", start: "#5e5ce6", end: "#bf5af2" },
        { name: "Electronic", symbol: "graphic_eq", start: "#64d2ff", end: "#30d158" },
        { name: "Alternative", symbol: "album", start: "#bf5af2", end: "#ff375f" },
        { name: "R&B", symbol: "mic", start: "#ff453a", end: "#ff9f0a" },
        { name: "Indie", symbol: "auto_awesome", start: "#63e6e2", end: "#40c8e0" },
        { name: "Dance", symbol: "bolt", start: "#0a84ff", end: "#5e5ce6" },
        { name: "Chill", symbol: "nights_stay", start: "#40c8e0", end: "#0a84ff" }
    ]
}
