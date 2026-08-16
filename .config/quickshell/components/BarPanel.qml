import Quickshell
import QtQuick
import qs.config
import qs.theme

// One bar surface on one monitor.
//
// Reserves an exclusive zone so tiled windows are pushed out of the way
// rather than being overlapped. Anchored to left+right plus the configured
// edge, which is what makes the panel span the monitor's full width.
PanelWindow {
  id: root

  default property alias content: contentItem.data

  readonly property bool atTop: (Config.bar.position || "top") !== "bottom"

  color: "transparent"

  anchors {
    top: root.atTop
    bottom: !root.atTop
    left: true
    right: true
  }

  implicitHeight: Config.bar.height || 38

  Rectangle {
    anchors.fill: parent
    color: Colours.bar.background

    // A single hairline on the inner edge. Cheaper than a shadow and it
    // still separates the bar from a same-coloured window underneath.
    Rectangle {
      width: parent.width
      height: 1
      color: Colours.bar.border
      anchors.top: root.atTop ? undefined : parent.top
      anchors.bottom: root.atTop ? parent.bottom : undefined
    }

    Item {
      id: contentItem
      anchors.fill: parent
      anchors.leftMargin: Style.spacing
      anchors.rightMargin: Style.spacing
    }
  }
}
