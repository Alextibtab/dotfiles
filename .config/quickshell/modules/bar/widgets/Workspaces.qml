import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.theme
import qs.services

// Per-monitor workspace indicator.
//
// Shows exactly the block of workspaces that split-monitor-workspaces assigned
// to THIS monitor: base+1 .. base+perMonitor. Labels are the local 1..N index
// by default, so what you see matches the SUPER+<n> keybind you press, not the
// absolute Hyprland id (which is 6..10 on the second monitor).
//
// The Repeater model is a fixed count rather than the live workspace list.
// Hyprland only materialises a workspace once it is used, so binding to the
// list would make empty slots pop in and out and the bar would reflow as you
// work. A fixed count keeps the row geometrically stable.
Row {
  id: root

  required property var monitorName

  spacing: Style.spacingSmall

  readonly property int base: Hypr.baseFor(root.monitorName)

  Repeater {
    model: Hypr.perMonitor

    delegate: Rectangle {
      id: chip

      required property int index

      readonly property int localIndex: index + 1
      readonly property int globalId: root.base + localIndex

      // Re-evaluates when workspaces are created or destroyed, because
      // workspaceById reads Hyprland.workspaces.values.
      readonly property var ws: Hypr.workspaceById(globalId)

      // Bind to the workspace object's own properties so focus changes
      // repaint without needing the outer lookup to re-run.
      readonly property bool isActive: ws ? ws.active : false
      readonly property bool isUrgent: ws ? ws.urgent : false
      readonly property int windows: Hypr.windowCount(ws)
      readonly property bool isOccupied: windows > 0

      visible: Config.workspaces.showEmpty || isOccupied || isActive

      implicitWidth: isActive ? 28 : 20
      implicitHeight: 20
      radius: Style.radiusSmall

      color: {
        if (isUrgent)
          return Colours.workspace.urgent;
        if (isActive)
          return Qt.alpha(Colours.workspace.active, 0.20);
        if (mouse.containsMouse)
          return Colours.workspace.hover;
        return "transparent";
      }

      Behavior on implicitWidth {
        NumberAnimation {
          duration: Style.animNormal
          easing.type: Style.animEasing
        }
      }
      Behavior on color {
        ColorAnimation {
          duration: Style.animFast
        }
      }

      Text {
        anchors.centerIn: parent
        text: Config.workspaces.localNumbering ? chip.localIndex : chip.globalId
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        font.bold: chip.isActive
        color: {
          if (chip.isUrgent)
            return Colours.bar.text;
          if (chip.isActive)
            return Colours.workspace.active;
          if (chip.isOccupied)
            return Colours.workspace.occupied;
          return Colours.workspace.empty;
        }

        Behavior on color {
          ColorAnimation {
            duration: Style.animFast
          }
        }
      }

      MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: Hypr.focusWorkspace(chip.globalId)
      }
    }
  }
}
