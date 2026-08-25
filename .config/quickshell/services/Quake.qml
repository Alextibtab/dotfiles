pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "QuakeModel.js" as Model

// Earthquake tracker for the bar pill, fed by the USGS Earthquake Hazards
// Program. Ported from the omaquake Omarchy plugin (rsoutar/omaquake).
//
// A single shared singleton (like SystemUpdates) so that every monitor's bar
// runs ONE poll instead of one per widget. The bar widget pushes its layout
// settings in here and reacts to the derived `label` / `events` / `alerting`.
//
// "Only Japan": the watch is confined to a bounding box (minLat/maxLat/
// minLon/maxLon) sent to the USGS FDSN API, so events outside Japan are
// never fetched. The latitude/longitude/rangeKm values are kept as the
// distance reference for display ("X km away").
Singleton {
  id: root

  // ---- settings, pushed in by the bar widget -----------------------------
  property real latitude: 37.0
  property real longitude: 138.0
  property string locationName: "Japan"
  property real rangeKm: 1200
  property real minMagnitude: 2.5
  property real alertMagnitude: 6.0
  property string scope: "local"
  property real refreshMinutes: 5
  property bool notify: true
  property string units: "auto"

  // Japan bounding box. When set, confines the watch to this box via the
  // FDSN minlat/maxlat/minlon/maxlon parameters (see QuakeModel.feedUrls).
  property real minLat: 24.0
  property real maxLat: 46.0
  property real minLon: 122.5
  property real maxLon: 154.0

  // ---- state -------------------------------------------------------------
  property var rawEvents: []
  property var events: []
  property string lastError: ""
  property bool refreshing: false
  property real lastPollMs: 0
  property var seenIds: ({})
  property bool seenSeeded: false
  property int fetchRetries: 0
  property real nowMs: Date.now()
  property bool initialized: false
  property string lastFetchKey: ""

  // ---- derived -----------------------------------------------------------
  readonly property var bounds: ({
    minLat: root.minLat,
    maxLat: root.maxLat,
    minLon: root.minLon,
    maxLon: root.maxLon
  })
  readonly property bool hasBounds: Model.hasBounds(root.bounds)

  readonly property var latest: Model.latestEvent(events)
  readonly property var hero: Model.heroEvent(events)
  readonly property var restEvents: Model.listEvents(events, hero)
  readonly property var currentAlert: Model.activeAlert(events, root.alertMagnitude, root.nowMs)
  readonly property bool alerting: root.currentAlert !== null
  readonly property string label: Model.barLabel(root.latest, false)
  readonly property string glyph: Model.QUAKE_GLYPH
  readonly property string tooltip: Model.tooltipText(root.latest, root.lastError !== "" && root.events.length === 0)
  readonly property bool useImperial: Model.shouldUseImperial(root.units, Qt.locale().name)
  readonly property string emptyMessage: {
    if (root.refreshing && root.events.length === 0) return "Fetching earthquakes…"
    if (root.lastError !== "" && root.events.length === 0) return root.lastError
    if (root.hasBounds) return "No recent earthquakes in Japan"
    if (root.scope === "local") return "No events in range"
    return "No recent earthquakes"
  }

  // Which query the cached events were fetched under. When it changes the
  // incremental poll cursor is dropped so the next fetch re-reads the window.
  readonly property string fetchKey: [
    root.scope, root.hasBounds, root.latitude, root.longitude,
    root.rangeKm, root.minMagnitude,
    root.minLat, root.maxLat, root.minLon, root.maxLon
  ].join(":")

  readonly property int userPollMs: Math.max(1000, Math.round(root.refreshMinutes * 60 * 1000))

  // ---- helpers -----------------------------------------------------------
  function filterOptions() {
    return {
      latitude: root.latitude,
      longitude: root.longitude,
      rangeKm: root.rangeKm,
      minMagnitude: root.minMagnitude,
      scope: root.scope,
      bounds: root.hasBounds ? root.bounds : null
    }
  }

  function applyFilter() {
    root.events = Model.filterEvents(root.rawEvents, root.filterOptions())
  }

  // Called by the widget whenever it pushes settings. Re-filters the cached
  // list and, if the underlying query changed, resets the incremental cursor
  // and refetches.
  function configure() {
    root.applyFilter()
    if (!root.initialized) return
    if (root.fetchKey !== root.lastFetchKey) {
      root.lastFetchKey = root.fetchKey
      root.resetFeedWindow()
      Qt.callLater(root.refresh)
    }
  }

  // ---- fetch cycle -------------------------------------------------------
  // Delay until the server could serve newer data: never sooner than the
  // chosen interval, and never sooner than the response's Expires (USGS
  // caches responses for 60s, so polling faster is wasted).
  function nextPollMs(headers) {
    var expires = Model.expiresAtMs(headers, Date.now())
    if (expires <= 0) return root.userPollMs
    return Math.max(root.userPollMs, expires - Date.now() + 600)
  }

  function scheduleNext(ms) {
    retryTimer.stop()
    refreshTimer.interval = Math.max(1000, Math.round(ms > 0 ? ms : root.userPollMs))
    refreshTimer.running = true
  }

  // Exponential backoff between retries, capped at a minute.
  function scheduleRetry(backoffMs) {
    if (root.events.length === 0) root.lastError = "Could not reach USGS"
    if (root.fetchRetries >= 4) {
      root.refreshing = false
      root.fetchRetries = 0
      root.scheduleNext(root.userPollMs)
      return
    }
    root.fetchRetries++
    var delay = backoffMs > 0 ? backoffMs : Math.min(60000, 5000 * Math.pow(2, root.fetchRetries - 1))
    retryTimer.interval = delay
    retryTimer.running = true
  }

  // HTTP errors (429 rate-limit, 4xx/5xx) land here with status + headers.
  function handleHttpError(http) {
    root.refreshing = false
    if (!http || http.status === 0) {
      root.scheduleRetry()
      return
    }
    if (http.status === 429) {
      if (root.events.length === 0) root.lastError = "USGS rate limited"
      root.fetchRetries = 0
      var backoff = Model.retryAfterMs(http.headers, Date.now())
      root.scheduleNext(backoff > 0 ? backoff : 120000)
    } else {
      root.scheduleRetry()
    }
  }

  // Drop the incremental cursor so the next fetch re-reads the whole window
  // (a widening of the query must not rely on incremental polling to backfill).
  function resetFeedWindow() {
    root.lastPollMs = 0
    root.fetchRetries = 0
    retryTimer.stop()
  }

  function refresh() {
    root.nowMs = Date.now()
    var urls = Model.feedUrls({
      scope: root.scope,
      latitude: root.latitude,
      longitude: root.longitude,
      rangeKm: root.rangeKm,
      minMagnitude: root.minMagnitude,
      bounds: root.hasBounds ? root.bounds : null,
      nowMs: Date.now(),
      updatedAfter: root.lastPollMs > 0 ? root.lastPollMs : null
    })
    if (!urls.length) return
    root.refreshing = true
    // -i keeps HTTP headers so we can read Expires/Cache-Control/Retry-After
    // and schedule the next poll against the server's cache.
    fetchProc.running = false
    fetchProc.command = ["curl", "-sS", "-i", "--max-time", "10", urls[0]]
    fetchProc.running = true
  }

  function ingestFeed(raw, headers) {
    var parsed = Model.parseFeed(raw)
    if (!parsed.ok) {
      root.scheduleRetry()
      return
    }
    root.lastError = ""
    root.fetchRetries = 0
    root.lastPollMs = Date.now()
    // Merge incremental polls into the existing list; updatedafter requests
    // only return events that changed since the last fetch, so replacing
    // rawEvents would wipe the list between quakes.
    root.rawEvents = Model.mergeFeed(root.rawEvents, parsed.events, Date.now())
    root.applyFilter()
    if (!root.seenSeeded) {
      root.seenIds = Model.seedSeenIds(root.events)
      root.seenSeeded = true
    } else if (root.notify) {
      var alerts = Model.alertCandidates(root.events, root.seenIds, {
        alertMagnitude: root.alertMagnitude,
        nowMs: Date.now(),
        requireInRange: !root.hasBounds
      })
      for (var i = 0; i < alerts.length; i++) root.sendAlertNotification(alerts[i])
      root.seenIds = Model.mergeSeen(root.seenIds, root.events)
    }
    root.nowMs = Date.now()
    root.scheduleNext(root.nextPollMs(headers))
  }

  // ---- notifications -----------------------------------------------------
  function sendAlertNotification(event) {
    var text = Model.notificationText(event, root.useImperial, Date.now())
    var url = Model.eventPageUrl(event)
    var body = text.body
    if (url) body = body ? body + "\n" + url : url
    var command = ["notify-send", "-a", "quake", "-u", "critical", text.headline]
    if (body) command.push(body)
    Quickshell.execDetached(command)
    root.playAlertSound()
  }

  function playAlertSound() {
    Quickshell.execDetached(["pw-play", Model.ALERT_SOUND])
  }

  // ---- timers ------------------------------------------------------------
  // Single-shot poll timer; refresh() reschedules it after every fetch so the
  // interval adapts to the setting and the server's Expires header.
  Timer {
    id: refreshTimer
    interval: 1
    repeat: false
    onTriggered: root.refresh()
  }

  // Backoff retry ladder, scheduled by scheduleRetry().
  Timer {
    id: retryTimer
    interval: 5000
    repeat: false
    onTriggered: if (!fetchProc.running) root.refresh()
  }

  // Refresh the relative-time strings ("5 minutes ago") in the panel.
  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  // ---- processes ---------------------------------------------------------
  Process {
    id: fetchProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.refreshing = false
        var http = Model.parseHttpResponse(text)
        var body = String(http.body || "").replace(/^\s+|\s+$/g, "")
        if (http.status >= 400 || !body) {
          root.handleHttpError(http)
          return
        }
        root.ingestFeed(body, http.headers)
      }
    }
  }

  Component.onCompleted: {
    root.initialized = true
  }
}
