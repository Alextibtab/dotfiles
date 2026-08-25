import QtQuick
import Quickshell
import qs.theme
import qs.components

// Lock and power buttons.
//
// Both shell out for now, matching what the waybar buttons did:
//   lock  -> hyprlock
//   power -> wlogout
//
// hyprlock directly rather than loginctl lock-session: nothing registers a
// lock handler with the session, so loginctl only marked it locked without
// ever launching hyprlock.
//
// Both are placeholders. The lock screen becomes a Quickshell WlSessionLock in
// a later phase, and the power menu becomes an in-shell panel, at which point
// these call shell IPC instead of spawning processes. wlogout stays installed
// until then so the button always does something.
Row {
  id: root

  property string lockCommand: "hyprlock"
  property string powerCommand: "wlogout"
  property bool showLock: true
  property bool showPower: true

  spacing: Style.spacingSmall

  BarButton {
    visible: root.showLock
    onClicked: Quickshell.execDetached([root.lockCommand])

    Text {
      text: "\uf023"   // padlock
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      color: Colours.bar.text
    }
  }

  BarButton {
    visible: root.showPower
    onClicked: Quickshell.execDetached([root.powerCommand])

    Text {
      text: "\u23fb"   // power symbol, as in the previous waybar config
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      color: Colours.bar.text
    }
  }
}
