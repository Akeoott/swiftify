pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// the macos unified toolbar as a material top app bar: back, the open
// playlist's actions, a search field, and the playback menu. it has no
// background: the pages scroll up under it, and each button sits on a shape
// of its own. it is also the handle the window is moved by.
Item {
    id: root

    required property Window window
    readonly property bool onPlaylist: Library.page === Library.Page.Playlist && Library.selectedPlaylist.valid
    readonly property bool searching: Session.libraryConnected && Library.page === Library.Page.Search
    readonly property string playlistLink: "https://open.spotify.com/playlist/" + Library.selectedPlaylist.id

    function focusSearch() {
        if (search.visible) {
            search.focusField()
        }
    }

    implicitHeight: Appearance.sizes.topBarHeight

    DragHandler {
        target: null
        grabPermissions: PointerHandler.CanTakeOverFromAnything
        onActiveChanged: if (active) root.window.startSystemMove()
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onDoubleTapped: root.window.visibility === Window.Maximized ? root.window.showNormal() : root.window.showMaximized()
    }

    ToolbarButton {
        id: back
        effect: ToolbarButton.NudgeLeft
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        symbol: "arrow_back"
        // it sits on an arrow, pointing the way it goes
        shape: "arrow"
        shapeAngle: -90
        turnsOnHover: false
        enabled: Library.canGoBack
        onClicked: Library.goBack()
        tooltip: "Back"
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Row {
            Reveal.shown: root.onPlaylist
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            ToolbarButton {
                effect: ToolbarButton.Spin
                shape: "clover4"
                symbol: "add"
                // a new playlist of the same kind as the one open
                onClicked: Library.selectedPlaylist.isLocal ? UiState.createLocalPlaylistRequested(null)
                                                            : UiState.beginCreatePlaylist()
                tooltip: "New Playlist"
            }
            ToolbarButton {
                effect: ToolbarButton.Pop
                Reveal.shown: Library.selectedPlaylistEditable
                shape: "puffy"
                symbol: "edit"
                onClicked: UiState.editPlaylistRequested()
                tooltip: "Edit Playlist"
            }
            ToolbarButton {
                effect: ToolbarButton.Pop
                // a playlist made here has no link
                Reveal.shown: !Library.selectedPlaylist.isLocal
                shape: "cookie6"
                symbol: "share"
                onClicked: {
                    App.copyToClipboard(root.playlistLink)
                    UiState.toastRequested("Playlist link copied")
                }
                tooltip: "Copy Link"
            }
            ToolbarButton {
                id: more
                effect: ToolbarButton.Pop
                shape: "sunny"
                symbol: "more_horiz"
                onClicked: moreMenu.popupAt(more, 0, more.height)
                tooltip: "More"
            }
            ToolbarButton {
                id: sort
                effect: ToolbarButton.Pop
                shape: "flower"
                symbol: "sort"
                onClicked: sortMenu.popupAt(sort, 0, sort.height)
                tooltip: "Sort Options"
            }
        }

        SearchField {
            id: search
            anchors.verticalCenter: parent.verticalCenter
            Reveal.shown: root.searching || root.onPlaylist
            width: activeFocus || text.length > 0 ? 340 : 260
            placeholder: root.searching ? "Search Spotify" : "Find in Playlist"
            text: root.searching ? Library.searchQuery : Library.playlistFilterQuery
            onTextChanged: {
                if (root.searching) {
                    Library.searchQuery = text
                } else if (root.onPlaylist) {
                    Library.playlistFilterQuery = text
                }
            }

            Behavior on width {
                ElementMoveSmall {}
            }
        }

        ToolbarButton {
            id: overflow
            effect: ToolbarButton.Spin
            anchors.verticalCenter: parent.verticalCenter
            symbol: "more_vert"
            onClicked: playbackMenu.popupAt(overflow, 0, overflow.height)
            tooltip: "Playback"
        }

        WindowControls {
            anchors.verticalCenter: parent.verticalCenter
            // a mac window keeps its own traffic lights
            visible: Settings.showWindowControls && !App.macOS
            window: root.window
        }
    }

    MusicPicker {
        id: trackPicker
        playlistId: Library.selectedPlaylist.isLocal ? Library.selectedPlaylist.id : ""
    }

    MenuLoader {
        id: playbackMenu
        sourceComponent: PlaybackMenu {}
    }

    MenuLoader {
        id: moreMenu
        sourceComponent: StyledMenu {
            StyledMenuItem {
                visible: Library.selectedPlaylistEditable
                height: visible ? implicitHeight : 0
                text: "Edit Playlist"
                symbol: "edit"
                onTriggered: UiState.editPlaylistRequested()
            }
            StyledMenuItem {
                visible: Library.selectedPlaylist.isLocal
                height: visible ? implicitHeight : 0
                text: "Add Tracks…"
                symbol: "playlist_add"
                onTriggered: trackPicker.pickFiles()
            }
            StyledMenuItem {
                visible: Library.selectedPlaylist.isLocal
                height: visible ? implicitHeight : 0
                text: "Add a Folder…"
                symbol: "create_new_folder"
                onTriggered: trackPicker.pickFolder()
            }
            StyledMenuItem {
                visible: !Library.selectedPlaylist.isLocal
                height: visible ? implicitHeight : 0
                text: "Open in Spotify"
                symbol: "open_in_new"
                onTriggered: App.openUrl(root.playlistLink)
            }
            StyledMenuSeparator {
                visible: Library.selectedPlaylistEditable
                height: visible ? implicitHeight : 0
            }
            StyledMenuItem {
                visible: Library.selectedPlaylistEditable
                height: visible ? implicitHeight : 0
                text: "Delete Playlist"
                symbol: "delete"
                destructive: true
                onTriggered: UiState.deletePlaylistRequested(Library.selectedPlaylist)
            }
        }
    }

    MenuLoader {
        id: sortMenu
        sourceComponent: StyledMenu {
            Repeater {
                model: [
                    { label: "Playlist Order", order: Library.SortOrder.Playlist },
                    { label: "Title", order: Library.SortOrder.Title },
                    { label: "Artist", order: Library.SortOrder.Artist },
                    { label: "Album", order: Library.SortOrder.Album },
                    { label: "Time", order: Library.SortOrder.Duration }
                ]

                StyledMenuItem {
                    required property var modelData
                    text: modelData.label
                    checkmark: true
                    checked: Library.playlistSortOrder === modelData.order
                    onTriggered: Library.playlistSortOrder = modelData.order
                }
            }
        }
    }
}
