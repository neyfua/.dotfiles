import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root

    property var pluginApi: null
    readonly property string runtimeRoot:
        pluginApi?.manifest?.metadata?.runtimeRoot ?? ""

    function _pathJoin(base, child) {
        if (!base || base.length === 0)
            return child || ""
        if (!child || child.length === 0)
            return base
        if (base.endsWith("/"))
            return base + child
        return base + "/" + child
    }

    function _runtimePath(relativePath) {
        return _pathJoin(_pathJoin(pluginApi?.pluginDir ?? "", runtimeRoot), relativePath)
    }

    readonly property string scriptPath:
        _runtimePath("allanime.py")
    readonly property string luaPath:
        _runtimePath("progress.lua")
    readonly property string progressDir:
        _pathJoin(pluginApi?.pluginDir ?? "", "progress")
    readonly property string feedLibraryPath:
        _pathJoin(pluginApi?.pluginDir ?? "", "anime-library.json")
    readonly property string feedCachePath:
        _pathJoin(pluginApi?.pluginDir ?? "", "anime-feed-cache.json")

    // ── Settings ──────────────────────────────────────────────────────────────
    property string currentMode:
        pluginApi?.pluginSettings?.mode ||
        pluginApi?.manifest?.metadata?.defaultSettings?.mode ||
        "sub"

    property string panelSize:  pluginApi?.pluginSettings?.panelSize  || "medium"
    property string posterSize: pluginApi?.pluginSettings?.posterSize || "medium"
    property string preferredProvider: pluginApi?.pluginSettings?.preferredProvider || "auto"
    property var    browseCache: ({})
    property var    detailCache: ({})

    function _normalisePosterSize(nextPanelSize, nextPosterSize) {
        if (nextPanelSize === "small" && nextPosterSize === "small")
            return "medium"
        return nextPosterSize
    }

    function _deepClone(value) {
        if (value === null || value === undefined)
            return value
        try {
            return JSON.parse(JSON.stringify(value))
        } catch (e) {
            return value
        }
    }

    function _browseCacheKey(args) {
        return args.join("\u241f")
    }

    function _detailCacheKey(showId, mode) {
        return String(showId || "") + "\u241f" + String(mode || "")
    }

    function _formatPlaybackError(stderrTail) {
        var text = String(stderrTail || "").trim()
        if (!text)
            return "Playback failed: no playable stream was opened for this episode."
        if ((text === "Exiting... (Errors when loading file)" || text === "errors while loading file")
                && _mpvLastMeaningfulError.length > 0)
            text = _mpvLastMeaningfulError
        if (text.indexOf("HTTP error 403") !== -1 || text.indexOf("403 Forbidden") !== -1)
            return "Playback failed: the provider rejected this stream."
        if (text.indexOf("HTTP error 404") !== -1 || text.indexOf("404 Not Found") !== -1)
            return "Playback failed: this stream is no longer available."
        if (text.indexOf("Failed to open") !== -1)
            return "Playback failed: mpv could not open the selected stream."
        if (text.indexOf("Errors when loading file") !== -1 && _mpvLastMeaningfulError.length > 0)
            text = _mpvLastMeaningfulError
        if (text.indexOf("Certificate verification failed") !== -1)
            return "Playback failed: the stream provider certificate could not be verified."
        if (text.length > 120)
            text = text.substring(0, 117) + "..."
        return "Playback failed: " + text
    }

    function _normaliseEpisodeList(episodes) {
        return (episodes || []).map(function(ep) {
            return { id: ep.id, number: ep.number }
        }).sort(function(a, b) {
            return Number(a.number) - Number(b.number)
        })
    }

    function setSetting(key, val) {
        if (key === "mode") currentMode = val
        if (key === "preferredProvider") preferredProvider = val

        if (key === "panelSize") {
            panelSize = val
            posterSize = _normalisePosterSize(val, posterSize)
        } else if (key === "posterSize") {
            posterSize = _normalisePosterSize(panelSize, val)
        }
        
        if (pluginApi) {
            pluginApi.pluginSettings[key] = val
            if (key === "panelSize" || key === "posterSize")
                pluginApi.pluginSettings.posterSize = posterSize
            pluginApi.saveSettings()
        }
    }

    function setMode(mode) {
        if (mode !== "sub" && mode !== "dub") return
        if (currentMode === mode) return

        setSetting("mode", mode)
        feedLastFetchedAt = 0

        if (currentAnime)
            fetchAnimeDetail(currentAnime)

        if (currentView === "search" && currentSearchQuery.length > 0)
            searchAnime(currentSearchQuery, true)
        else
            fetchCurrentFeed(true)
    }

    // ── Browse state ──────────────────────────────────────────────────────────
    property var    animeList:       []
    property bool   isFetchingAnime: false
    property string animeError:      ""
    property string currentView:     "top"
    property string browseFeed:      "top"
    property string currentCountry:  "ALL"
    property string currentSearchQuery: ""
    property string currentGenre:    ""
    property var    genresList:      []
    property int    _page:           1
    property bool   _hasMore:        true
    property real   browseScrollY:   0

    // ── Feed state ────────────────────────────────────────────────────────────
    property var    feedList:        []
    property bool   isFetchingFeed:  false
    property string feedError:       ""
    property double feedLastFetchedAt: 0
    property int    feedCooldownMs:  300000

    // ── Library view state ───────────────────────────────────────────────────
    property real libraryScrollY: 0

    // ── Detail state ──────────────────────────────────────────────────────────
    property var  currentAnime:     null
    property bool isFetchingDetail: false
    property string detailFocusEpisodeNum: ""
    property string pendingAutoPlayShowId: ""

    // ── Stream state ──────────────────────────────────────────────────────────
    property var    selectedLink:    null
    property bool   isFetchingLinks: false
    property string linksError:      ""
    property bool   isLaunchingPlayer: false
    property string playbackError:   ""
    property string currentEpisode:  ""
    property string detailError:     ""

    // ── Currently playing ─────────────────────────────────────────────────────
    property string _playingShowId: ""
    property string _playingEpNum:  ""
    property string _pendingEpisodeId: ""
    property string _pendingProgressFile: ""
    property string _activeShowId: ""
    property string _activeEpNum: ""
    property string _activeProgressFile: ""
    property string _queuedUrl: ""
    property string _queuedRef: ""
    property string _queuedTitle: ""
    property string _queuedType: ""
    property var    _queuedHeaders: ({})
    property string _queuedShowId: ""
    property string _queuedEpNum: ""
    property string _queuedProgressFile: ""
    property real _queuedStartPos: 0
    property bool _launchQueued: false
    property double _mpvLaunchStartedAt: 0
    property string _mpvStderrTail: ""
    property string _mpvLastMeaningfulError: ""

    // ── Library ───────────────────────────────────────────────────────────────
    property bool libraryLoaded: false
    property var  libraryList:   []

    // Counter that bumps whenever libraryList changes — views bind to this
    // so watched/in-library checks re-evaluate reactively
    property int libraryVersion: 0

    Component.onCompleted: {
        posterSize = _normalisePosterSize(panelSize, posterSize)
        if (pluginApi && pluginApi.pluginSettings)
            pluginApi.pluginSettings.posterSize = posterSize
        _loadLibrary()
        _ensureProgressDir()
        fetchGenres()
        fetchPopular(true)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function _ensureProgressDir() {
        mkdirProc.command = ["mkdir", "-p", progressDir]
        mkdirProc.running = true
    }

    function _saveLibrary() {
        if (!pluginApi) return
        pluginApi.pluginSettings.library = libraryList
        pluginApi.saveSettings()
        feedLastFetchedAt = 0
        libraryVersion++  // trigger reactive re-evaluation in views
    }

    function _loadLibrary() {
        if (!pluginApi) return
        var raw = pluginApi.pluginSettings?.library
        libraryList = (raw && Array.isArray(raw)) ? raw : []
        libraryLoaded = true
        feedLastFetchedAt = 0
        libraryVersion++
    }

    // ── Library API ───────────────────────────────────────────────────────────
    function isInLibrary(id) {
        var _ = libraryVersion  // reactive dependency
        return libraryList.some(function(e) { return e.id === id })
    }

    function getLibraryEntry(id) {
        var _ = libraryVersion  // reactive dependency
        return libraryList.find(function(e) { return e.id === id }) || null
    }

    function isEpisodeWatched(showId, epNum) {
        var _ = libraryVersion  // reactive dependency
        var entry = libraryList.find(function(e) { return e.id === showId })
        if (!entry) return false
        return (entry.watchedEpisodes || []).indexOf(String(epNum)) !== -1
    }

    function hasEpisodeProgress(showId, epNum) {
        var _ = libraryVersion
        var entry = libraryList.find(function(e) { return e.id === showId })
        if (!entry) return false
        return getEpisodeProgress(showId, epNum) > 0
    }

    function _progressPosition(value) {
        if (typeof value === "number")
            return value
        if (value && typeof value === "object")
            return value.position || 0
        return 0
    }

    function _progressDuration(value) {
        if (value && typeof value === "object")
            return value.duration || 0
        return 0
    }

    function _makeEntry(show, lastEpId, lastEpNum) {
        return {
            id: show.id, name: show.name || "",
            englishName: show.englishName || "",
            nativeName: show.nativeName || "",
            thumbnail: show.thumbnail || "",
            score: show.score || null,
            type: show.type || "",
            episodeCount: show.episodeCount || "",
            availableEpisodes: show.availableEpisodes || {sub:0,dub:0,raw:0},
            season: show.season || null,
            lastWatchedEpId:  lastEpId  ? String(lastEpId)  : "",
            lastWatchedEpNum: lastEpNum ? String(lastEpNum) : "",
            watchedEpisodes:  [],
            episodeProgress:  {},
            updatedAt: Date.now()
        }
    }

    function addToLibrary(show) {
        if (isInLibrary(show.id)) return
        var updated = libraryList.slice()
        updated.push(_makeEntry(show, "", ""))
        libraryList = updated
        _saveLibrary()
    }

    function addToLibraryWithEpisode(show, epId, epNum) {
        if (isInLibrary(show.id)) {
            updateLastWatched(show.id, epId, epNum)
            return
        }
        var updated = libraryList.slice()
        updated.push(_makeEntry(show, epId, epNum))
        libraryList = updated
        _saveLibrary()
    }

    function removeFromLibrary(id) {
        libraryList = libraryList.filter(function(e) { return e.id !== id })
        _saveLibrary()
    }

    function updateLastWatched(showId, epId, epNum) {
        var updated = libraryList.map(function(e) {
            if (e.id !== showId) return e
            return {
                id: e.id, name: e.name, englishName: e.englishName,
                nativeName: e.nativeName, thumbnail: e.thumbnail,
                score: e.score, type: e.type, episodeCount: e.episodeCount,
                availableEpisodes: e.availableEpisodes, season: e.season,
                lastWatchedEpId:  String(epId),
                lastWatchedEpNum: String(epNum),
                watchedEpisodes:  e.watchedEpisodes  || [],
                episodeProgress:  e.episodeProgress  || {},
                updatedAt: Date.now()
            }
        })
        libraryList = updated
        _saveLibrary()
    }

    function markEpisodeWatched(showId, epNum) {
        var updated = libraryList.map(function(e) {
            if (e.id !== showId) return e
            var watched = (e.watchedEpisodes || []).slice()
            if (watched.indexOf(String(epNum)) === -1) watched.push(String(epNum))
            // Clear progress since it's fully watched
            var prog = Object.assign({}, e.episodeProgress || {})
            delete prog[String(epNum)]
            return {
                id: e.id, name: e.name, englishName: e.englishName,
                nativeName: e.nativeName, thumbnail: e.thumbnail,
                score: e.score, type: e.type, episodeCount: e.episodeCount,
                availableEpisodes: e.availableEpisodes, season: e.season,
                lastWatchedEpId:  e.lastWatchedEpId,
                lastWatchedEpNum: e.lastWatchedEpNum,
                watchedEpisodes:  watched,
                episodeProgress:  prog,
                updatedAt: Date.now()
            }
        })
        libraryList = updated
        _saveLibrary()
    }

    function unmarkEpisodeWatched(showId, epNum) {
        var updated = libraryList.map(function(e) {
            if (e.id !== showId) return e
            var watched = (e.watchedEpisodes || []).filter(function(item) {
                return item !== String(epNum)
            })
            return {
                id: e.id, name: e.name, englishName: e.englishName,
                nativeName: e.nativeName, thumbnail: e.thumbnail,
                score: e.score, type: e.type, episodeCount: e.episodeCount,
                availableEpisodes: e.availableEpisodes, season: e.season,
                lastWatchedEpId: e.lastWatchedEpNum === String(epNum) ? "" : e.lastWatchedEpId,
                lastWatchedEpNum: e.lastWatchedEpNum === String(epNum) ? "" : e.lastWatchedEpNum,
                watchedEpisodes: watched,
                episodeProgress: e.episodeProgress || {},
                updatedAt: Date.now()
            }
        })
        libraryList = updated
        _saveLibrary()
    }

    function toggleEpisodeWatched(show, epId, epNum) {
        if (!show || !show.id) return
        if (!isInLibrary(show.id)) {
            addToLibraryWithEpisode(show, epId, epNum)
            markEpisodeWatched(show.id, epNum)
            return
        }
        if (isEpisodeWatched(show.id, epNum))
            unmarkEpisodeWatched(show.id, epNum)
        else {
            updateLastWatched(show.id, epId, epNum)
            markEpisodeWatched(show.id, epNum)
        }
    }

    function markEpisodesThrough(show, epId, epNum, episodeIndex) {
        if (!show || !show.id) return

        var episodes = show.episodes || []
        var endIndex = Number(episodeIndex)
        if (!(endIndex >= 0)) {
            endIndex = episodes.findIndex(function(ep) {
                return String(ep.number) === String(epNum)
            })
        }
        if (endIndex < 0) return

        var watchedMap = {}
        for (var i = 0; i <= endIndex && i < episodes.length; i++)
            watchedMap[String(episodes[i].number)] = true

        var updated = libraryList.slice()
        var existingIndex = updated.findIndex(function(entry) { return entry.id === show.id })
        if (existingIndex === -1) {
            updated.push(_makeEntry(show, epId, epNum))
            existingIndex = updated.length - 1
        }

        var current = updated[existingIndex]
        var mergedWatched = []
        var seen = {}

        episodes.forEach(function(ep) {
            var number = String(ep.number)
            if (watchedMap[number] || (current.watchedEpisodes || []).indexOf(number) !== -1) {
                mergedWatched.push(number)
                seen[number] = true
            }
        })

        ;(current.watchedEpisodes || []).forEach(function(number) {
            number = String(number)
            if (seen[number]) return
            mergedWatched.push(number)
            seen[number] = true
        })

        var prog = Object.assign({}, current.episodeProgress || {})
        Object.keys(watchedMap).forEach(function(number) {
            delete prog[number]
        })

        updated[existingIndex] = {
            id: current.id,
            name: current.name,
            englishName: current.englishName,
            nativeName: current.nativeName,
            thumbnail: current.thumbnail,
            score: current.score,
            type: current.type,
            episodeCount: current.episodeCount,
            availableEpisodes: current.availableEpisodes,
            season: current.season,
            lastWatchedEpId: String(epId || ""),
            lastWatchedEpNum: String(epNum || ""),
            watchedEpisodes: mergedWatched,
            episodeProgress: prog,
            updatedAt: Date.now()
        }

        libraryList = updated
        _saveLibrary()
    }

    function saveEpisodeProgress(showId, epNum, position, duration) {
        var updated = libraryList.map(function(e) {
            if (e.id !== showId) return e
            var prog = Object.assign({}, e.episodeProgress || {})
            prog[String(epNum)] = {
                position: position,
                duration: duration || 0
            }
            return {
                id: e.id, name: e.name, englishName: e.englishName,
                nativeName: e.nativeName, thumbnail: e.thumbnail,
                score: e.score, type: e.type, episodeCount: e.episodeCount,
                availableEpisodes: e.availableEpisodes, season: e.season,
                lastWatchedEpId:  e.lastWatchedEpId,
                lastWatchedEpNum: e.lastWatchedEpNum,
                watchedEpisodes:  e.watchedEpisodes || [],
                episodeProgress:  prog,
                updatedAt: Date.now()
            }
        })
        libraryList = updated
        _saveLibrary()
    }

    function getEpisodeProgress(showId, epNum) {
        var entry = libraryList.find(function(e) { return e.id === showId })
        if (!entry) return 0
        return _progressPosition((entry.episodeProgress || {})[String(epNum)])
    }

    function getEpisodeProgressRatio(showId, epNum) {
        var entry = libraryList.find(function(e) { return e.id === showId })
        if (!entry) return 0
        var progress = (entry.episodeProgress || {})[String(epNum)]
        var position = _progressPosition(progress)
        var duration = _progressDuration(progress)
        if (duration <= 0 || position <= 0) return 0
        return Math.max(0, Math.min(1, position / duration))
    }

    function getContinueWatchingList() {
        var _ = libraryVersion
        return libraryList
            .filter(function(entry) {
                var prog = entry.episodeProgress || {}
                return Object.keys(prog).some(function(key) {
                    return root._progressPosition(prog[key]) > 0
                })
            })
            .sort(function(a, b) {
                return (b.updatedAt || 0) - (a.updatedAt || 0)
            })
    }

    function getNextUnwatchedEpisode(show) {
        if (!show || !show.id) return null
        var episodes = show.episodes || []
        if (episodes.length === 0) return null

        var entry = getLibraryEntry(show.id)
        var lastWatchedNum = entry?.lastWatchedEpNum || ""

        if (lastWatchedNum) {
            var currentIndex = episodes.findIndex(function(ep) {
                return String(ep.number) === String(lastWatchedNum)
            })

            if (currentIndex >= 0) {
                var currentEpisode = episodes[currentIndex]
                if (!isEpisodeWatched(show.id, currentEpisode.number) ||
                    hasEpisodeProgress(show.id, currentEpisode.number))
                    return currentEpisode

                for (var i = currentIndex + 1; i < episodes.length; i++) {
                    if (!isEpisodeWatched(show.id, episodes[i].number))
                        return episodes[i]
                }
            }
        }

        for (var j = 0; j < episodes.length; j++) {
            if (!isEpisodeWatched(show.id, episodes[j].number) ||
                hasEpisodeProgress(show.id, episodes[j].number))
                return episodes[j]
        }

        return episodes[episodes.length - 1] || null
    }

    function playNextUnwatched(show) {
        var nextEpisode = getNextUnwatchedEpisode(show)
        if (!show || !nextEpisode) return
        fetchStreamLinks(show.id, nextEpisode.id, nextEpisode.number)
    }

    function commitPendingEpisodeSelection() {
        if (!currentAnime || !_playingShowId || !_playingEpNum) return
        if (isInLibrary(_playingShowId))
            updateLastWatched(_playingShowId, _pendingEpisodeId, _playingEpNum)
        else
            addToLibraryWithEpisode(currentAnime, _pendingEpisodeId, _playingEpNum)
    }

    function setBrowseScroll(y) {
        browseScrollY = Math.max(0, y || 0)
    }

    function setLibraryScroll(y) {
        libraryScrollY = Math.max(0, y || 0)
    }

    // ── MPV launch & progress tracking ───────────────────────────────────────
    property string _pendingUrl:   ""
    property string _pendingRef:   ""
    property string _pendingTitle: ""
    property string _pendingType:  ""
    property var    _pendingHeaders: ({})

    // Step 1: called from DetailView Connections
    function playWithMpv(url, referer, title, headers, mediaType) {
        if (!url || url.length === 0) return
        playbackError = ""
        isLaunchingPlayer = true
        _pendingUrl   = url
        _pendingRef   = referer
        _pendingTitle = title
        _pendingType  = mediaType || ""
        _pendingHeaders = headers || ({})
        _pendingProgressFile = progressDir + "/" + _playingShowId + "-ep" + _playingEpNum + ".txt"

        // Read existing progress file if it exists (for resume)
        preReadProc.command = [
            "sh", "-c",
            "test -f \"$1\" && cat \"$1\" || printf 'position=0\n'",
            "sh",
            _pendingProgressFile
        ]
        preReadProc._buf = ""
        if (preReadProc.running) preReadProc.running = false
        Qt.callLater(function() { preReadProc.running = true })
    }

    Process {
        id: preReadProc
        property string _buf: ""

        onRunningChanged: {
            if (running) return
            var startPos = 0
            var lines = _buf.split("\n")
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith("position=")) {
                    startPos = parseFloat(line.substring(9)) || 0
                }
            }
            _buf = ""
            _doLaunchMpv(startPos)
        }

        stdout: SplitParser {
            onRead: function(data) { preReadProc._buf += data + "\n" }  // SplitParser strips newlines
        }
    }

    function _startMpvSession(showId, epNum, progressFile, startPos, url, referer, title, headers, mediaType) {
        _activeShowId = showId
        _activeEpNum = epNum
        _activeProgressFile = progressFile
        _mpvLaunchStartedAt = Date.now()
        _mpvStderrTail = ""
        _mpvLastMeaningfulError = ""
        var args = [
            "mpv", "--fs", "--force-window=yes",
            "--title=" + (title || "Anime"),
            "--script=" + luaPath,
            "--script-opts=progress_file=" + progressFile,
        ]
        if (startPos > 5)
            args.push("--start=" + Math.floor(startPos))
        var effectiveHeaders = headers || ({})
        var effectiveReferer = referer || effectiveHeaders["Referer"] || effectiveHeaders["Referrer"] || ""
        if (effectiveReferer && effectiveReferer.length > 0) {
            args.push("--referrer=" + effectiveReferer)
            effectiveHeaders["Referer"] = effectiveReferer
        }
        if (effectiveHeaders["User-Agent"] && effectiveHeaders["User-Agent"].length > 0)
            args.push("--user-agent=" + effectiveHeaders["User-Agent"])
        var extraHeaders = []
        Object.keys(effectiveHeaders).forEach(function(key) {
            if (key === "User-Agent" || key === "Referrer")
                return
            var value = String(effectiveHeaders[key] || "")
            if (value.length > 0)
                extraHeaders.push(key + ": " + value)
        })
        if (extraHeaders.length > 0)
            args.push("--http-header-fields=" + extraHeaders.join(","))
        if (mediaType === "hls") {
            args.push("--demuxer-lavf-o=protocol_whitelist=file,http,https,tcp,tls,crypto,data")
            args.push("--load-unsafe-playlists=yes")
        }
        args.push(url)

        mpvProcess.command = args
        mpvProcess.running = true
    }

    function _doLaunchMpv(startPos) {
        var showId = _playingShowId
        var epNum = _playingEpNum
        var progressFile = _pendingProgressFile
        var url = _pendingUrl
        var referer = _pendingRef
        var title = _pendingTitle
        var mediaType = _pendingType
        var headers = _pendingHeaders

        if (mpvProcess.running) {
            _queuedShowId = showId
            _queuedEpNum = epNum
            _queuedProgressFile = progressFile
            _queuedUrl = url
            _queuedRef = referer
            _queuedTitle = title
            _queuedType = mediaType
            _queuedHeaders = headers
            _queuedStartPos = startPos
            _launchQueued = true
            mpvProcess.running = false
            return
        }

        _startMpvSession(showId, epNum, progressFile, startPos, url, referer, title, headers, mediaType)
    }

    Process {
        id: mpvProcess

        onRunningChanged: {
            if (running) {
                root.isLaunchingPlayer = false
                return
            }
            root.isLaunchingPlayer = false
            if (!root._activeProgressFile) return
            // mpv exited — read the progress file
            postReadProc.command = [
                "sh", "-c",
                "test -f \"$1\" && cat \"$1\" || printf 'duration=0\nposition=0\n'",
                "sh",
                root._activeProgressFile
            ]
            postReadProc._buf    = ""
            postReadProc._showId = root._activeShowId
            postReadProc._epNum  = root._activeEpNum
            postReadProc._pfile  = root._activeProgressFile
            postReadProc._stderrTail = root._mpvStderrTail
            postReadProc._launchStartedAt = root._mpvLaunchStartedAt
            if (postReadProc.running) postReadProc.running = false
            Qt.callLater(function() { postReadProc.running = true })
        }

        stderr: SplitParser {
            onRead: function(data) {
                var line = (data || "").trim()
                if (line.length === 0) return
                root._mpvStderrTail = line
                if (line.indexOf("Exiting...") === -1 && line.indexOf("errors while loading file") === -1)
                    root._mpvLastMeaningfulError = line
                Logger.w("Anime", "mpv:", line)
            }
        }
        stdout: SplitParser {
            onRead: function(data) {
                var line = (data || "").trim()
                if (line.length === 0) return
                root._mpvStderrTail = line
                if (line.indexOf("Exiting...") === -1 && line.indexOf("errors while loading file") === -1)
                    root._mpvLastMeaningfulError = line
                Logger.w("Anime", "mpv:", line)
            }
        }
    }

    Process {
        id: postReadProc
        property string _buf:    ""
        property string _showId: ""
        property string _epNum:  ""
        property string _pfile:  ""
        property string _stderrTail: ""
        property double _launchStartedAt: 0

        onRunningChanged: {
            if (running) return
            var dur = 0, pos = 0
            var lines = _buf.split("\n")
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith("duration=")) dur = parseFloat(line.substring(9)) || 0
                if (line.startsWith("position=")) pos = parseFloat(line.substring(9)) || 0
            }
            _buf = ""
            var ranBriefly = _launchStartedAt > 0 && (Date.now() - _launchStartedAt) < 2500

            if (dur > 0 && pos > 0) {
                if (pos / dur >= 0.85) {
                    // Fully watched
                    root.markEpisodeWatched(_showId, _epNum)
                    // Delete the progress file
                    rmProc.command = ["rm", "-f", _pfile]
                    rmProc.running = true
                } else {
                    // Partially watched — save position
                    root.saveEpisodeProgress(_showId, _epNum, pos, dur)
                }
            } else if (ranBriefly) {
                root.playbackError = root._formatPlaybackError(_stderrTail)
            }

            root._activeShowId = ""
            root._activeEpNum = ""
            root._activeProgressFile = ""
            root._mpvLaunchStartedAt = 0
            root._mpvStderrTail = ""
            root._mpvLastMeaningfulError = ""
            _stderrTail = ""
            _launchStartedAt = 0

            if (root._launchQueued) {
                var nextShowId = root._queuedShowId
                var nextEpNum = root._queuedEpNum
                var nextProgressFile = root._queuedProgressFile
                var nextStartPos = root._queuedStartPos
                var nextUrl = root._queuedUrl
                var nextRef = root._queuedRef
                var nextTitle = root._queuedTitle
                var nextType = root._queuedType
                var nextHeaders = root._queuedHeaders

                root._launchQueued = false
                root._queuedShowId = ""
                root._queuedEpNum = ""
                root._queuedProgressFile = ""
                root._queuedStartPos = 0
                root._queuedUrl = ""
                root._queuedRef = ""
                root._queuedTitle = ""
                root._queuedType = ""
                root._queuedHeaders = ({})

                root._startMpvSession(
                    nextShowId,
                    nextEpNum,
                    nextProgressFile,
                    nextStartPos,
                    nextUrl,
                    nextRef,
                    nextTitle,
                    nextHeaders,
                    nextType
                )
            }
        }

        stdout: SplitParser {
            onRead: function(data) { postReadProc._buf += data + "\n" }
        }
    }

    // ── Utility processes ────────────────────────────────────────────────────
    Process { id: mkdirProc }
    Process { id: rmProc }

    Process {
        id: feedWriteProc
        property string _payload: ""
        property bool _force: false

        onRunningChanged: {
            if (running) return
            root._runFeedCommand(_force)
        }
    }

    // ── Browse processes ──────────────────────────────────────────────────────
    Process {
        id: genreProc
        property string _buf: ""
        onRunningChanged: {
            if (running) return
            if (_buf.length === 0) return
            try {
                root.genresList = JSON.parse(_buf)
            } catch(e) { Logger.w("Anime", "genres parse error:", e) }
            _buf = ""
        }
        stdout: SplitParser {
            onRead: function(data) { genreProc._buf += data }
        }
    }

    Process {
        id: browseProc
        property string _buf:   ""
        property bool   _reset: true
        property string _cacheKey: ""

        onRunningChanged: {
            if (running) return
            root.isFetchingAnime = false
            if (_buf.length === 0) return
            try {
                var d = JSON.parse(_buf)
                if (d.error) { root.animeError = d.error; _buf = ""; return }
                root.browseCache[_cacheKey] = root._deepClone({
                    results: d.results || [],
                    hasNextPage: d.hasNextPage || false
                })
                var results = d.results || []
                root.animeList = _reset ? results : root.animeList.concat(results)
                root._hasMore = d.hasNextPage || false
                root._page++
            } catch(e) { root.animeError = "Parse error: " + e }
            _buf = ""
        }

        stdout: SplitParser {
            onRead: function(data) { browseProc._buf += data }
        }
        stderr: SplitParser {
            onRead: function(data) {
                if (data.trim().length > 0) Logger.w("Anime", "browse:", data)
            }
        }
    }

    Process {
        id: detailProc
        property string _buf:  ""
        property var    _show: null
        property string _cacheKey: ""

        onRunningChanged: {
            if (running) return
            root.isFetchingDetail = false
            if (_buf.length === 0) return
            try {
                var d = JSON.parse(_buf)
                if (d.error) { root.detailError = d.error; _buf = ""; return }
                if (_show) {
                    var enriched = Object.assign({}, _show)
                    enriched.episodes = root._normaliseEpisodeList(d.episodes || [])
                    if (d.description) enriched.description = d.description
                    if (d.thumbnail)   enriched.thumbnail   = d.thumbnail
                    root.detailCache[_cacheKey] = root._deepClone(enriched)
                    root.currentAnime = enriched
                    root._maybeAutoPlayPendingShow(enriched)
                }
            } catch(e) {
                root.detailError = "Parse error: " + e
                Logger.w("Anime", "detail error:", e)
            }
            _buf = ""
        }

        stdout: SplitParser {
            onRead: function(data) { detailProc._buf += data }
        }
        stderr: SplitParser {
            onRead: function(data) {
                if (data.trim().length > 0) Logger.w("Anime", "detail:", data)
            }
        }
    }

    Process {
        id: feedProc
        property string _buf: ""

        onRunningChanged: {
            if (running) return
            root.isFetchingFeed = false
            if (_buf.length === 0) return
            try {
                var d = JSON.parse(_buf)
                if (d.error) {
                    root.feedError = d.error
                    _buf = ""
                    return
                }
                root.feedList = d.results || []
                root.feedError = ""
                root.feedLastFetchedAt = Date.now()
            } catch(e) {
                root.feedError = "Parse error: " + e
                Logger.w("Anime", "feed error:", e)
            }
            _buf = ""
        }

        stdout: SplitParser {
            onRead: function(data) { feedProc._buf += data }
        }
        stderr: SplitParser {
            onRead: function(data) {
                if (data.trim().length > 0) Logger.w("Anime", "feed:", data)
            }
        }
    }

    Process {
        id: streamProc
        property string _buf: ""

        onRunningChanged: {
            if (running) return
            root.isFetchingLinks = false
            if (_buf.length === 0) return
            try {
                var d = JSON.parse(_buf)
                if (d.error) { root.linksError = d.error; _buf = ""; return }
                root.selectedLink = d
            } catch(e) { root.linksError = "Parse error: " + e }
            _buf = ""
        }

        stdout: SplitParser {
            onRead: function(data) { streamProc._buf += data }
        }
        stderr: SplitParser {
            onRead: function(data) {
                if (data.trim().length > 0) Logger.w("Anime", "stream:", data)
            }
        }
    }

    // ── Internal browse helper ────────────────────────────────────────────────
    function _runBrowse(args, reset) {
        var cacheKey = _browseCacheKey(args)
        if (browseCache[cacheKey]) {
            var cached = _deepClone(browseCache[cacheKey])
            animeError = ""
            isFetchingAnime = false
            animeList = reset ? (cached.results || []) : animeList.concat(cached.results || [])
            _hasMore = cached.hasNextPage || false
            _page++
            return
        }
        browseProc._buf   = ""
        browseProc._reset = reset
        browseProc._cacheKey = cacheKey
        browseProc.command = ["python3", scriptPath].concat(args)
        isFetchingAnime = true
        animeError = ""
        if (browseProc.running) {
            browseProc.running = false
            Qt.callLater(function() { browseProc.running = true })
        } else {
            browseProc.running = true
        }
    }

    // ── Public API ────────────────────────────────────────────────────────────
    function fetchGenres() {
        if (genresList.length > 0) return
        genreProc._buf = ""
        genreProc.command = ["python3", scriptPath, "genres"]
        genreProc.running = true
    }

    function _runFeedCommand(forceRefresh) {
        feedProc._buf = ""
        feedProc.command = [
            "python3", scriptPath, "feed",
            feedLibraryPath, currentMode, feedCachePath
        ]
        isFetchingFeed = true
        feedError = ""
        if (forceRefresh === true)
            feedLastFetchedAt = 0
        if (feedProc.running) {
            feedProc.running = false
            Qt.callLater(function() { feedProc.running = true })
        } else {
            feedProc.running = true
        }
    }

    function fetchFollowingFeed(forceRefresh) {
        if (!libraryLoaded) return
        if ((libraryList || []).length === 0) {
            feedList = []
            feedError = ""
            feedLastFetchedAt = Date.now()
            return
        }
        var now = Date.now()
        if (!forceRefresh && feedList.length > 0 && (now - feedLastFetchedAt) < feedCooldownMs)
            return

        feedWriteProc._payload = JSON.stringify(libraryList || [])
        feedWriteProc._force = forceRefresh === true
        feedWriteProc.command = [
            "sh", "-c",
            "printf '%s' \"$1\" > \"$2\"",
            "sh",
            feedWriteProc._payload,
            feedLibraryPath
        ]
        if (feedWriteProc.running) {
            feedWriteProc.running = false
            Qt.callLater(function() { feedWriteProc.running = true })
        } else {
            feedWriteProc.running = true
        }
    }

    function setGenre(genre) {
        if (currentGenre === genre) return
        currentGenre = genre
        if (currentView === "search" && currentSearchQuery.length > 0)
            searchAnime(currentSearchQuery, true)
        else
            fetchCurrentFeed(true)
    }

    function fetchCurrentFeed(reset) {
        if (browseFeed === "recent")
            fetchRecent(reset)
        else
            fetchPopular(reset)
    }

    function fetchPopular(reset) {
        if (reset) { _page = 1; _hasMore = true }
        if (!_hasMore || isFetchingAnime) return
        browseFeed = "top"
        currentView = "top"
        currentSearchQuery = ""
        var args = ["popular", String(_page), currentMode]
        if (currentGenre) args.push(currentGenre)
        _runBrowse(args, reset || _page === 1)
    }

    function fetchRecent(reset) {
        if (reset) { _page = 1; _hasMore = true }
        if (!_hasMore || isFetchingAnime) return
        browseFeed = "recent"
        currentView = "recent"
        currentSearchQuery = ""
        var args = ["recent", String(_page), currentMode, currentCountry]
        _runBrowse(args, reset || _page === 1)
    }

    function fetchNextPage() {
        if (currentView === "search")
            searchAnime(currentSearchQuery, false)
        else if (browseFeed === "recent")
            fetchRecent(false)
        else
            fetchPopular(false)
    }

    function searchAnime(query, reset) {
        if (reset) { _page = 1; _hasMore = true }
        if (isFetchingAnime) return
        currentView = "search"
        currentSearchQuery = query
        var args = ["search", query, currentMode, String(_page)]
        if (currentGenre) args.push(currentGenre)
        _runBrowse(args, reset || _page === 1)
    }

    function fetchAnimeDetail(show) {
        pendingAutoPlayShowId = ""
        detailFocusEpisodeNum = ""
        _fetchAnimeDetail(show)
    }

    function openAnimeDetail(show, focusEpisodeNum) {
        pendingAutoPlayShowId = ""
        detailFocusEpisodeNum = focusEpisodeNum ? String(focusEpisodeNum) : ""
        _fetchAnimeDetail(show)
    }

    function playNextForShow(show, focusEpisodeNum) {
        if (!show || !show.id) return
        pendingAutoPlayShowId = String(show.id)
        detailFocusEpisodeNum = focusEpisodeNum ? String(focusEpisodeNum) : ""
        _fetchAnimeDetail(show)
    }

    function _maybeAutoPlayPendingShow(show) {
        if (!show || !show.id) return
        if (String(show.id) !== String(pendingAutoPlayShowId || ""))
            return
        pendingAutoPlayShowId = ""
        Qt.callLater(function() {
            if (!currentAnime || String(currentAnime.id) !== String(show.id))
                return
            playNextUnwatched(currentAnime)
        })
    }

    function _fetchAnimeDetail(show) {
        currentAnime = show
        detailError = ""
        var cacheKey = _detailCacheKey(show?.id, currentMode)
        if (detailCache[cacheKey]) {
            var cachedDetail = _deepClone(detailCache[cacheKey])
            cachedDetail.episodes = _normaliseEpisodeList(cachedDetail.episodes || [])
            currentAnime = Object.assign({}, show, cachedDetail)
            isFetchingDetail = false
            _maybeAutoPlayPendingShow(currentAnime)
            if (detailProc.running) detailProc.running = false
            return
        }
        detailProc._buf  = ""
        detailProc._show = show
        detailProc._cacheKey = cacheKey
        detailProc.command = ["python3", scriptPath, "episodes", show.id, currentMode]
        isFetchingDetail = true
        if (detailProc.running) {
            detailProc.running = false
            Qt.callLater(function() { detailProc.running = true })
        } else {
            detailProc.running = true
        }
    }

    function clearDetail() {
        currentAnime = null
        detailFocusEpisodeNum = ""
        pendingAutoPlayShowId = ""
        if (detailProc.running) detailProc.running = false
    }

    function fetchStreamLinks(showId, epId, epNum) {
        if (!currentAnime) return
        _playingShowId  = showId
        _playingEpNum   = String(epNum)
        _pendingEpisodeId = String(epId || "")
        currentEpisode  = String(epNum)
        linksError      = ""
        playbackError  = ""
        selectedLink    = null
        isFetchingLinks = true
        streamProc._buf  = ""
        streamProc.command = ["python3", scriptPath, "stream",
                              showId, String(epNum), currentMode,
                              preferredProvider, "best"]
        if (streamProc.running) {
            streamProc.running = false
            Qt.callLater(function() { streamProc.running = true })
        } else {
            streamProc.running = true
        }
    }

    function clearStreamLinks() {
        selectedLink   = null
        linksError     = ""
        currentEpisode = ""
        _pendingEpisodeId = ""
    }
}
