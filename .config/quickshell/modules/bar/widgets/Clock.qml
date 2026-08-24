import QtQuick
import Quickshell
import qs.config
import qs.theme
import qs.services
import qs.components

// Date/time label for the bar. Clicking toggles the calendar panel.
//
//   click   toggle the calendar popup
//
// Settings come from the bar layout entry, e.g.
//   { "id": "clock", "format": "HH:mm" }
BarButton {
  id: root

  property string format: "HH:mm"

  // The output this bar instance is on; the popup needs it to cover the
  // correct screen on multi-monitor setups.
  property var screen: null
  property string monitorName: ""

  onClicked: popup.visible ? popup.closeTree() : popup.openFor(root)

  Text {
    text: Time.format(root.format)
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    color: Colours.bar.text
    verticalAlignment: Text.AlignVCenter
  }

  ClockPanel {
    id: popup
    output: root.screen
    monitorName: root.monitorName
  }
}
