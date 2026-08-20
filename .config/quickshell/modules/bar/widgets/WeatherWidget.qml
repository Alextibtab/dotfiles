import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Weather pill: condition glyph plus temperature. Clicking toggles the detail
// popup (current conditions, click-to-edit location, three-day forecast);
// middle click forces an immediate refresh.
//
//   click        toggle the weather popup
//   middle click refresh now
//
// Settings come from the bar layout entry, e.g.
//   { "id": "weather", "unit": "imperial", "refreshMinutes": 30 }
// `unit` is "metric"/"imperial", or empty for auto (locale + country).
BarButton {
  id: root

  // The output this bar instance is on; the popup needs it to cover the
  // correct screen on multi-monitor setups.
  property var screen: null
  property string monitorName: ""

  property string unit: ""
  property int refreshMinutes: 15

  // Hidden until the first report arrives so an offline boot shows no dead
  // glyph; the pill appears the moment either source answers.
  visible: Weather.label !== ""

  onUnitChanged: Weather.unitOverride = root.unit
  onRefreshMinutesChanged: Weather.refreshMinutes = Math.max(1, root.refreshMinutes)
  Component.onCompleted: {
    Weather.unitOverride = root.unit
    Weather.refreshMinutes = Math.max(1, root.refreshMinutes)
  }

  onClicked: popup.visible ? popup.closeTree() : popup.openFor(root)
  onMiddleClicked: Weather.refresh()

  Row {
    spacing: Style.spacingSmall

    Text {
      text: Weather.label
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      color: Colours.bar.text
    }

    Text {
      visible: Weather.current != null
      text: Weather.reportTempNum + "°"
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      color: Colours.bar.textMuted
    }
  }

  WeatherPopup {
    id: popup
    output: root.screen
    monitorName: root.monitorName
  }
}
