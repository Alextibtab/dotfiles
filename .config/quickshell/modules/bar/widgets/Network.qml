import QtQuick
import qs.theme
import qs.services
import qs.components

// Connection state from the Net service (iwd via a helper script - see
// services/Net.qml for why Quickshell's Networking service is unusable here).
//
//   click   force an immediate refresh rather than waiting for the poll
//
// Glyphs: U+F1EB wifi, U+F0997 wifi-off, U+F0297 ethernet (Nerd Font).
BarButton {
  id: root

  onClicked: Net.refresh()

  Text {
    text: {
      if (!Net.connected)
        return "\udb82\udd97";   // wifi-off, U+F0997
      if (Net.kind === "wired")
        return "\udb80\ude97";   // ethernet, U+F0297
      return "\uf1eb";            // wifi
    }
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    color: Net.connected ? Colours.bar.text : Colours.urgent
  }
}
