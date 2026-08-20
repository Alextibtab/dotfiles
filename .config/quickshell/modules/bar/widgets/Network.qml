import QtQuick
import qs.theme
import qs.services
import qs.components

// Connection state from the Net service (iwd via a helper script - see
// services/Net.qml for why Quickshell's Networking service is unusable here).
//
//   click   force an immediate refresh rather than waiting for the poll
//
// Glyphs follow the previous waybar config: \uf1eb wifi, \U000f0297 ethernet.
BarButton {
  id: root

  onClicked: Net.refresh()

  Text {
    text: {
      if (!Net.connected)
        return "\U000f0997";      // wifi-off
      if (Net.kind === "wired")
        return "\U000f0297";      // ethernet
      return "\uf1eb";            // wifi
    }
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    color: Net.connected ? Colours.bar.text : Colours.urgent
  }
}
