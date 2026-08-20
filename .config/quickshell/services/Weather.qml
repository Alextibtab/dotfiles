pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "WeatherModel.js" as Model

// Weather data for the bar pill: current conditions plus a three-day
// forecast, mixed from two sources exactly like omarchy's panel:
//
//   - Open-Meteo (fast) for current conditions + daily forecast, fetched as
//     soon as any coordinates are known (stored or auto-detected).
//   - wttr.in for the auto-detected area name and as the no-coordinates
//     fallback.
//
// The configured location lives in ~/.config/quickshell/weather.json, written
// by ~/.local/bin/weather-location and watched live so hand edits take effect
// too. An empty object (or missing file) means auto-detect from the IP.
//
// The bar widget feeds two settings in from its layout entry: `unit`
// ("metric"/"imperial"/empty-for-auto) and `refreshMinutes`.
Singleton {
  id: root

  // ---- settings, pushed in by the bar widget -----------------------------
  property string unitOverride: ""
  property int refreshMinutes: 15

  // ---- location ----------------------------------------------------------
  property string locationStatePath: Quickshell.env("HOME") + "/.config/quickshell/weather.json"
  property var configuredLocationState: ({ name: "", latitude: null, longitude: null })

  readonly property string configuredLocation: root.configuredLocationState.name
  readonly property string locationQuery: Model.wttrLocationQuery(
    root.configuredLocationState.name,
    root.configuredLocationState.latitude,
    root.configuredLocationState.longitude)
  readonly property bool hasConfiguredCoordinates: !isNaN(parseFloat(String(root.configuredLocationState.latitude)))
      && !isNaN(parseFloat(String(root.configuredLocationState.longitude)))

  // Auto-detected area name from wttr.in ?format=%l.
  property string wttrLocation: ""

  // ---- fetched reports ---------------------------------------------------
  // Parsed wttr.in j1 response. Kept on failure so stale data stays visible.
  property var report: null
  property var dailyForecastReport: null

  // The bar glyph, updated with each successful response.
  property string label: ""

  readonly property var openMeteoCurrent: Model.openMeteoCurrentCondition(root.dailyForecastReport)
  readonly property var current: root.hasConfiguredCoordinates && root.openMeteoCurrent
      ? root.openMeteoCurrent
      : ((root.report && root.report.current_condition && root.report.current_condition[0])
          ? root.report.current_condition[0]
          : root.openMeteoCurrent)
  readonly property var areaInfo: root.report && root.report.nearest_area && root.report.nearest_area[0]
      ? root.report.nearest_area[0]
      : null
  readonly property var forecastDays: Model.buildForecastDays(
    root.report, root.dailyForecastReport, Qt.formatDate(new Date(), "yyyy-MM-dd"))

  readonly property string reportCountry: root.areaInfo && root.areaInfo.country && root.areaInfo.country[0]
      ? root.areaInfo.country[0].value : ""

  readonly property bool useImperial: Model.shouldUseImperial(root.unitOverride, Qt.locale().name, root.reportCountry)

  // ---- display values ----------------------------------------------------
  readonly property string reportLocation: root.configuredLocation || root.wttrLocation
      || (root.areaInfo && root.areaInfo.areaName && root.areaInfo.areaName[0] ? root.areaInfo.areaName[0].value : "")
  readonly property string reportTempNum: root.current
      ? String(root.useImperial ? root.current.temp_F : root.current.temp_C) : ""
  readonly property string tempUnit: "°" + (root.useImperial ? "F" : "C")
  readonly property string reportFeels: root.current
      ? Model.formatTemp(root.useImperial ? root.current.FeelsLikeF : root.current.FeelsLikeC, root.useImperial) : ""
  readonly property string reportWind: root.current
      ? (root.useImperial ? (root.current.windspeedMiles + " mph") : (root.current.windspeedKmph + " km/h")) : ""
  readonly property string reportHumidity: root.current ? (root.current.humidity + "%") : ""

  // ---- location editing state (used by the popup) ------------------------
  property bool editingLocation: false
  property bool savingLocation: false
  property bool savingLocationQueryStarted: false
  property var locationSuggestions: []
  property int suggestionIndex: 0
  property string geocodePendingQuery: ""
  property string geocodeActiveQuery: ""
  property string searchText: ""

  property int forecastRetries: 0
  property int dailyForecastRetries: 0

  // ---- refresh cycle -----------------------------------------------------
  function refresh() {
    // Each full refresh cycle gets a fresh retry budget, so an earlier
    // exhausted round (e.g. waking with the network still down) doesn't
    // starve retries for the rest of the session.
    root.forecastRetries = 0
    root.dailyForecastRetries = 0
    forecastProc.command = ["curl", "-fsS", "--max-time", "10", "https://wttr.in/" + root.locationQuery + "?format=j1"]
    if (!forecastProc.running) forecastProc.running = true
    if (root.locationQuery === "" && !locationProc.running) locationProc.running = true
    // With stored coordinates this fetches open-meteo right away — no need
    // to wait for the slow wttr response. Without them it's a no-op until
    // wttr reports the detected area.
    root.refreshDailyForecast(null)
  }

  function refreshDailyForecast(sourceReport) {
    if (dailyForecastProc.running) return

    var lat = parseFloat(String(root.configuredLocationState.latitude))
    var lon = parseFloat(String(root.configuredLocationState.longitude))
    if (isNaN(lat) || isNaN(lon)) {
      var area = sourceReport && sourceReport.nearest_area && sourceReport.nearest_area[0]
          ? sourceReport.nearest_area[0]
          : root.areaInfo
      if (!area) return
      lat = parseFloat(String(area.latitude || ""))
      lon = parseFloat(String(area.longitude || ""))
    }
    if (isNaN(lat) || isNaN(lon)) return

    var url = "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + encodeURIComponent(String(lat))
        + "&longitude=" + encodeURIComponent(String(lon))
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
        + "&forecast_days=4"
        + "&timezone=auto"
    dailyForecastProc.command = ["curl", "-fsS", "--max-time", "5", url]
    dailyForecastProc.running = true
  }

  // wttr.in can be slow or flaky, especially for a location it hasn't
  // cached yet. Retry a few times before leaving it to the refresh timer.
  function scheduleForecastRetry() {
    if (root.forecastRetries >= 3) return
    root.forecastRetries++
    forecastRetryTimer.restart()
  }

  Timer {
    id: forecastRetryTimer
    interval: 2500
    onTriggered: if (!forecastProc.running) forecastProc.running = true
  }

  // With configured coordinates the open-meteo fetch is the only thing that
  // updates the bar icon, so a dropped response (e.g. waking before the
  // network is back) must retry rather than wait out the refresh timer.
  function scheduleDailyForecastRetry() {
    if (root.dailyForecastRetries >= 3) return
    root.dailyForecastRetries++
    dailyForecastRetryTimer.restart()
  }

  Timer {
    id: dailyForecastRetryTimer
    interval: 2500
    onTriggered: root.refreshDailyForecast(null)
  }

  Timer {
    id: refreshTimer
    interval: root.refreshMinutes * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // ---- location file -----------------------------------------------------
  FileView {
    id: locationFile
    path: root.locationStatePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.configuredLocationState = Model.parseLocationFile(text())
    onLoadFailed: root.configuredLocationState = Model.parseLocationFile("")
  }

  // The first read can race shell startup, leaving a stored location
  // unhonored until the next file write. One delayed reload self-corrects;
  // if the first read was fine it's a no-op, since identical state doesn't
  // change locationQuery and so triggers no refetch.
  Timer {
    interval: 1500
    running: true
    onTriggered: locationFile.reload()
  }

  // Keep the previous report visible while the new location loads. The
  // editor remains open with a spinner, so stale data is never presented
  // under the newly configured location label.
  onLocationQueryChanged: {
    if (root.savingLocation) root.savingLocationQueryStarted = true
    root.forecastRetries = 0
    root.dailyForecastRetries = 0
    forecastProc.running = false
    dailyForecastProc.running = false
    Qt.callLater(root.refresh)
  }

  // ---- location editing --------------------------------------------------
  function startEditingLocation() {
    root.editingLocation = true
    root.savingLocation = false
    root.savingLocationQueryStarted = false
    root.locationSuggestions = []
    root.suggestionIndex = 0
    root.searchText = root.configuredLocation
  }

  function cancelEditingLocation() {
    root.editingLocation = false
    root.savingLocation = false
    root.savingLocationQueryStarted = false
    root.locationSuggestions = []
    root.searchText = ""
    geocodeDebounce.stop()
  }

  // Commit whatever the search field resolved to: the selected geocoded
  // suggestion, or the raw typed name when no suggestion was picked.
  function commitSearch() {
    var location = Model.locationCommit(root.searchText, root.locationSuggestions, root.suggestionIndex)
    if (location.name === "") {
      root.clearLocation()
      return
    }
    root.commitLocation(location.name, location.latitude, location.longitude)
  }

  function commitLocation(name, latitude, longitude) {
    root.savingLocation = true
    root.savingLocationQueryStarted = false
    root.configuredLocationState = { name: name, latitude: latitude, longitude: longitude }
    root.persistLocation(name, latitude, longitude)
  }

  function pickSuggestion(suggestion) {
    if (!suggestion) return
    root.savingLocation = true
    root.savingLocationQueryStarted = false
    root.configuredLocationState = {
      name: suggestion.name,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude
    }
    root.persistLocation(suggestion.name, suggestion.latitude, suggestion.longitude)
  }

  function clearLocation() {
    root.persistLocation("", null, null)
    root.wttrLocation = ""
    root.cancelEditingLocation()
  }

  function finishSavingLocation() {
    if (root.savingLocation && root.savingLocationQueryStarted) root.cancelEditingLocation()
  }

  function persistLocation(name, latitude, longitude) {
    var command = [Quickshell.env("HOME") + "/.local/bin/weather-location"]
    if (name && latitude !== null && longitude !== null)
      command = command.concat(["--set", name, latitude + "," + longitude])
    else if (name)
      command = command.concat(["--set", name])
    else
      command = command.concat(["--clear"])
    locationSaveProc.command = command
    locationSaveProc.running = true
  }

  // ---- geocoding ---------------------------------------------------------
  // Debounced search. Only one curl runs at a time; if the query moved on
  // while a fetch was in flight, the latest query is fetched right after.
  function search(text) {
    root.searchText = text
    if (root.editingLocation) geocodeDebounce.restart()
  }

  Timer {
    id: geocodeDebounce
    interval: 300
    onTriggered: root.requestGeocode(root.searchText)
  }

  function requestGeocode(query) {
    var q = String(query || "").trim()
    if (q.length < 2) {
      root.locationSuggestions = []
      return
    }
    root.geocodePendingQuery = q
    if (!geocodeProc.running) root.startGeocode()
  }

  function startGeocode() {
    root.geocodeActiveQuery = root.geocodePendingQuery
    geocodeProc.command = ["curl", "-fsS", "--max-time", "5",
      "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(root.geocodeActiveQuery) + "&count=5&language=en&format=json"]
    geocodeProc.running = true
  }

  // ---- helpers for the popup --------------------------------------------
  function dayName(dateString) {
    return Model.dayName(dateString, function (d) { return Qt.formatDate(d, "dddd") })
  }

  // Bare degree value (no unit letter), used in the forecast row.
  function bareTempForDay(day, kind) {
    return Model.bareTempForDay(day, kind, root.useImperial)
  }

  function dayIcon(day) {
    return Model.dayIcon(day)
  }

  function iconForOpenMeteoCode(code) {
    return Model.iconForOpenMeteoCode(code)
  }

  function iconForCode(code, night) {
    return Model.iconForCode(code, night)
  }

  // ---- network processes -------------------------------------------------
  Process {
    id: forecastProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw) {
          root.scheduleForecastRetry()
          return
        }
        try {
          var parsed = JSON.parse(raw)
          root.report = parsed
          if (!root.hasConfiguredCoordinates)
            root.label = Model.provisionalCurrentIcon(parsed.current_condition && parsed.current_condition[0], root.label)
          root.forecastRetries = 0
          if (Model.weatherResponseCompletesSave(root.hasConfiguredCoordinates, "wttr"))
            root.finishSavingLocation()
          // Stored coordinates already drove the fast open-meteo fetch from
          // refresh(); only auto-detect needs the area wttr reported.
          if (isNaN(parseFloat(String(root.configuredLocationState.latitude))))
            root.refreshDailyForecast(parsed)
        } catch (e) {
          // Keep last-good report visible, but try again shortly.
          root.scheduleForecastRetry()
        }
      }
    }
  }

  Process {
    id: dailyForecastProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw) {
          root.scheduleDailyForecastRetry()
          return
        }
        try {
          var parsed = JSON.parse(raw)
          var parsedCurrent = Model.openMeteoCurrentCondition(parsed)
          root.dailyForecastReport = parsed
          root.label = Model.currentIcon(parsedCurrent, root.label)
          root.dailyForecastRetries = 0
          if (Model.weatherResponseCompletesSave(root.hasConfiguredCoordinates, "open-meteo"))
            root.finishSavingLocation()
        } catch (e) {
          // Keep last-good daily forecast visible, but try again shortly.
          root.scheduleDailyForecastRetry()
        }
      }
    }
  }

  Process {
    id: geocodeProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.locationSuggestions = root.editingLocation ? Model.parseGeocodingResults(text) : []
        root.suggestionIndex = 0
        if (root.geocodePendingQuery !== root.geocodeActiveQuery) Qt.callLater(root.startGeocode)
      }
    }
  }

  Process {
    id: locationSaveProc
    onExited: function (exitCode) {
      if (exitCode !== 0 || !root.savingLocation) return

      // FileView handles changed locations. Explicitly refresh here too so
      // saving the already-active location cannot strand the spinner.
      root.savingLocationQueryStarted = true
      root.forecastRetries = 0
      root.dailyForecastRetries = 0
      forecastProc.running = false
      dailyForecastProc.running = false
      Qt.callLater(root.refresh)
    }
  }

  Process {
    id: locationProc
    command: ["curl", "-fsS", "--max-time", "4", "https://wttr.in/?format=%l"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw) return
        root.wttrLocation = raw.split(",")[0]
      }
    }
  }
}
