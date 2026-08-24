#!/usr/bin/env python3
"""Japanese study review counts: WaniKani, Bunpro, Anki.

Reads tokens from secrets.json (a sibling of this script), then queries each
service and prints a single JSON object for the bar widget:

    {
      "total": N,
      "services": [
        { "id", "name", "due", "lessons", "ok", "status", "decks" },
        ...
      ]
    }

`due` counts reviews currently available:

  - WaniKani: GET /v2/summary, the reviews/lessons buckets whose available_at
    has passed.
  - Bunpro:   GET /api/frontend/user/due (community-documented frontend API,
    requires a browser JWT that expires periodically).
  - Anki:     AnkiConnect getNumCardsDuePerDeck on 127.0.0.1:8765, summing
    new+learn+review across every deck. Only present while Anki is running
    with the AnkiConnect addon installed.

Each service reports `ok` plus a short `status` note for non-ok states (not
configured / token expired / not running), so the panel can say something
useful instead of silently showing zero.

Run with `--open <service>` to launch that service's review UI instead of
querying (used by the bar widget's Study buttons). Only stdlib is used.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone

WANIKANI_SUMMARY = "https://api.wanikani.com/v2/summary"
BUNPRO_DUE = "https://api.bunpro.jp/api/frontend/user/due"
BUNPRO_QUEUE = "https://api.bunpro.jp/api/frontend/user/queue"
BUNPRO_LEARN = "https://api.bunpro.jp/api/frontend/learn"
ANKICONNECT_URL = "http://127.0.0.1:8765"

WANIKANI_REVIEW_URL = "https://www.wanikani.com/review/session"
BUNPRO_REVIEW_URL = "https://bunpro.jp/reviews"

TIMEOUT = 5

# Bunpro's API sits behind Cloudflare, which rejects clients whose
# User-Agent does not look like a real browser (HTTP 403 "Error 1010: Access
# denied"). Send a browser UA on every request so it is not blocked.
USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0"
)


def here() -> str:
    return os.path.dirname(os.path.abspath(__file__))


def secrets_path() -> str:
    return os.path.join(os.path.expanduser("~"), ".config", "quickshell", "secrets.json")


def service(
    id: str,
    name: str,
    due: int = 0,
    lessons: int = 0,
    ok: bool = True,
    status: str = "",
    decks=None,
) -> dict:
    return {
        "id": id,
        "name": name,
        "due": due,
        "lessons": lessons,
        "ok": ok,
        "status": status,
        "decks": decks or [],
    }


def load_tokens() -> dict:
    try:
        with open(secrets_path(), "r", encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def http_json(url: str, headers=None, data=None) -> tuple:
    """GET/POST a JSON endpoint. Returns (payload, error)."""
    request_headers = headers or {}
    request_headers.setdefault("User-Agent", USER_AGENT)
    req = urllib.request.Request(url, headers=request_headers, data=data)
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return json.loads(resp.read().decode("utf-8")), None
    except urllib.error.HTTPError as e:
        body = ""
        try:
            body = e.read().decode("utf-8")
        except Exception:
            pass
        return None, f"HTTP {e.code} {body[:120]}"
    except Exception as e:
        return None, str(e)


# ---- WaniKani -----------------------------------------------------------


def query_wanikani(token: str) -> dict:
    if not token:
        return service("wanikani", "WaniKani", ok=False, status="not configured")

    payload, err = http_json(WANIKANI_SUMMARY, headers={
        "Authorization": "Bearer " + token,
        "Wanikani-Revision": "20170710",
    })
    if err is not None or not isinstance(payload, dict):
        return service("wanikani", "WaniKani", ok=False, status="request failed")

    now = datetime.now(timezone.utc)

    def count_available(buckets) -> int:
        if not isinstance(buckets, list):
            return 0
        total = 0
        for bucket in buckets:
            if not isinstance(bucket, dict):
                continue
            try:
                at = datetime.fromisoformat(bucket["available_at"].replace("Z", "+00:00"))
            except Exception:
                continue
            if at <= now and isinstance(bucket.get("subject_ids"), list):
                total += len(bucket["subject_ids"])
        return total

    data = payload.get("data") or {}
    return service(
        "wanikani",
        "WaniKani",
        due=count_available(data.get("reviews")),
        lessons=count_available(data.get("lessons")),
    )


# ---- Bunpro -------------------------------------------------------------


def count_payload_due(payload) -> int:
    """Defensively extract a due count from whatever shape /user/due returns."""
    if isinstance(payload, list):
        return len(payload)
    if not isinstance(payload, dict):
        return 0
    # e.g. {"total_due_grammar": 46, "total_due_vocab": 122}
    due_keys = [k for k in payload if str(k).startswith("total_due_")]
    if due_keys:
        return sum(int(payload[k]) for k in due_keys if isinstance(payload[k], (int, float)))
    for key in ("due_count", "reviews_available", "count", "total"):
        value = payload.get(key)
        if isinstance(value, (int, float)):
            return int(value)
    data = payload.get("data")
    if isinstance(data, list):
        return len(data)
    if isinstance(data, dict):
        for key in ("due", "queue", "items", "reviews"):
            value = data.get(key)
            if isinstance(value, list):
                return len(value)
    return 0


def query_bunpro_lessons(token: str) -> int:
    """Count the next batch of new items to learn across active decks.

    /user/queue lists the user's decks; /learn?deck_id=N returns exactly the
    next batch (batch_size items) of unlearned content for that deck. Fully
    defensive: any failure contributes 0.
    """
    payload, err = http_json(BUNPRO_QUEUE, headers={
        "Authorization": "Bearer " + token,
        "Accept": "application/json",
    })
    if err is not None or not isinstance(payload, dict):
        return 0
    entries = payload.get("data")
    if not isinstance(entries, list):
        return 0

    total = 0
    for entry in entries:
        attrs = entry.get("attributes") if isinstance(entry, dict) else None
        if not isinstance(attrs, dict):
            continue
        if attrs.get("actively_studying") is False:
            continue
        deck_id = attrs.get("deck_id")
        if deck_id is None:
            continue
        learn, lerr = http_json(
            f"{BUNPRO_LEARN}?deck_id={deck_id}",
            headers={
                "Authorization": "Bearer " + token,
                "Accept": "application/json",
            },
        )
        if lerr is None and isinstance(learn, dict) and isinstance(learn.get("content"), list):
            total += len(learn["content"])
    return total


def query_bunpro(token: str) -> dict:
    if not token:
        return service("bunpro", "Bunpro", ok=False, status="not configured")

    payload, err = http_json(BUNPRO_DUE, headers={
        "Authorization": "Bearer " + token,
        "Accept": "application/json",
    })
    if err is None and payload is not None:
        return service(
            "bunpro",
            "Bunpro",
            due=count_payload_due(payload),
            lessons=query_bunpro_lessons(token),
        )
    if err and "401" in str(err):
        return service("bunpro", "Bunpro", ok=False, status="token expired")
    return service("bunpro", "Bunpro", ok=False, status="request failed")


# ---- Anki ---------------------------------------------------------------


def anki_connect(action: str, params=None) -> tuple:
    body = json.dumps({"action": action, "version": 6, "params": params or {}}).encode("utf-8")
    payload, err = http_json(ANKICONNECT_URL, headers={"Content-Type": "application/json"}, data=body)
    if err is not None:
        return None, err
    if not isinstance(payload, dict):
        return None, "no response"
    if payload.get("error"):
        return None, payload["error"]
    return payload.get("result"), None


def deck_due(counts) -> int:
    """Sum the due counts from a getDeckStats entry."""
    if not isinstance(counts, dict):
        return 0
    return (
        int(counts.get("new_count", 0) or 0)
        + int(counts.get("learn_count", 0) or 0)
        + int(counts.get("review_count", 0) or 0)
    )


def query_anki() -> dict:
    # getNumCardsDuePerDeck is not supported by the installed AnkiConnect, so
    # get the deck list first and ask for per-deck stats instead.
    names, err = anki_connect("deckNames")
    if err is not None or not isinstance(names, list):
        return service("anki", "Anki", ok=False, status="Anki not running")

    result, err = anki_connect("getDeckStats", {"decks": names})
    if err is not None or not isinstance(result, dict):
        return service("anki", "Anki", ok=False, status="Anki not running")

    decks = []
    total = 0
    for entry in result.values():
        due = deck_due(entry)
        if due > 0:
            decks.append({"name": entry.get("name", "?"), "due": due})
        total += due
    decks.sort(key=lambda d: d["due"], reverse=True)
    return service("anki", "Anki", due=total, decks=decks)


# ---- open actions -------------------------------------------------------


def open_wanikani() -> None:
    subprocess.Popen(["xdg-open", WANIKANI_REVIEW_URL], start_new_session=True)


def open_bunpro() -> None:
    subprocess.Popen(["xdg-open", BUNPRO_REVIEW_URL], start_new_session=True)


def open_anki() -> None:
    names, err = anki_connect("deckNames")
    if err is not None:
        # Not running (or no AnkiConnect) - just launch Anki.
        subprocess.Popen(["anki"], start_new_session=True)
        return

    # Bring the (possibly tray-hidden) window back up, then navigate. Ignore
    # the error if the guiShowAnkiWindow action is missing (addon not loaded).
    anki_connect("guiShowAnkiWindow")

    best = None
    result, err = anki_connect("getDeckStats", {"decks": names})
    if err is None and isinstance(result, dict):
        for entry in result.values():
            due = deck_due(entry)
            if due > 0 and (best is None or due > best[1]):
                best = (entry.get("name", "?"), due)
    if best is not None:
        anki_connect("guiDeckReview", {"name": best[0]})
    else:
        anki_connect("guiDeckBrowser")


# ---- main ---------------------------------------------------------------


def main() -> int:
    args = sys.argv[1:]
    if args and args[0] == "--open":
        action = args[1] if len(args) > 1 else ""
        if action == "wanikani":
            open_wanikani()
        elif action == "bunpro":
            open_bunpro()
        elif action == "anki":
            open_anki()
        return 0

    tokens = load_tokens()
    services = [
        query_wanikani(tokens.get("wanikaniToken", "")),
        query_bunpro(tokens.get("bunproToken", "")),
        query_anki(),
    ]
    total = sum(s["due"] for s in services if s["ok"])
    print(json.dumps({"total": total, "services": services}, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())