import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Commons

Item {
    id: feedView

    property var pluginApi: null
    readonly property var anime: pluginApi?.mainInstance || null
    readonly property var newEntries: anime?.feedList ?? []
    readonly property bool hasAnyContent:
        newEntries.length > 0

    signal animeSelected(var show, string nextEpisode)

    function _columns() {
        var size = anime?.posterSize || "medium"
        if (size === "small")
            return 5
        if (size === "large")
            return 3
        return 4
    }

    function _showFromEntry(entry, posterOverride) {
        if (!entry) return null
        return {
            id: entry.id,
            name: entry.name || "",
            englishName: entry.englishName || "",
            nativeName: entry.nativeName || "",
            thumbnail: entry.thumbnail || posterOverride || "",
            score: entry.score,
            type: entry.type || "",
            episodeCount: entry.episodeCount || "",
            availableEpisodes: entry.availableEpisodes || { sub: 0, dub: 0, raw: 0 },
            season: entry.season || null
        }
    }

    function _showFromFeedItem(item) {
        if (!anime || !item) return null
        return _showFromEntry(anime.getLibraryEntry(item.id), item.poster || "")
    }

    function openEntry(item) {
        var show = _showFromFeedItem(item)
        if (!show) return
        feedView.animeSelected(show, String(item.nextEpisode || ""))
    }

    function playNextForItem(item) {
        var show = _showFromFeedItem(item)
        if (!show || !anime) return
        anime.playNextForShow(show, String(item.nextEpisode || ""))
    }

    function updatedLabel() {
        var ts = anime?.feedLastFetchedAt || 0
        if (ts <= 0)
            return "Not updated yet"
        var diff = Math.max(0, Math.floor((Date.now() - ts) / 1000))
        if (diff < 15)
            return "Updated just now"
        if (diff < 60)
            return "Updated " + diff + "s ago"
        if (diff < 3600)
            return "Updated " + Math.floor(diff / 60) + "m ago"
        if (diff < 86400)
            return "Updated " + Math.floor(diff / 3600) + "h ago"
        return "Updated " + Math.floor(diff / 86400) + "d ago"
    }

    function summaryText() {
        var parts = []
        if (newEntries.length > 0)
            parts.push(newEntries.length + " new")
        return parts.join(" · ")
    }

    function headerStatusText() {
        var summary = summaryText()
        var updated = anime?.isFetchingFeed ? "Refreshing…" : updatedLabel()
        if (summary.length === 0)
            return updated
        return summary + " · " + updated
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "transparent"
            z: 2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1
                color: Color.mOutlineVariant
                opacity: 0.5
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 18; rightMargin: 10 }
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 19
                    color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.72)
                    border.width: 1
                    border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.18)

                    Row {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                        }
                        spacing: 0

                        Text {
                            text: "F"
                            font.pixelSize: 22
                            font.letterSpacing: 1
                            color: Color.mPrimary
                        }
                        Text {
                            text: "eed"
                            font.pixelSize: 22
                            font.letterSpacing: 1
                            color: Color.mOnSurface
                            opacity: 0.85
                        }
                    }
                }

                Item {
                    width: 38
                    height: 38

                    Rectangle {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        radius: 16
                        color: refreshArea.containsMouse
                            ? Color.mPrimaryContainer
                            : "transparent"
                        border.width: refreshArea.containsMouse ? 1 : 0
                        border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.25)
                        scale: refreshArea.containsMouse ? 1.06 : 1.0
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.width { NumberAnimation { duration: 180 } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        font.pixelSize: 16
                        color: refreshArea.containsMouse
                            ? Color.mOnPrimaryContainer
                            : Color.mOnSurfaceVariant
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (anime) anime.fetchFollowingFeed(true)
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                visible: (anime?.isFetchingFeed ?? false) && !feedView.hasAnyContent

                Column {
                    anchors.centerIn: parent
                    spacing: 14

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"
                        border.color: Color.mPrimary
                        border.width: 2
                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 800
                            loops: Animation.Infinite
                            running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "checking followed shows"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11
                        font.letterSpacing: 2
                        opacity: 0.7
                    }
                }
            }

            Item {
                anchors.fill: parent
                visible: !(anime?.isFetchingFeed ?? false) && (anime?.feedError?.length ?? 0) > 0

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Feed unavailable"
                        font.pixelSize: 15
                        font.bold: true
                        color: Color.mOnSurface
                    }

                    Text {
                        width: 320
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: anime?.feedError ?? ""
                        font.pixelSize: 11
                        color: Color.mOnSurfaceVariant
                        opacity: 0.74
                    }
                }
            }

            Item {
                anchors.fill: parent
                visible: !(anime?.isFetchingFeed ?? false)
                    && (anime?.feedError?.length ?? 0) === 0
                    && !feedView.hasAnyContent

                Rectangle {
                    width: Math.min(parent.width - 28, 370)
                    anchors.centerIn: parent
                    radius: 20
                    color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.72)
                    border.width: 1
                    border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.16)
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
                                text: (anime?.libraryList?.length ?? 0) > 0 ? "✓" : "⊡"
                                font.pixelSize: 19
                                color: Color.mPrimary
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (anime?.libraryList?.length ?? 0) > 0
                                ? "You're all caught up"
                                : "Your library is empty"
                            font.pixelSize: 15
                            font.bold: true
                            color: Color.mOnSurface
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            lineHeight: 1.35
                            text: (anime?.libraryList?.length ?? 0) > 0
                                ? "No currently airing follow-up releases are waiting right now. Feed only shows recent episode releases for shows you are actively keeping up with."
                                : "Add anime to your library and Feed will surface recent releases from shows you are actively following."
                            font.pixelSize: 11
                            color: Color.mOnSurfaceVariant
                            opacity: 0.74
                            font.letterSpacing: 0.2
                        }
                    }
                }
            }

            Flickable {
                id: feedScroll
                anchors.fill: parent
                anchors.margins: 10
                visible: feedView.hasAnyContent && (anime?.feedError?.length ?? 0) === 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: sectionsColumn.height

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3
                        color: Color.mPrimary
                        opacity: 0.45
                        radius: 2
                    }
                }

                Column {
                    id: sectionsColumn
                    width: feedScroll.width
                    spacing: 14

                    Item {
                        width: parent.width
                        height: helperColumn.implicitHeight

                        Column {
                            id: helperColumn
                            width: parent.width
                            spacing: 4

                            Text {
                                width: parent.width
                                text: feedView.headerStatusText()
                                visible: text.length > 0
                                font.pixelSize: 10
                                font.letterSpacing: 0.25
                                color: anime?.isFetchingFeed ? Color.mPrimary : Color.mOnSurfaceVariant
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: parent.width
                                text: "Recent airing releases from shows you're actively keeping up with."
                                font.pixelSize: 11
                                color: Color.mOnSurfaceVariant
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: newEntries.length > 0 ? newSectionColumn.implicitHeight : 0
                        visible: newEntries.length > 0

                        Column {
                            id: newSectionColumn
                            width: parent.width
                            spacing: 10

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "New Episodes"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Color.mOnSurface
                                }

                                Rectangle {
                                    height: 20
                                    width: newCountText.implicitWidth + 14
                                    radius: 10
                                    color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.12)
                                    border.width: 1
                                    border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.28)

                                    Text {
                                        id: newCountText
                                        anchors.centerIn: parent
                                        text: newEntries.length + " close"
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                        color: Color.mPrimary
                                    }
                                }
                            }

                            Grid {
                                id: newGrid
                                width: parent.width
                                columns: feedView._columns()
                                rowSpacing: 10
                                columnSpacing: 10
                                readonly property real cardWidth:
                                    Math.floor((width - ((columns - 1) * columnSpacing)) / columns)

                                Repeater {
                                    model: newEntries

                                    delegate: Item {
                                        width: newGrid.cardWidth
                                        height: Math.round(width * 1.5)

                                        readonly property var itemData: modelData
                                        readonly property var libraryEntry: {
                                            var _ = anime?.libraryVersion ?? 0
                                            return anime ? anime.getLibraryEntry(itemData.id) : null
                                        }

                                        Rectangle {
                                            id: newCard
                                            anchors.fill: parent
                                            radius: 14
                                            color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.6)
                                            border.width: 1
                                            border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.12)
                                            clip: true

                                            Rectangle {
                                                id: newPoster
                                                anchors {
                                                    top: parent.top
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                                height: parent.height - newFooter.height
                                                radius: 14
                                                clip: true
                                                color: "transparent"
                                                layer.enabled: true
                                                layer.effect: OpacityMask {
                                                    maskSource: Rectangle {
                                                        width: newPoster.width
                                                        height: newPoster.height
                                                        radius: newPoster.radius
                                                    }
                                                }

                                                Image {
                                                    id: newCover
                                                    anchors.fill: parent
                                                    source: itemData.poster || ""
                                                    fillMode: Image.PreserveAspectCrop
                                                    asynchronous: true
                                                    cache: true
                                                    opacity: status === Image.Ready ? 1 : 0
                                                    Behavior on opacity { NumberAnimation { duration: 300 } }

                                                    Rectangle {
                                                        anchors.fill: parent
                                                        color: Color.mSurfaceVariant
                                                        visible: newCover.status !== Image.Ready

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "◫"
                                                            font.pixelSize: 28
                                                            color: Color.mOutline
                                                            opacity: 0.25
                                                        }
                                                    }

                                                    Rectangle {
                                                        anchors { top: parent.top; left: parent.left; topMargin: 8; leftMargin: 8 }
                                                        height: 20
                                                        width: latestCountText.implicitWidth + 12
                                                        radius: 10
                                                        color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.92)

                                                        Text {
                                                            id: latestCountText
                                                            anchors.centerIn: parent
                                                            text: itemData.newCount + " new"
                                                            font.pixelSize: 8
                                                            font.bold: true
                                                            color: Color.mOnPrimary
                                                        }
                                                    }

                                                    Rectangle {
                                                        anchors { top: parent.top; right: parent.right; topMargin: 8; rightMargin: 8 }
                                                        height: 20
                                                        width: latestEpisodeText.implicitWidth + 12
                                                        radius: 10
                                                        color: Qt.rgba(Color.mSecondaryContainer.r, Color.mSecondaryContainer.g, Color.mSecondaryContainer.b, 0.78)
                                                        border.width: 1
                                                        border.color: Qt.rgba(Color.mSecondary.r, Color.mSecondary.g, Color.mSecondary.b, 0.22)

                                                        Text {
                                                            id: latestEpisodeText
                                                            anchors.centerIn: parent
                                                            text: "Next " + itemData.nextEpisode
                                                            font.pixelSize: 8
                                                            font.bold: true
                                                            color: Color.mOnSecondaryContainer
                                                        }
                                                    }

                                                    Rectangle {
                                                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                                        height: 62
                                                        gradient: Gradient {
                                                            GradientStop { position: 0.0; color: "transparent" }
                                                            GradientStop { position: 1.0; color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.9) }
                                                        }
                                                    }

                                                    Column {
                                                        anchors {
                                                            left: parent.left
                                                            right: parent.right
                                                            bottom: parent.bottom
                                                            leftMargin: 10
                                                            rightMargin: 10
                                                            bottomMargin: 10
                                                        }
                                                        spacing: 4

                                                        Text {
                                                            width: parent.width
                                                            text: itemData.title || ""
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            color: Color.mOnSurface
                                                            wrapMode: Text.Wrap
                                                            maximumLineCount: 2
                                                            elide: Text.ElideRight
                                                            lineHeight: 1.25
                                                        }

                                                        Text {
                                                            width: parent.width
                                                            text: libraryEntry && (libraryEntry.lastWatchedEpNum || "").length > 0
                                                                ? "Last watched " + libraryEntry.lastWatchedEpNum
                                                                : "Ready to catch up"
                                                            font.pixelSize: 9
                                                            color: Color.mOnSurfaceVariant
                                                            opacity: 0.8
                                                            elide: Text.ElideRight
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                id: newFooter
                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    bottom: parent.bottom
                                                }
                                                height: 48
                                                z: 2
                                                color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.88)
                                                radius: 14

                                                Rectangle {
                                                    anchors { top: parent.top; left: parent.left; right: parent.right }
                                                    height: parent.radius
                                                    color: parent.color
                                                }

                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 8

                                                    Rectangle {
                                                        width: 70
                                                        height: 28
                                                        radius: 14
                                                        z: 3
                                                        color: openNewArea.containsMouse
                                                            ? Qt.rgba(Color.mSecondary.r, Color.mSecondary.g, Color.mSecondary.b, 0.24)
                                                            : Qt.rgba(Color.mSecondary.r, Color.mSecondary.g, Color.mSecondary.b, 0.14)
                                                        border.width: 1
                                                        border.color: openNewArea.containsMouse
                                                            ? Qt.rgba(Color.mSecondary.r, Color.mSecondary.g, Color.mSecondary.b, 0.52)
                                                            : Qt.rgba(Color.mSecondary.r, Color.mSecondary.g, Color.mSecondary.b, 0.34)
                                                        Behavior on color { ColorAnimation { duration: 140 } }
                                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "Open"
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: openNewArea.containsMouse ? Color.mSecondary : Color.mOnSurface
                                                            Behavior on color { ColorAnimation { duration: 140 } }
                                                        }

                                                        MouseArea {
                                                            id: openNewArea
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: feedView.openEntry(itemData)
                                                        }
                                                    }

                                                    Rectangle {
                                                        width: 84
                                                        height: 28
                                                        radius: 14
                                                        z: 3
                                                        color: playNewArea.containsMouse
                                                            ? Color.mPrimary
                                                            : Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.18)
                                                        border.width: 1
                                                        border.color: playNewArea.containsMouse
                                                            ? Color.mPrimary
                                                            : Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.42)
                                                        Behavior on color { ColorAnimation { duration: 140 } }
                                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "Play Next"
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: playNewArea.containsMouse
                                                                ? Color.mOnPrimary
                                                                : Color.mPrimary
                                                            Behavior on color { ColorAnimation { duration: 140 } }
                                                        }

                                                        MouseArea {
                                                            id: playNewArea
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: feedView.playNextForItem(itemData)
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 14
                                                color: Color.mPrimary
                                                z: 1
                                                opacity: newCardArea.pressed ? 0.14 : (newCardArea.containsMouse ? 0.06 : 0)
                                                Behavior on opacity { NumberAnimation { duration: 130 } }
                                            }

                                            transform: Scale {
                                                origin.x: newCard.width / 2
                                                origin.y: newCard.height / 2
                                                xScale: newCardArea.pressed ? 0.98 : 1.0
                                                yScale: newCardArea.pressed ? 0.98 : 1.0
                                                Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                                Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                            }

                                            MouseArea {
                                                id: newCardArea
                                                anchors.fill: parent
                                                z: 1
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: feedView.openEntry(itemData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
