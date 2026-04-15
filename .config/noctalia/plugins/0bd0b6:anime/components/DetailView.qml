import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons

Item {
    id: detailView

    property var pluginApi: null
    readonly property var anime: pluginApi?.mainInstance || null
    property string _lastCenteredEpisodeKey: ""

    signal backRequested()

    readonly property bool _inLibrary:
        anime && anime.currentAnime ? anime.isInLibrary(anime.currentAnime.id) : false
    readonly property var _nextEpisode:
        anime?.currentAnime ? anime.getNextUnwatchedEpisode(anime.currentAnime) : null

    function centerPreferredEpisode(force) {
        if (!anime?.currentAnime || !epList.visible) return

        var entry = anime.getLibraryEntry(anime.currentAnime.id)
        var lastEpNum = entry?.lastWatchedEpNum || ""
        var targetEpNum = anime?.detailFocusEpisodeNum || ""
        var episodes = anime.currentAnime.episodes || []
        if ((!lastEpNum && !targetEpNum) || episodes.length === 0) return

        var focusEpNum = targetEpNum || lastEpNum
        var key = String(anime.currentAnime.id || "") + ":" + String(focusEpNum) + ":" + String(episodes.length)
        if (!force && _lastCenteredEpisodeKey === key)
            return

        var index = -1
        for (var i = 0; i < episodes.length; i++) {
            if (String(episodes[i].number) === String(focusEpNum)) {
                index = i
                break
            }
        }
        if (index < 0) return

        _lastCenteredEpisodeKey = key
        Qt.callLater(function() {
            if (!epList.visible || epList.count <= index) return
            epList.positionViewAtIndex(index, ListView.Center)
        })
    }

    function _streamTitle() {
        return anime?.currentAnime
            ? (anime.currentAnime.englishName || anime.currentAnime.name || "")
            : ""
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
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 8

                // Back button
                Item {
                    width: 38; height: 38
                    readonly property bool hovered: backHover.hovered

                    Rectangle {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        radius: 16
                        color: parent.hovered ? Color.mPrimaryContainer : "transparent"
                        border.width: parent.hovered ? 1 : 0
                        border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.25)
                        scale: parent.hovered ? 1.06 : 1.0
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on border.width { NumberAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "←"
                        font.pixelSize: 18
                        color: parent.hovered ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }
                    HoverHandler { id: backHover }
                    MouseArea {
                        id: backArea; anchors.fill: parent
                        onClicked: detailView.backRequested()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 19
                    color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.88)
                    border.width: 1
                    border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.4)

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                            rightMargin: 14
                        }
                        text: anime?.currentAnime
                            ? (anime.currentAnime.englishName || anime.currentAnime.name || "")
                            : ""
                        font.pixelSize: 13
                        color: Color.mOnSurface
                        elide: Text.ElideRight
                    }
                }

                // Library button
                Item {
                    visible: anime?.currentAnime != null && detailView._nextEpisode != null
                    width: nextBtnLabel.implicitWidth + 34; height: 32

                    Rectangle {
                        anchors.fill: parent; radius: height / 2
                        color: nextArea.containsMouse ? Color.mPrimaryContainer : Color.mSurface
                        border.color: nextArea.containsMouse ? Color.mPrimary : Color.mOutlineVariant
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                    }
                    Row {
                        anchors.centerIn: parent; spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "▶"
                            font.pixelSize: 10; font.bold: true
                            color: nextArea.containsMouse ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                        }
                        Text {
                            id: nextBtnLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: detailView._nextEpisode
                                ? "Next Ep. " + detailView._nextEpisode.number
                                : "Next"
                            font.pixelSize: 11; font.letterSpacing: 0.3
                            color: nextArea.containsMouse ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                        }
                    }
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!anime?.currentAnime) return
                            anime.playNextUnwatched(anime.currentAnime)
                        }
                    }
                }

                Item {
                    visible: anime?.currentAnime != null
                    width: libBtnLabel.implicitWidth + 28; height: 32

                    Rectangle {
                        anchors.fill: parent; radius: height / 2
                        color: detailView._inLibrary
                            ? (libraryArea.containsMouse ? Color.mPrimary : Color.mPrimaryContainer)
                            : (libraryArea.containsMouse ? Color.mPrimaryContainer : Color.mSurface)
                        border.color: detailView._inLibrary || libraryArea.containsMouse ? Color.mPrimary : Color.mOutlineVariant
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                    }
                    Row {
                        anchors.centerIn: parent; spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: detailView._inLibrary ? "✓" : "+"
                            font.pixelSize: 11; font.bold: true
                            color: detailView._inLibrary
                                ? (libraryArea.containsMouse ? Color.mOnPrimary : Color.mOnPrimaryContainer)
                                : (libraryArea.containsMouse ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant)
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        Text {
                            id: libBtnLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Library"
                            font.pixelSize: 11; font.letterSpacing: 0.3
                            color: detailView._inLibrary
                                ? (libraryArea.containsMouse ? Color.mOnPrimary : Color.mOnPrimaryContainer)
                                : (libraryArea.containsMouse ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant)
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }
                    MouseArea {
                        id: libraryArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!anime?.currentAnime) return
                            if (detailView._inLibrary)
                                anime.removeFromLibrary(anime.currentAnime.id)
                            else
                                anime.addToLibrary(anime.currentAnime)
                        }
                    }
                }
            }
        }

        // ── Episode count / last watched sub-bar ──────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: Math.max(34, detailMetaFlow.implicitHeight + 16)
            color: "transparent"
            visible: anime?.currentAnime != null

            Item {
                anchors.fill: parent
                anchors.margins: 8
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                readonly property var libraryEntry: anime?.currentAnime
                    ? anime.getLibraryEntry(anime.currentAnime.id) : null
                readonly property var episodeList: anime?.currentAnime?.episodes || []
                readonly property int lastWatchedIndex: {
                    if (!libraryEntry || !episodeList.length) return -1
                    for (var i = 0; i < episodeList.length; i++) {
                        if (String(episodeList[i].number) === String(libraryEntry.lastWatchedEpNum))
                            return i
                    }
                    return -1
                }
                readonly property bool hasOlderUnwatched: {
                    if (!libraryEntry || lastWatchedIndex < 0) return false
                    for (var i = 0; i <= lastWatchedIndex; i++) {
                        if (!(anime?.isEpisodeWatched(anime?.currentAnime?.id ?? "", episodeList[i].number) ?? false))
                            return true
                    }
                    return false
                }

                Flow {
                    id: detailMetaFlow
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: 2
                    }
                    spacing: 8

                    Text {
                        text: {
                            var eps = anime?.currentAnime?.episodes
                            return eps ? (eps.length + " episodes") : ""
                        }
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        color: Color.mOnSurfaceVariant
                        opacity: 0.75
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        visible: parent.parent.libraryEntry !== null && parent.parent.libraryEntry !== undefined
                            && (parent.parent.libraryEntry.lastWatchedEpNum || "") !== ""
                        height: 20
                        width: lastWatchedText.implicitWidth + 18
                        radius: 10
                        color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.12)
                        border.color: Color.mPrimary
                        border.width: 1

                        Text {
                            id: lastWatchedText
                            anchors.centerIn: parent
                            text: parent.visible ? "Last: Ep. " + detailMetaFlow.parent.libraryEntry.lastWatchedEpNum : ""
                            font.pixelSize: 9
                            font.letterSpacing: 0.8
                            color: Color.mPrimary
                        }
                    }

                    Rectangle {
                        visible: detailMetaFlow.parent.hasOlderUnwatched
                        height: 22
                        width: catchUpText.implicitWidth + 22
                        radius: 11
                        color: catchUpArea.containsMouse ? Color.mPrimaryContainer : Color.mSurface
                        border.color: catchUpArea.containsMouse ? Color.mPrimary : Color.mOutlineVariant
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Behavior on border.color { ColorAnimation { duration: 160 } }

                        Text {
                            id: catchUpText
                            anchors.centerIn: parent
                            text: "Mark 1→Last"
                            font.pixelSize: 9
                            font.letterSpacing: 0.6
                            color: catchUpArea.containsMouse ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }

                        MouseArea {
                            id: catchUpArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!anime?.currentAnime || !detailMetaFlow.parent.libraryEntry) return
                                anime.markEpisodesThrough(
                                    anime.currentAnime,
                                    detailMetaFlow.parent.libraryEntry.lastWatchedEpId || "",
                                    detailMetaFlow.parent.libraryEntry.lastWatchedEpNum || "",
                                    detailMetaFlow.parent.lastWatchedIndex
                                )
                            }
                        }
                    }

                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: Color.mOutlineVariant; opacity: 0.3
            }
        }

        // ── Hero: thumbnail + description ─────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 160
            color: Color.mSurface
            clip: true
            visible: anime?.currentAnime != null

            // Blurred background from thumbnail
            Image {
                anchors.fill: parent
                source: anime?.currentAnime?.thumbnail ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: 0.15
                layer.enabled: true
                layer.effect: null
            }

            // Dark gradient overlay
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.22) }
                    GradientStop { position: 1.0; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.35) }
                }
            }

            Row {
                anchors { fill: parent; margins: 12 }
                spacing: 12

                // Thumbnail
                Rectangle {
                    width: 100; height: 136
                    radius: 8; clip: true
                    color: Color.mSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: anime?.currentAnime?.thumbnail ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                // Description
                Item {
                    width: parent.width - 124
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors { fill: parent; topMargin: 4 }
                        text: anime?.currentAnime?.description ?? ""
                        color: Color.mOnSurface
                        font.pixelSize: 11
                        lineHeight: 1.4
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 8
                        opacity: 0.85
                    }
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: Color.mOutlineVariant; opacity: 0.3
            }
        }

        // ── Episode list ──────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true

            // Fetching detail spinner
            Rectangle {
                anchors.fill: parent; color: "transparent"
                visible: anime?.isFetchingDetail ?? false; z: 5

                Column {
                    anchors.centerIn: parent; spacing: 14

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"; border.color: Color.mPrimary; border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite; running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "fetching episodes"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11; font.letterSpacing: 2; opacity: 0.7
                    }
                }
            }

            // Fetching stream spinner
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.68)
                visible: anime?.isFetchingLinks ?? false; z: 6

                Column {
                    anchors.centerIn: parent; spacing: 14

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"; border.color: Color.mPrimary; border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite; running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "fetching stream"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11; font.letterSpacing: 2; opacity: 0.7
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.52)
                visible: anime?.isLaunchingPlayer ?? false; z: 6

                Column {
                    anchors.centerIn: parent; spacing: 12

                    Rectangle {
                        width: 24; height: 24; radius: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"; border.color: Color.mPrimary; border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 760
                            loops: Animation.Infinite; running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "opening player"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11; font.letterSpacing: 2; opacity: 0.8
                    }
                }
            }

            // Error toast
            Rectangle {
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: ((anime?.linksError?.length ?? 0) > 0
                        || (anime?.playbackError?.length ?? 0) > 0) ? 56 : 12
                }
                height: 36
                radius: 18
                width: Math.min(parent.width - 32, detailErrText.implicitWidth + 28)
                color: Color.mErrorContainer
                visible: (anime?.detailError?.length ?? 0) > 0 && !(anime?.isFetchingDetail ?? false)
                z: 7

                Text {
                    id: detailErrText
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    text: anime?.detailError ?? ""
                    font.pixelSize: 11
                    color: Color.mOnErrorContainer
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom; horizontalCenter: parent.horizontalCenter
                    bottomMargin: (anime?.playbackError?.length ?? 0) > 0 ? 56 : 12
                }
                height: 36; radius: 18
                width: Math.min(parent.width - 32, linksErrText.implicitWidth + 28)
                color: Color.mErrorContainer
                visible: (anime?.linksError?.length ?? 0) > 0 && !(anime?.isFetchingLinks ?? false)
                z: 7

                Text {
                    id: linksErrText
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    text: anime?.linksError ?? ""
                    font.pixelSize: 11
                    color: Color.mOnErrorContainer
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom; horizontalCenter: parent.horizontalCenter
                    bottomMargin: 12
                }
                height: 36; radius: 18
                width: Math.min(parent.width - 32, playbackErrText.implicitWidth + 28)
                color: Color.mErrorContainer
                visible: (anime?.playbackError?.length ?? 0) > 0 && !(anime?.isLaunchingPlayer ?? false)
                z: 7

                Text {
                    id: playbackErrText
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    text: anime?.playbackError ?? ""
                    font.pixelSize: 11
                    color: Color.mOnErrorContainer
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            ListView {
                id: epList
                anchors.fill: parent; clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: anime?.currentAnime?.episodes ?? []

                onModelChanged: detailView.centerPreferredEpisode(false)
                onVisibleChanged: if (visible) detailView.centerPreferredEpisode(true)
                onContentHeightChanged: detailView.centerPreferredEpisode(false)

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3; color: Color.mPrimary; opacity: 0.45; radius: 2
                    }
                }

                delegate: Rectangle {
                    width: epList.width; height: 52

                    readonly property var _libEntry: {
                        var _ = anime?.libraryVersion ?? 0  // reactive trigger
                        return anime?.currentAnime
                            ? anime.getLibraryEntry(anime.currentAnime.id) : null
                    }
                    readonly property bool isLastWatched:
                        _libEntry !== null && _libEntry !== undefined
                        && _libEntry.lastWatchedEpNum === String(modelData.number)
                    readonly property bool isWatched:
                        (anime?.libraryVersion ?? 0) >= 0 &&
                        (anime?.isEpisodeWatched(anime?.currentAnime?.id ?? "", modelData.number) ?? false)
                    readonly property bool hasProgress:
                        !isWatched &&
                        (anime?.libraryVersion ?? 0) >= 0 &&
                        (anime?.hasEpisodeProgress(anime?.currentAnime?.id ?? "", modelData.number) ?? false)
                    readonly property real progressRatio:
                        (anime?.libraryVersion ?? 0) >= 0
                        ? (anime?.getEpisodeProgressRatio(anime?.currentAnime?.id ?? "", modelData.number) ?? 0)
                        : 0

                    color: isLastWatched
                        ? Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.07)
                        : (epRowArea.pressed
                            ? Color.mSurfaceVariant
                            : (epRowArea.containsMouse ? Color.mSurface : "transparent"))
                    opacity: isWatched && !isLastWatched ? 0.5 : 1.0
                    Behavior on color { ColorAnimation { duration: 110 } }

                    Rectangle {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left; right: parent.right
                            leftMargin: 64; rightMargin: 56
                        }
                        height: 1; color: Color.mOutlineVariant; opacity: 0.22
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: 64
                            rightMargin: 56
                            bottomMargin: 3
                        }
                        height: 3
                        radius: 2
                        color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.18)
                        visible: hasProgress && progressRatio > 0

                        Rectangle {
                            width: parent.width * progressRatio
                            height: parent.height
                            radius: parent.radius
                            color: Color.mTertiary
                        }
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        spacing: 14

                        Rectangle {
                            width: epPillText.implicitWidth + 16; height: 26; radius: 13
                            color: (isLastWatched || isWatched) ? Color.mPrimary : Color.mPrimaryContainer

                            Text {
                                id: epPillText; anchors.centerIn: parent
                                text: "Ep." + (modelData.number || "?")
                                font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.5
                                color: (isLastWatched || isWatched) ? Color.mOnPrimary : Color.mOnPrimaryContainer
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Episode " + (modelData.number || "")
                            font.pixelSize: 12; color: Color.mOnSurface; elide: Text.ElideRight
                        }

                        // In-progress dot
                        Rectangle {
                            visible: hasProgress
                            width: 6; height: 6; radius: 3
                            color: Color.mTertiary
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: 0.9
                        }

                        Text {
                            text: isWatched ? "✓" : "▶"
                            font.pixelSize: isWatched ? 14 : 13
                            font.bold: isWatched
                            color: isWatched
                                ? Color.mPrimary
                                : hasProgress
                                    ? Color.mTertiary
                                    : (epRowArea.containsMouse ? Color.mPrimary : Color.mOutline)
                            opacity: isWatched ? 0.8
                                : hasProgress ? 0.9
                                : (epRowArea.containsMouse ? 0.9 : 0.35)
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Behavior on color   { ColorAnimation  { duration: 120 } }
                        }

                        Item {
                            id: watchToggleButton
                            width: 28
                            height: 28
                            Layout.alignment: Qt.AlignVCenter
                            z: 2

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: watchToggleArea.containsMouse
                                    ? (isWatched ? Color.mPrimary : Color.mPrimaryContainer)
                                    : Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.7)
                                border.width: 1
                                border.color: isWatched
                                    ? Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.45)
                                    : Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.35)
                                Behavior on color { ColorAnimation { duration: 130 } }
                                Behavior on border.color { ColorAnimation { duration: 130 } }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: isWatched ? "✓" : "+"
                                font.pixelSize: isWatched ? 12 : 14
                                font.bold: true
                                color: isWatched
                                    ? (watchToggleArea.containsMouse ? Color.mOnPrimary : Color.mPrimary)
                                    : (watchToggleArea.containsMouse ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant)
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }

                            MouseArea {
                                id: watchToggleArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    mouse.accepted = true
                                    if (!anime?.currentAnime) return
                                    anime.toggleEpisodeWatched(
                                        anime.currentAnime,
                                        modelData.id,
                                        modelData.number
                                    )
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: epRowArea
                        anchors {
                            fill: parent
                            rightMargin: 52
                        }
                        hoverEnabled: true
                        onClicked: {
                            if (!anime?.currentAnime) return
                            anime.fetchStreamLinks(
                                anime.currentAnime.id,
                                modelData.id,
                                modelData.number
                            )
                        }
                    }
                }
            }
        }
    }

    // ── React to selectedLink ─────────────────────────────────────────────────
    Connections {
        target: anime
        enabled: anime !== null

        function onCurrentAnimeChanged() {
            detailView._lastCenteredEpisodeKey = ""
            detailView.centerPreferredEpisode(true)
        }

        function onSelectedLinkChanged() {
            if (!anime?.selectedLink) return
            var lnk = anime.selectedLink
            if (!lnk.url || lnk.url.length === 0) {
                anime.clearStreamLinks()
                return
            }
            anime.commitPendingEpisodeSelection()
            var title = detailView._streamTitle()
            if (title.length > 0)
                title += " — Ep." + anime.currentEpisode
            anime.playWithMpv(
                lnk.url,
                lnk.referer || "",
                title,
                lnk.http_headers || ({}),
                lnk.type || ""
            )
            anime.clearStreamLinks()
        }

    }
}
