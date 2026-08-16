import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.theme
import qs.services

// Title of the focused window on THIS monitor.
//
// Hyprland.activeToplevel is global: without the monitor check, both bars
// would show the same title, including the bar on the monitor you are not
// looking at. We only render when the focused toplevel actually lives here.
Text {
  id: root

  required property var monitorName
  property int maxWidth: 600

  readonly property var toplevel: Hypr.activeToplevel
  readonly property bool onThisMonitor: {
    const t = root.toplevel;
    if (!t || !t.monitor)
      return false;
    return t.monitor.name === root.monitorName;
  }

  text: onThisMonitor && toplevel.title ? toplevel.title : ""
  visible: text !== ""

  font.family: Style.fontFamily
  font.pixelSize: Style.fontSize
  color: Colours.bar.textMuted

  elide: Text.ElideRight
  maximumLineCount: 1
  width: Math.min(implicitWidth, root.maxWidth)
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
}
