import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components
import "../../../services/QuakeModel.js" as Model

// Earthquake tracker pill, ported from the omaquake Omarchy plugin. Tracks
// earthquakes in Japan (a bounding box around the archipelago).
//
//   click        toggle the quake panel (hero + recent events)
//   middle click refresh now
//
// The glyph pulses and turns urgent while an alert-magnitude quake is recent.
// Settings come from the bar layout entry, e.g.
//   { "id": "quake", "minMagnitude": 3.0, "alertMagnitude": 6.0 }
// All values are pushed into the shared Quake service.
BarButton {
  id: root

  // The output this bar instance is on; the popup needs it to cover the
  // correct screen on multi-monitor setups.
  property var screen: null
  property string monitorName: ""

  // Japan watch defaults. A layout entry can override any of these.
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

  // Japan bounding box, sent to the FDSN API to confine the watch.
  property real minLat: 24.0
  property real maxLat: 46.0
  property real minLon: 122.5
  property real maxLon: 154.0

  property bool pushQueued: false

  function push() {
    root.pushQueued = false
    Quake.latitude = root.latitude
    Quake.longitude = root.longitude
    Quake.locationName = root.locationName
    Quake.rangeKm = root.rangeKm
    Quake.minMagnitude = root.minMagnitude
    Quake.alertMagnitude = root.alertMagnitude
    Quake.scope = root.scope
    Quake.refreshMinutes = root.refreshMinutes
    Quake.notify = root.notify
    Quake.units = root.units
    Quake.minLat = root.minLat
    Quake.maxLat = root.maxLat
    Quake.minLon = root.minLon
    Quake.maxLon = root.maxLon
    Quake.configure()
  }

  // Debounce the burst of onChanged handlers during setup/runtime edits into
  // a single configure().
  function queuePush() {
    if (root.pushQueued) return
    root.pushQueued = true
    Qt.callLater(root.push)
  }

  onLatitudeChanged: queuePush()
  onLongitudeChanged: queuePush()
  onLocationNameChanged: queuePush()
  onRangeKmChanged: queuePush()
  onMinMagnitudeChanged: queuePush()
  onAlertMagnitudeChanged: queuePush()
  onScopeChanged: queuePush()
  onRefreshMinutesChanged: queuePush()
  onNotifyChanged: queuePush()
  onUnitsChanged: queuePush()
  onMinLatChanged: queuePush()
  onMaxLatChanged: queuePush()
  onMinLonChanged: queuePush()
  onMaxLonChanged: queuePush()

  Component.onCompleted: root.push()

  onClicked: popup.visible ? popup.closeTree() : popup.openFor(root)
  onMiddleClicked: Quake.refresh()

  // Pulse the whole pill while an alert-magnitude quake is recent.
  opacity: pulse.running ? pulse.opacity : 1

  Row {
    spacing: Style.spacingSmall

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Quake.glyph
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      color: Quake.alerting ? Colours.urgent : Colours.bar.textMuted
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Quake.latest ? Model.formatMagnitude(Quake.latest.mag) : "—"
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      font.bold: true
      color: Quake.alerting ? Colours.urgent : Colours.bar.text
    }
  }

  SequentialAnimation {
    id: pulse
    running: Quake.alerting
    loops: Animation.Infinite
    property real opacity: 1
    NumberAnimation {
      target: pulse
      property: "opacity"
      to: 0.45
      duration: 700
      easing.type: Easing.InOutSine
    }
    NumberAnimation {
      target: pulse
      property: "opacity"
      to: 1
      duration: 700
      easing.type: Easing.InOutSine
    }
    onRunningChanged: if (!running) pulse.opacity = 1
  }

  QuakePopup {
    id: popup
    output: root.screen
    monitorName: root.monitorName
  }
}
