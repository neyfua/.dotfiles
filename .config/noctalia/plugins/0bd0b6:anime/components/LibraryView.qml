import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Commons
import qs.Widgets

Item {
    id: libraryView

    property var pluginApi: null
    readonly property var anime: pluginApi?.mainInstance || null
    property string librarySearchQuery: ""

    signal animeSelected(var show)
    signal settingsRequested()

    function openEntry(entry) {
        libraryView.animeSelected({
            id:               entry.id,
            name:             entry.name,
            englishName:      entry.englishName,
            nativeName:       entry.nativeName || "",
            thumbnail:        entry.thumbnail,
            score:            entry.score,
            type:             entry.type || "",
            episodeCount:     entry.episodeCount || "",
            availableEpisodes: entry.availableEpisodes || { sub: 0, dub: 0, raw: 0 },
            season:           entry.season || null
        })
    }

    function filteredLibraryEntries() {
        var entries = anime?.libraryList ?? []
        var query = (librarySearchQuery || "").trim().toLowerCase()
        if (query.length === 0) return entries
        return entries.filter(function(entry) {
            var haystack = [
                entry.englishName || "",
                entry.name || "",
                entry.nativeName || ""
            ].join(" ").toLowerCase()
            return haystack.indexOf(query) !== -1
        })
    }

    function openSearch() {
        librarySearchBar.visible = true
        librarySearchField.forceActiveFocus()
    }

    function closeSearch() {
        librarySearchBar.visible = false
        librarySearchField.text = ""
    }

    TapHandler {
        enabled: librarySearchBar.visible
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: function(eventPoint) {
            var pos = librarySearchBar.mapToItem(libraryView, 0, 0)
            var x = eventPoint.position.x
            var y = eventPoint.position.y
            var insideSearchBar =
                x >= pos.x && x <= pos.x + librarySearchBar.width &&
                y >= pos.y && y <= pos.y + librarySearchBar.height
            if (!insideSearchBar)
                libraryView.closeSearch()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "transparent"
            z: 2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: Color.mOutlineVariant; opacity: 0.5
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 18; rightMargin: 10 }
                spacing: 8

                Rectangle {
                    id: libraryWordmark
                    visible: !librarySearchBar.visible
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 19
                    color: libraryTitleArea.containsMouse
                        ? Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.92)
                        : Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.88)
                    border.width: 1
                    border.color: libraryTitleArea.containsMouse
                        ? Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.28)
                        : Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.4)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    Row {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                        }
                        spacing: 0

                        Text {
                            text: "A"
                            font.pixelSize: 20
                            font.letterSpacing: 1
                            color: Color.mPrimary
                        }
                        Text {
                            text: "nime Library"
                            font.pixelSize: 20
                            font.letterSpacing: 1
                            color: Color.mOnSurface
                            opacity: libraryTitleArea.containsMouse ? 1 : 0.85
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }
                    }

                    MouseArea {
                        id: libraryTitleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: libraryView.openSearch()
                    }
                }

                Rectangle {
                    id: librarySearchBar
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    color: Color.mSurface
                    visible: false
                    border.color: librarySearchField.activeFocus ? Color.mPrimary : Color.mOutlineVariant
                    border.width: librarySearchField.activeFocus ? 1.5 : 1

                    TextInput {
                        id: librarySearchField
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: libraryClearBtn.left
                            leftMargin: 14
                            rightMargin: 6
                        }
                        color: Color.mOnSurface
                        font.pixelSize: 13
                        clip: true
                        onTextChanged: libraryView.librarySearchQuery = text
                        Keys.onEscapePressed: {
                            libraryView.closeSearch()
                        }
                    }

                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 14 }
                        text: "Search library…"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 13
                        visible: librarySearchField.text.length === 0
                        opacity: 0.6
                    }

                    Item {
                        id: libraryClearBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 10 }
                        width: 22
                        height: 22
                        visible: librarySearchField.text.length > 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            radius: 9
                            color: libraryClearArea.containsMouse ? Color.mPrimaryContainer : Color.mSurfaceVariant
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: libraryClearArea.containsMouse ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                            font.pixelSize: 9
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        MouseArea {
                            id: libraryClearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: librarySearchField.text = ""
                        }
                    }
                }

                Rectangle {
                    visible: (anime?.libraryList?.length ?? 0) > 0
                    height: 30
                    width: libCountText.implicitWidth + 20
                    radius: 15
                    color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.92)
                    border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.42)
                    border.width: 1

                    Text {
                        id: libCountText; anchors.centerIn: parent
                        text: (anime?.libraryList?.length ?? 0) + " saved"
                        font.pixelSize: 10
                        font.letterSpacing: 0.5
                        color: Color.mOnSurfaceVariant
                    }
                }

                Item {
                    width: 38; height: 38

                    Rectangle {
                        anchors.centerIn: parent
                        width: 32; height: 32; radius: 16
                        color: (librarySearchBar.visible || librarySearchToggleArea.containsMouse)
                            ? Color.mPrimaryContainer
                            : "transparent"
                        border.width: librarySearchToggleArea.containsMouse ? 1 : 0
                        border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.25)
                        scale: librarySearchToggleArea.containsMouse ? 1.06 : 1.0
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.width { NumberAnimation { duration: 180 } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "⌕"; font.pixelSize: 18
                        color: (librarySearchBar.visible || librarySearchToggleArea.containsMouse)
                            ? Color.mOnPrimaryContainer
                            : Color.mOnSurfaceVariant
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    MouseArea {
                        id: librarySearchToggleArea
                        anchors.fill: parent
                        z: 1
                        hoverEnabled: true
                        onClicked: {
                            librarySearchBar.visible = !librarySearchBar.visible
                            if (librarySearchBar.visible) librarySearchField.forceActiveFocus()
                            else libraryView.closeSearch()
                        }
                    }
                }

                Item {
                    width: 38; height: 38

                    Rectangle {
                        anchors.centerIn: parent
                        width: 32; height: 32; radius: 16
                        color: settingsArea.containsMouse
                            ? Color.mPrimaryContainer
                            : "transparent"
                        border.width: settingsArea.containsMouse ? 1 : 0
                        border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.25)
                        scale: settingsArea.containsMouse ? 1.06 : 1.0
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.width { NumberAnimation { duration: 180 } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "⚙"
                        font.pixelSize: 15
                        color: settingsArea.containsMouse
                            ? Color.mOnPrimaryContainer
                            : Color.mOnSurfaceVariant
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    MouseArea {
                        id: settingsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: libraryView.settingsRequested()
                    }
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: (anime?.libraryList?.length ?? 0) === 0 && (anime?.libraryLoaded ?? false)

            Rectangle {
                width: Math.min(parent.width - 28, 340)
                anchors.centerIn: parent
                radius: 20
                color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.86)
                border.width: 1
                border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.4)
                implicitHeight: emptyColumn.implicitHeight + 34

                Column {
                    id: emptyColumn
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 42
                        height: 42
                        radius: 21
                        color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "⊡"
                            font.pixelSize: 19
                            color: Color.mPrimary
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Your library is empty"
                        font.pixelSize: 15
                        font.bold: true
                        color: Color.mOnSurface
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        lineHeight: 1.35
                        text: "Open an anime from Browse and tap + Library to keep track of what you are watching."
                        font.pixelSize: 11
                        color: Color.mOnSurfaceVariant
                        opacity: 0.74
                        font.letterSpacing: 0.2
                    }
                }
            }
        }

        // ── Loading ───────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: !(anime?.libraryLoaded ?? true)

            Rectangle {
                width: 28; height: 28; radius: 14
                anchors.centerIn: parent
                color: "transparent"; border.color: Color.mPrimary; border.width: 2
                RotationAnimator on rotation {
                    from: 0; to: 360; duration: 800
                    loops: Animation.Infinite; running: parent.visible
                    easing.type: Easing.Linear
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: (anime?.libraryList?.length ?? 0) > 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── Library grid ──────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: libraryView.filteredLibraryEntries().length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No matches"
                            font.pixelSize: 15
                            font.bold: true
                            color: Color.mOnSurface
                        }

                        Text {
                            width: 280
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: "Try a different title, English name, or native name."
                            font.pixelSize: 11
                            color: Color.mOnSurfaceVariant
                            opacity: 0.74
                        }
                    }
                }

                GridView {
                    id: libGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: libraryView.filteredLibraryEntries().length > 0
                    topMargin: 10
                    leftMargin: 8
                    rightMargin: 8
                    bottomMargin: 10

                    readonly property var columnsMap: ({ "small": 8, "medium": 5, "large": 3 })
                    readonly property int columns: columnsMap[anime?.posterSize || "medium"]

                    cellWidth: Math.floor((width - leftMargin - rightMargin) / columns)
                    cellHeight: cellWidth * 1.78
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    model: {
                        var _ = anime?.libraryVersion ?? 0  // reactive trigger
                        return libraryView.filteredLibraryEntries()
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 3; color: Color.mPrimary; opacity: 0.45; radius: 2
                        }
                    }

                    onContentYChanged: {
                        if (anime) anime.setLibraryScroll(contentY)
                    }

                    onVisibleChanged: {
                        if (!visible || !anime) return
                        Qt.callLater(function() {
                            libGrid.contentY = Math.min(
                                anime.libraryScrollY || 0,
                                Math.max(0, libGrid.contentHeight - libGrid.height)
                            )
                        })
                    }

                    onContentHeightChanged: {
                        if (!visible || !anime) return
                        if ((anime.libraryScrollY || 0) <= 0) return
                        Qt.callLater(function() {
                            libGrid.contentY = Math.min(
                                anime.libraryScrollY || 0,
                                Math.max(0, libGrid.contentHeight - libGrid.height)
                            )
                        })
                    }

                    delegate: Item {
                        width: libGrid.cellWidth
                        height: libGrid.cellHeight

                        readonly property var entry: modelData
                        readonly property real activeProgressRatio: {
                            if (!anime || !entry.lastWatchedEpNum) return 0
                            return anime.getEpisodeProgressRatio(entry.id, entry.lastWatchedEpNum)
                        }

                        Rectangle {
                            id: libCard
                            anchors { fill: parent; margins: 5 }
                            radius: 10; color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.45)
                            clip: true

                            // Cover
                            Rectangle {
                                id: libImageWrapper
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: parent.height - libTitleBar.height - libEpBar.height
                                radius: 10
                                color: "transparent"
                                clip: true
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: libImageWrapper.width
                                        height: libImageWrapper.height
                                        radius: libImageWrapper.radius
                                    }
                                }

                                Image {
                                    id: libCover
                                    anchors.fill: parent
                                    source: entry.thumbnail || ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true; cache: true
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }

                                    Rectangle {
                                        anchors.fill: parent; color: Color.mSurfaceVariant
                                        visible: libCover.status !== Image.Ready
                                        Text {
                                            anchors.centerIn: parent; text: "◫"
                                            font.pixelSize: 28; color: Color.mOutline; opacity: 0.25
                                        }
                                    }

                                    // Score badge
                                    Rectangle {
                                        visible: entry.score != null
                                        anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 6 }
                                        height: 18; radius: 9; width: libScoreText.implicitWidth + 10
                                        color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.88)
                                        border.width: 1
                                        border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.38)

                                        Text {
                                            id: libScoreText; anchors.centerIn: parent
                                            text: entry.score ? "★ " + (entry.score).toFixed(1) : ""
                                            font.pixelSize: 8; font.bold: true
                                            color: Color.mPrimary
                                        }
                                    }

                                    // Gradient
                                    Rectangle {
                                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                        height: 40
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 1.0; color: Color.mSurfaceVariant }
                                        }
                                    }
                                }
                            }

                            // Title bar
                            Rectangle {
                                id: libTitleBar
                                anchors { bottom: libEpBar.top; left: parent.left; right: parent.right }
                                height: libTitleText.implicitHeight + 10
                                color: Color.mSurfaceVariant

                                Text {
                                    id: libTitleText
                                    anchors {
                                        left: parent.left; right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 8; rightMargin: 8
                                    }
                                    text: entry.englishName || entry.name || ""
                                    font.pixelSize: 10; font.letterSpacing: 0.2
                                    color: Color.mOnSurface
                                    wrapMode: Text.Wrap; maximumLineCount: 2
                                    elide: Text.ElideRight; lineHeight: 1.3
                                }
                            }

                            // Last-watched bar
                            Rectangle {
                                id: libEpBar
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: 28; color: Color.mSurface; radius: 10

                                // Square off top corners
                                Rectangle {
                                    anchors { top: parent.top; left: parent.left; right: parent.right }
                                    height: parent.radius; color: parent.color
                                }

                                Row {
                                    anchors {
                                        verticalCenter: parent.verticalCenter
                                        left: parent.left; leftMargin: 8
                                    }
                                    spacing: 5

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "▶"; font.pixelSize: 7
                                        color: entry.lastWatchedEpNum ? Color.mPrimary : Color.mOutline
                                        opacity: entry.lastWatchedEpNum ? 1 : 0.4
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: entry.lastWatchedEpNum
                                            ? "Ep. " + entry.lastWatchedEpNum
                                            : "Not started"
                                        font.pixelSize: 10; font.letterSpacing: 0.4
                                        color: entry.lastWatchedEpNum
                                            ? Color.mOnSurface : Color.mOnSurfaceVariant
                                        opacity: entry.lastWatchedEpNum ? 0.85 : 0.45
                                    }

                                    Rectangle {
                                        visible: (entry.watchedEpisodes || []).length > 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 14; radius: 7
                                        width: watchedCountText.implicitWidth + 8
                                        color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.18)

                                        Text {
                                            id: watchedCountText
                                            anchors.centerIn: parent
                                            text: "✓ " + (entry.watchedEpisodes || []).length
                                            font.pixelSize: 8; font.bold: true
                                            color: Color.mPrimary
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        bottom: parent.bottom
                                        leftMargin: 8
                                        rightMargin: 8
                                        bottomMargin: 4
                                    }
                                    height: 3
                                    radius: 2
                                    color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.22)
                                    visible: activeProgressRatio > 0

                                    Rectangle {
                                        width: parent.width * activeProgressRatio
                                        height: parent.height
                                        radius: parent.radius
                                        color: Color.mTertiary
                                    }
                                }
                            }

                            Rectangle {
                                id: libraryAction
                                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
                                width: 32
                                height: 32
                                radius: 16
                                color: libraryActionArea.containsMouse
                                    ? Qt.rgba(Color.mErrorContainer.r, Color.mErrorContainer.g, Color.mErrorContainer.b, 0.96)
                                    : Color.mPrimary
                                border.width: 1
                                border.color: libraryActionArea.containsMouse
                                    ? Color.mError
                                    : Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.6)
                                z: 3

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                NIcon {
                                    anchors.centerIn: parent
                                    icon: "bookmark"
                                    pointSize: 14
                                    color: Color.mOnPrimary
                                    opacity: libraryActionArea.containsMouse ? 0 : 1
                                    scale: libraryActionArea.containsMouse ? 0.7 : 1
                                    Behavior on opacity { NumberAnimation { duration: 110 } }
                                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "−"
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: Color.mOnErrorContainer
                                    opacity: libraryActionArea.containsMouse ? 1 : 0
                                    scale: libraryActionArea.containsMouse ? 1 : 0.7
                                    Behavior on opacity { NumberAnimation { duration: 110 } }
                                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    id: libraryActionArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: if (anime) anime.removeFromLibrary(entry.id)
                                }

                                StyledToolTip {
                                    target: libraryActionArea
                                    shown: libraryActionArea.containsMouse
                                    above: false
                                    text: "Remove from library"
                                }
                            }

                            // Hover/press overlay
                            Rectangle {
                                anchors.fill: parent; radius: 10; color: Color.mPrimary
                                opacity: libCardArea.pressed ? 0.16 : (libCardArea.containsMouse ? 0.07 : 0)
                                Behavior on opacity { NumberAnimation { duration: 130 } }
                            }

                            transform: Scale {
                                origin.x: libCard.width / 2; origin.y: libCard.height / 2
                                xScale: libCardArea.pressed ? 0.97 : 1.0
                                yScale: libCardArea.pressed ? 0.97 : 1.0
                                Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                id: libCardArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: libraryView.openEntry(entry)
                            }
                        }
                    }
                }
            }
        }
    }
}
