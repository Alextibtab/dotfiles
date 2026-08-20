import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.components

// Display settings button. Opens the display panel (text size + scale, the
// same idea as Omarchy Quattro's display widget); the glyph shows one or two
// monitors depending on how many are connected.
//
//   click    toggle the display panel
BarButton {
  id: root

  // The output this bar instance is on; the panel needs it to cover the
  // correct screen on multi-monitor setups.
  property var screen: null

  // This bar's output name. The panel targets THIS monitor for scale changes,
  // so the button always controls the monitor its bar sits on.
  property string monitorName: ""

  onClicked: popup.visible ? popup.closeTree() : popup.openFor(root)

  Text {
    text: Quickshell.screens.length > 1 ? "\udb80\udf7a" : "\udb80\udf79"
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    color: Colours.bar.text
  }

  DisplayPopup {
    id: popup
    output: root.screen
    monitorName: root.monitorName
  }
}
