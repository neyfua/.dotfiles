#!/usr/bin/env python3
"""
allanime.py — AllAnime API helper for the Noctalia anime plugin.
No third-party dependencies; uses only stdlib.

Usage:
  python3 allanime.py search <query> [sub|dub] [page]
  python3 allanime.py popular [page] [sub|dub]
  python3 allanime.py recent [page] [sub|dub] [country]
  python3 allanime.py latest [page] [sub|dub] [country]
  python3 allanime.py episodes <show_id> [sub|dub]
  python3 allanime.py feed <library_json_path> [sub|dub] [cache_json_path]
  python3 allanime.py stream <show_id> <episode_number> [sub|dub]

All output is JSON on stdout. Errors are {"error": "..."} with exit code 1.
"""

import json
import sys
import urllib.request
import urllib.error
import re
import time
from pathlib import Path
from datetime import datetime, timedelta, timezone

# ── Constants ─────────────────────────────────────────────────────────────────
API     = "https://api.allanime.day/api"
REFERER = "https://allmanga.to"
AGENT   = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0"
BASE    = "allanime.day"

# ── GQL queries (single-line — multiline breaks the API) ──────────────────────
_Q_SHOWS = "query($search:SearchInput $limit:Int $page:Int $translationType:VaildTranslationTypeEnumType $countryOrigin:VaildCountryOriginEnumType){shows(search:$search limit:$limit page:$page translationType:$translationType countryOrigin:$countryOrigin){edges{_id name englishName nativeName thumbnail score type season availableEpisodes}}}"

_Q_EPISODES = "query($showId:String!){show(_id:$showId){_id name englishName description thumbnail availableEpisodesDetail lastEpisodeDate status}}"

_Q_STREAM = "query($showId:String! $translationType:VaildTranslationTypeEnumType! $episodeString:String!){episode(showId:$showId translationType:$translationType episodeString:$episodeString){episodeString sourceUrls}}"

_GENRES = [
    "Action", "Adventure", "Comedy", "Drama", "Ecchi", "Fantasy", "Horror", 
    "Mahou Shoujo", "Mecha", "Music", "Mystery", "Psychological", "Romance", 
    "Sci-Fi", "Slice of Life", "Sports", "Supernatural", "Thriller"
]

_PROVIDER_PRIORITY = {
    "auto": ["Default", "S-mp4", "Luf-Mp4", "Yt-mp4"],
    "default": ["Default", "S-mp4", "Luf-Mp4", "Yt-mp4"],
    "sharepoint": ["S-mp4", "Default", "Luf-Mp4", "Yt-mp4"],
    "hianime": ["Luf-Mp4", "Default", "S-mp4", "Yt-mp4"],
    "youtube": ["Yt-mp4", "Default", "S-mp4", "Luf-Mp4"],
}

# ── Hex-decode table (from ani-cli provider_init) ─────────────────────────────
_HEX = {
    "79":"A","7a":"B","7b":"C","7c":"D","7d":"E","7e":"F","7f":"G","70":"H",
    "71":"I","72":"J","73":"K","74":"L","75":"M","76":"N","77":"O","68":"P",
    "69":"Q","6a":"R","6b":"S","6c":"T","6d":"U","6e":"V","6f":"W","60":"X",
    "61":"Y","62":"Z","59":"a","5a":"b","5b":"c","5c":"d","5d":"e","5e":"f",
    "5f":"g","50":"h","51":"i","52":"j","53":"k","54":"l","55":"m","56":"n",
    "57":"o","48":"p","49":"q","4a":"r","4b":"s","4c":"t","4d":"u","4e":"v",
    "4f":"w","40":"x","41":"y","42":"z","08":"0","09":"1","0a":"2","0b":"3",
    "0c":"4","0d":"5","0e":"6","0f":"7","00":"8","01":"9","15":"-","16":".",
    "67":"_","46":"~","02":":","17":"/","07":"?","1b":"#","63":"[","65":"]",
    "78":"@","19":"!","1c":"$","1e":"&","10":"(","11":")","12":"*","13":"+",
    "14":",","03":";","05":"=","1d":"%",
}

def _decode_url(encoded):
    pairs = [encoded[i:i+2] for i in range(0, len(encoded), 2)]
    return "".join(_HEX.get(p, p) for p in pairs).replace("/clock", "/clock.json")

# ── HTTP ──────────────────────────────────────────────────────────────────────
def _gql(variables, query):
    body = json.dumps({"variables": variables, "query": query},
                      separators=(",", ":")).encode()
    req = urllib.request.Request(API, data=body, headers={
        "Content-Type": "application/json",
        "Referer":      REFERER,
        "User-Agent":   AGENT,
    })
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.loads(r.read().decode())

def _fetch(url):
    req = urllib.request.Request(url, headers={
        "Referer":    REFERER,
        "User-Agent": AGENT,
    })
    with urllib.request.urlopen(req, timeout=15) as r:
        return r.read().decode(errors="replace")

# ── Normalise ─────────────────────────────────────────────────────────────────
def _normalise(edge):
    thumb = edge.get("thumbnail") or ""

    avail = edge.get("availableEpisodes") or {}
    return {
        "id":          edge.get("_id", ""),
        "name":        edge.get("name", ""),
        "englishName": edge.get("englishName") or edge.get("name", ""),
        "nativeName":  edge.get("nativeName", ""),
        "thumbnail":   thumb,
        "score":       edge.get("score"),
        "type":        edge.get("type", ""),
        "availableEpisodes": {
            "sub": avail.get("sub", 0),
            "dub": avail.get("dub", 0),
            "raw": avail.get("raw", 0),
        },
        "season": edge.get("season"),
    }

def _parse_episode_number(value):
    text = str(value or "").strip()
    if not text:
        return None
    match = re.search(r"\d+(?:\.\d+)?", text)
    if not match:
        return None
    try:
        return float(match.group(0))
    except Exception:
        return None

def _format_episode_number(value):
    number = _parse_episode_number(value)
    if number is None:
        return str(value or "").strip()
    if number.is_integer():
        return str(int(number))
    return ("%s" % number).rstrip("0").rstrip(".")

def _episode_sort_key(value):
    number = _parse_episode_number(value)
    if number is None:
        return -1
    return number

def _load_json_file(path, default):
    if not path:
        return default
    file_path = Path(path)
    if not file_path.exists():
        return default
    try:
        return json.loads(file_path.read_text(encoding="utf-8"))
    except Exception:
        return default

def _save_json_file(path, data):
    if not path:
        return
    file_path = Path(path)
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )

def _extract_episode_numbers(show_detail, mode):
    detail = (show_detail or {}).get("availableEpisodesDetail") or {}
    episodes = detail.get(mode) or []
    cleaned = []
    for episode in episodes:
        text = _format_episode_number(episode)
        if not text:
            continue
        cleaned.append(text)
    cleaned = sorted(set(cleaned), key=_episode_sort_key)
    return cleaned

def _extract_last_episode_date(show_detail, mode):
    detail = (show_detail or {}).get("lastEpisodeDate") or {}
    mode_value = detail.get(mode) or {}
    if not isinstance(mode_value, dict):
        return ""
    year = mode_value.get("year")
    month = mode_value.get("month")
    day = mode_value.get("date")
    hour = mode_value.get("hour", 0) or 0
    minute = mode_value.get("minute", 0) or 0
    if not year or not month or not day:
        return ""
    try:
        dt = datetime(
            int(year),
            int(month),
            int(day),
            int(hour),
            int(minute),
            tzinfo=timezone.utc,
        )
    except Exception:
        return ""
    return dt.isoformat()

def _episode_cache_key(show_id, mode):
    return f"{show_id}:{mode}"

def _get_cached_episode_numbers(cache, show_id, mode, now_ts, ttl_seconds):
    entry = (cache or {}).get(_episode_cache_key(show_id, mode)) or {}
    fetched_at = float(entry.get("fetchedAt") or 0)
    if fetched_at <= 0 or (now_ts - fetched_at) > ttl_seconds:
        return None
    episodes = entry.get("episodes") or []
    last_episode_date = entry.get("lastEpisodeDate") or ""
    if not isinstance(episodes, list) or not episodes or not last_episode_date:
        return None
    return {
        "episodes": [_format_episode_number(ep) for ep in episodes if _format_episode_number(ep)],
        "thumbnail": entry.get("thumbnail") or "",
        "lastEpisodeDate": last_episode_date,
    }

def _store_cached_episode_numbers(cache, show_id, mode, episodes, thumbnail, last_episode_date, now_ts):
    cache[_episode_cache_key(show_id, mode)] = {
        "episodes": [_format_episode_number(ep) for ep in episodes if _format_episode_number(ep)],
        "thumbnail": thumbnail or "",
        "lastEpisodeDate": last_episode_date or "",
        "fetchedAt": now_ts,
    }

def _fetch_show_detail(show_id):
    data = _gql({"showId": show_id}, _Q_EPISODES)
    return (data.get("data") or {}).get("show") or {}

def _has_consistent_recent_history(entry, episode_numbers):
    watched_numbers = {
        _format_episode_number(value)
        for value in (entry.get("watchedEpisodes") or [])
        if _format_episode_number(value)
    }
    last_watched = _parse_episode_number(entry.get("lastWatchedEpNum"))
    if last_watched is None or last_watched <= 0:
        return False

    start = max(1, int(last_watched) - 4)
    end = int(last_watched)
    available_set = { _format_episode_number(ep) for ep in episode_numbers }

    for current in range(start, end + 1):
        label = str(current)
        if label not in available_set:
            return False
        if label not in watched_numbers:
            return False
    return True

def _parse_iso_datetime(value):
    text = str(value or "").strip()
    if not text:
        return None
    try:
        if text.endswith("Z"):
            text = text[:-1] + "+00:00"
        dt = datetime.fromisoformat(text)
    except Exception:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

def _is_recent_enough(last_episode_date, days=90):
    dt = _parse_iso_datetime(last_episode_date)
    if dt is None:
        return False
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    return dt >= cutoff

def build_feed_items(library_entries, episode_map):
    items = []
    for entry in library_entries or []:
        show_id = entry.get("id") or ""
        if not show_id:
            continue

        last_watched = _parse_episode_number(entry.get("lastWatchedEpNum"))
        if last_watched is None or last_watched <= 0:
            continue

        episode_numbers = [
            _format_episode_number(ep)
            for ep in (episode_map.get(show_id) or {}).get("episodes", [])
            if _format_episode_number(ep)
        ]
        episode_numbers = sorted(set(episode_numbers), key=_episode_sort_key)
        if not episode_numbers:
            continue

        last_episode_date = (episode_map.get(show_id) or {}).get("lastEpisodeDate") or ""
        if not _is_recent_enough(last_episode_date):
            continue

        latest_available = _parse_episode_number(episode_numbers[-1])
        if latest_available is None or latest_available <= last_watched:
            continue

        gap = latest_available - last_watched
        if gap <= 0 or gap > 3:
            continue

        if not _has_consistent_recent_history(entry, episode_numbers):
            continue

        new_episodes = []
        for episode in episode_numbers:
            parsed = _parse_episode_number(episode)
            if parsed is not None and parsed > last_watched:
                new_episodes.append(episode)
        if not new_episodes:
            continue

        title = entry.get("englishName") or entry.get("name") or ""
        poster = entry.get("thumbnail") or (episode_map.get(show_id) or {}).get("thumbnail") or ""

        items.append({
            "id": show_id,
            "title": title,
            "poster": poster,
            "nextEpisode": _format_episode_number(new_episodes[0]),
            "newCount": len(new_episodes),
            "_sortGap": gap,
            "_sortLatest": latest_available,
        })

    items.sort(key=lambda item: (item["_sortGap"], -item["_sortLatest"], item["title"].lower()))
    for item in items:
        item.pop("_sortGap", None)
        item.pop("_sortLatest", None)
    return items

def _shows(search_obj, page, mode, country="ALL"):
    data = _gql({
        "search":          search_obj,
        "limit":           40,
        "page":            page,
        "translationType": mode,
        "countryOrigin":   country,
    }, _Q_SHOWS)
    edges = (data.get("data") or {}).get("shows", {}).get("edges") or []
    results = [_normalise(e) for e in edges]
    print(json.dumps({"results": results, "hasNextPage": len(results) == 40}))

def _shows_with_fallbacks(search_variants, page, mode, country="ALL"):
    last_error = None
    for search_obj in search_variants:
        try:
            _shows(search_obj, page, mode, country)
            return
        except urllib.error.HTTPError as e:
            if e.code not in (400, 500):
                raise
            last_error = e
            continue

    if last_error:
        raise last_error
    raise RuntimeError("No working feed query variant found")

# ── Commands ──────────────────────────────────────────────────────────────────
def cmd_popular(page=1, mode="sub", genre=None):
    search = {"allowAdult": False, "allowUnknown": False}
    if genre:
        search["genres"] = [genre]
    _shows_with_fallbacks([
        dict(search, sortBy="Top"),
        dict(search, sortBy="Popular"),
        dict(search, sortBy="Trending"),
        search,
    ], page, mode)

def cmd_recent(page=1, mode="sub", country="ALL"):
    search = {"allowAdult": False, "allowUnknown": False}
    _shows_with_fallbacks([
        dict(search, sortBy="Recent"),
        dict(search, sortBy="Latest_Update"),
        dict(search, sortBy="Trending"),
        search,
    ], page, mode, country)

def cmd_latest(page=1, mode="sub", country="ALL"):
    cmd_recent(page, mode, country)

def cmd_search(query, mode="sub", page=1, genre=None):
    search = {"allowAdult": False, "allowUnknown": False, "query": query}
    if genre:
        search["genres"] = [genre]
    _shows(search, page, mode)

def cmd_genres():
    print(json.dumps(_GENRES))

def cmd_episodes(show_id, mode="sub"):
    data = _gql({"showId": show_id}, _Q_EPISODES)
    show = (data.get("data") or {}).get("show") or {}
    detail = show.get("availableEpisodesDetail") or {}
    eps = detail.get(mode) or []
    episodes = [{"id": f"{show_id}-episode-{ep}", "number": ep} for ep in eps]
    # Clean HTML entities from description
    import html
    desc = html.unescape(show.get("description") or "")
    # Strip remaining HTML tags
    import re
    desc = re.sub(r"<[^>]+>", " ", desc).strip()
    desc = re.sub(r" {2,}", " ", desc)
    print(json.dumps({
        "episodes": episodes,
        "episodeDetail": detail,
        "description": desc,
        "thumbnail": show.get("thumbnail") or "",
    }))

def cmd_feed(library_path, mode="sub", cache_path=""):
    library_data = _load_json_file(library_path, [])
    if not isinstance(library_data, list):
        raise RuntimeError("Invalid library file format")

    cache = _load_json_file(cache_path, {}) if cache_path else {}
    if not isinstance(cache, dict):
        cache = {}

    now_ts = time.time()
    ttl_seconds = 300
    episode_map = {}

    for entry in library_data:
        show_id = entry.get("id") or ""
        if not show_id:
            continue

        cached_episodes = _get_cached_episode_numbers(cache, show_id, mode, now_ts, ttl_seconds)
        if cached_episodes is not None:
            episode_map[show_id] = {
                "episodes": cached_episodes.get("episodes") or [],
                "thumbnail": entry.get("thumbnail") or cached_episodes.get("thumbnail") or "",
                "lastEpisodeDate": cached_episodes.get("lastEpisodeDate") or "",
            }
            continue

        show = _fetch_show_detail(show_id)
        episodes = _extract_episode_numbers(show, mode)
        thumbnail = show.get("thumbnail") or entry.get("thumbnail") or ""
        last_episode_date = _extract_last_episode_date(show, mode)
        _store_cached_episode_numbers(cache, show_id, mode, episodes, thumbnail, last_episode_date, now_ts)
        episode_map[show_id] = {
            "episodes": episodes,
            "thumbnail": thumbnail,
            "lastEpisodeDate": last_episode_date,
        }

    if cache_path:
        _save_json_file(cache_path, cache)

    print(json.dumps({"results": build_feed_items(library_data, episode_map)}))

def _pick_quality(links, quality_pref):
    def _res(pair):
        return _resolution_value(pair[1])

    links = sorted(links, key=_res, reverse=True)
    if quality_pref == "best":
        return links[0]

    try:
        target = int(str(quality_pref).rstrip("p"))
    except Exception:
        return links[0]

    at_or_below = [pair for pair in links if _res(pair) <= target]
    if at_or_below:
        return at_or_below[0]
    return links[-1]

def _resolution_value(value):
    text = str(value or "").strip().lower()
    match = re.search(r"(\d+)", text)
    if match:
        try:
            return int(match.group(1))
        except Exception:
            return 0
    return 0

def _json_unescape(value):
    text = str(value or "")
    try:
        return json.loads('"' + text.replace('"', '\\"') + '"')
    except Exception:
        return text.replace("\\/", "/").replace("\\u0026", "&")

def _build_quality_variants(links):
    variants = []
    seen = set()
    for url, res in sorted(links, key=lambda pair: _resolution_value(pair[1]), reverse=True):
        url = _json_unescape(url)
        if "repackager.wixmp.com" in url:
            url = re.sub(r"repackager\.wixmp\.com/", "", url)
            url = re.sub(r"\.urlset.*", "", url)
        label = _normalise_variant_label(res, "mp4")
        key = (url, label)
        if key in seen:
            continue
        seen.add(key)
        variants.append({
            "url": url,
            "quality": label,
            "label": label,
            "type": "mp4",
        })
    return variants

def _is_direct_mp4_quality(label):
    text = str(label or "").strip().lower()
    if _resolution_value(text) > 0:
        return True
    return text in ("source", "default", "original")

def _normalise_variant_label(label, stream_type="mp4"):
    text = str(label or "").strip()
    lowered = text.lower()
    if stream_type == "hls" or lowered in ("hls", "m3u8", "auto"):
        return "Auto"
    return text or "Auto"

def _stringify_error(exc):
    text = str(exc).strip()
    return text or exc.__class__.__name__

def _normalise_provider_failure(provider, reason):
    return {
        "provider": provider,
        "reason": reason,
    }

def _summarise_provider_failures(failures):
    if not failures:
        return "No playable stream was available for this episode."

    summary = []
    for failure in failures[:3]:
        summary.append(f"{failure['provider']}: {failure['reason']}")

    detail = "; ".join(summary)
    if len(failures) > 3:
        detail += f"; +{len(failures) - 3} more"

    if all(f["reason"] == "source unavailable" for f in failures):
        return "No compatible providers were available for this episode."

    return f"No playable stream was available for this episode. {detail}"

def cmd_stream(show_id, ep_num, mode="sub", provider_pref="auto", quality_pref="best"):
    data = _gql({
        "showId": show_id,
        "translationType": mode,
        "episodeString": ep_num,
    }, _Q_STREAM)

    ep = ((data.get("data") or {}).get("episode")) or {}
    source_urls = ep.get("sourceUrls") or []
    if not source_urls:
        print(json.dumps({
            "error": "This episode did not return any stream sources.",
            "code": "no_sources",
            "providerFailures": [],
        }))
        sys.exit(1)

    # Build name->encoded_url map
    sources = {}
    for s in source_urls:
        name = s.get("sourceName", "")
        url  = s.get("sourceUrl",  "")
        if name and url:
            sources[name] = url

    show_data = _gql({"showId": show_id}, _Q_EPISODES)
    show = (show_data.get("data") or {}).get("show") or {}
    title = show.get("englishName") or show.get("name") or "Unknown"
    metadata = {
        "title": title,
        "episode": ep_num,
        "showId": show_id
    }

    provider_failures = []

    for provider in _PROVIDER_PRIORITY.get(provider_pref, _PROVIDER_PRIORITY["auto"]):
        raw = sources.get(provider)
        if not raw:
            provider_failures.append(_normalise_provider_failure(provider, "source unavailable"))
            continue
        if not raw.startswith("--"):
            provider_failures.append(_normalise_provider_failure(provider, "unsupported source format"))
            continue
        decoded = _decode_url(raw[2:])
        if not decoded:
            provider_failures.append(_normalise_provider_failure(provider, "failed to decode source"))
            continue
        provider_url = f"https://{BASE}{decoded}"

        try:
            resp = _fetch(provider_url)
        except urllib.error.HTTPError as e:
            provider_failures.append(_normalise_provider_failure(provider, f"HTTP {e.code}"))
            continue
        except urllib.error.URLError as e:
            provider_failures.append(_normalise_provider_failure(provider, f"network error ({_stringify_error(e.reason)})"))
            continue
        except Exception as e:
            provider_failures.append(_normalise_provider_failure(provider, _stringify_error(e)))
            continue

        headers = {
            "User-Agent": AGENT,
            "Referer": REFERER
        }

        # mp4 links with resolution
        links = re.findall(r'"link":"([^"]+)"[^}]*"resolutionStr":"([^"]+)"', resp)
        direct_mp4_links = [
            (url, res) for url, res in links
            if _is_direct_mp4_quality(res)
        ]
        if direct_mp4_links:
            variants = _build_quality_variants(direct_mp4_links)
            url, res = _pick_quality([(item["url"], item["quality"]) for item in variants], quality_pref)
            print(json.dumps({
                "url": url, "referer": REFERER, "type": "mp4",
                "provider": provider,
                "http_headers": headers, "metadata": metadata
            }))
            return

        if '"error"' in resp.lower():
            provider_failures.append(_normalise_provider_failure(provider, "provider returned an error response"))
            continue

        # HLS fallback
        hls = re.search(r'"url":"(https?://[^"]+master\.m3u8[^"]*)"', resp)
        if hls:
            refm = re.search(r'"Referer":"([^"]+)"', resp)
            final_url = _json_unescape(hls.group(1))
            final_referer = _json_unescape(refm.group(1)) if refm else REFERER
            headers["Referer"] = final_referer
            print(json.dumps({
                "url": final_url,
                "referer": final_referer,
                "type": "hls", "provider": provider,
                "http_headers": headers, "metadata": metadata
            }))
            return

        provider_failures.append(_normalise_provider_failure(provider, "no playable links returned"))

    print(json.dumps({
        "error": _summarise_provider_failures(provider_failures),
        "code": "no_playable_stream",
        "providerFailures": provider_failures,
    }))
    sys.exit(1)

# ── Entry point ───────────────────────────────────────────────────────────────
def main():
    args = sys.argv[1:]
    if not args:
        print(json.dumps({"error": "No command given"}))
        sys.exit(1)
    cmd = args[0]
    try:
        if cmd == "search":
            cmd_search(
                args[1] if len(args) > 1 else "",
                args[2] if len(args) > 2 else "sub",
                int(args[3]) if len(args) > 3 else 1,
                args[4] if len(args) > 4 else None
            )
        elif cmd == "popular":
            cmd_popular(
                int(args[1]) if len(args) > 1 else 1,
                args[2] if len(args) > 2 else "sub",
                args[3] if len(args) > 3 else None
            )
        elif cmd == "latest":
            cmd_latest(
                int(args[1]) if len(args) > 1 else 1,
                args[2] if len(args) > 2 else "sub",
                args[3] if len(args) > 3 else "ALL",
            )
        elif cmd == "recent":
            cmd_recent(
                int(args[1]) if len(args) > 1 else 1,
                args[2] if len(args) > 2 else "sub",
                args[3] if len(args) > 3 else "ALL",
            )
        elif cmd == "genres":
            cmd_genres()
        elif cmd == "episodes":
            cmd_episodes(
                args[1],
                args[2] if len(args) > 2 else "sub",
            )
        elif cmd == "feed":
            cmd_feed(
                args[1],
                args[2] if len(args) > 2 else "sub",
                args[3] if len(args) > 3 else "",
            )
        elif cmd == "stream":
            cmd_stream(
                args[1],
                args[2],
                args[3] if len(args) > 3 else "sub",
                args[4] if len(args) > 4 else "auto",
                args[5] if len(args) > 5 else "best",
            )
        else:
            print(json.dumps({"error": f"Unknown command: {cmd}"}))
            sys.exit(1)
    except IndexError:
        print(json.dumps({"error": f"Missing argument for: {cmd}"}))
        sys.exit(1)
    except urllib.error.HTTPError as e:
        print(json.dumps({"error": f"HTTP Error {e.code}: {e.reason}"}))
        sys.exit(1)
    except urllib.error.URLError as e:
        print(json.dumps({"error": f"Network error: {e}"}))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()
