import QtQuick
import Quickshell
import qs.theme
import qs.components

// Lock and power buttons.
//
// Both shell out for now, matching what the waybar buttons did:
//   lock  -> loginctl lock-session
//   power -> wlogout
//
// loginctl rather than invoking hyprlock directly: it routes through systemd so
// the session is properly marked locked, which also means a future idle daemon
// and this button take the same path. hyprlock itself is wired up as the
// session's lock handler.
//
// Both are placeholders. The lock screen becomes a Quickshell WlSessionLock in
// a later phase, and the power menu becomes an in-shell panel, at which point
// these call shell IPC instead of spawning processes. wlogout stays installed
// until then so the button always does something.
Row {
  id: root

  property string lockCommand: "loginctl lock-session"
  property string powerCommand: "wlogout"
  property bool showLock: true
  property bool showPower: true

  spacing: Style.spacingSmall

  BarButton {
    visible: root.showLock
    onClicked: Quickshell.execDetached(["sh", "-c", root.lockCommand])

    Text {
      text: "\uf023"   // padlock
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      color: Colours.bar.text
    }
  }

  BarButton {
    visible: root.showPower
    onClicked: Quickshell.execDetached(["sh", "-c", root.powerCommand])

    Text {
      text: "\u23fb"   // power symbol, as in the previous waybar config
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      // Power is destructive; tint it so it is distinguishable from the
      // neighbouring glyphs at a glance.
      color: Colours.urgent
    }
  }
}
