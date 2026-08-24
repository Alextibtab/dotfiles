import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.theme

// System update indicator (Arch + AUR).
//
//   click        toggle the update panel
//   middle click force a refresh
//
// The panel lists each installed repo (Arch, AUR) with its update count and
// an Update button. Clicking Update launches a dedicated, floating, centered
// terminal (see the "system-updates" window rule in ~/.config/hypr/hyprland/
// rules.lua) on the monitor this bar belongs to, running the repo's update
// command. Normal terminal windows are unaffected.
//
// Settings come from the bar layout entry, e.g.
//   { "id": "systemUpdates", "refreshIntervalSec": 1800, "alwaysShow": true }
BarButton {
  id: root

  // The output this bar instance is on; the panel and the launched terminal
  // must target the same monitor the user clicked.
  property var screen: null
  property string monitorName: ""

  property int refreshIntervalSec: 1800
  property bool alwaysShow: true

  // The terminal used for updates. The Hyprland window rule in
  // ~/.config/hypr/hyprland/rules.lua floats+centers the window by its
  // "System Updates" title.
  property string updateTerminal: "ghostty"

  // Counts come from the shared SystemUpdates service so that all monitors
  // report the same numbers and only one scanner runs at a time.
  readonly property var installedRepos: {
    var out = []
    for (var i = 0; i < SystemUpdates.repos.length; i++)
      if (SystemUpdates.repos[i].installed === true)
        out.push(SystemUpdates.repos[i])
    return out
  }

  readonly property int total: SystemUpdates.total
  readonly property int updateCount: SystemUpdates.total

  readonly property string glyph: "\uDB80\uDDA7" // 󰆧 (nf-md-cloud_alert / download)

  function refresh() {
    SystemUpdates.refresh()
  }

  function launchUpdate(repo) {
    if (!repo || !repo.updateCmd)
      return

    // The bar is a layer surface, so clicking it does not focus its monitor.
    // Focus the clicked monitor first so the terminal opens there, centered.
    if (root.monitorName)
      Hypr.dispatch(`hl.dsp.focus({ monitor = "${root.monitorName}" })`)

    // `-e` forces a separate ghostty instance (so exactly one window opens)
    // and runs the update command inside it.
    Quickshell.execDetached([root.updateTerminal,
      "--title=System Updates",
      "-e", "bash", "-c", repo.updateCmd])

    popup.closeTree()
  }

  visible: root.total > 0 || root.alwaysShow

  onClicked: popup.visible ? popup.closeTree() : popup.openFor(root)
  onMiddleClicked: root.refresh()

  Row {
    spacing: Style.spacingSmall

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.glyph
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      color: root.total > 0 ? Colours.accentAlt : Colours.bar.textMuted
    }

    Text {
      visible: root.total > 0
      anchors.verticalCenter: parent.verticalCenter
      text: String(root.total)
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      font.bold: true
      color: Colours.bar.text
    }
  }

  onRefreshIntervalSecChanged: SystemUpdates.refreshIntervalSec = Math.max(300, root.refreshIntervalSec)

  Component.onCompleted: {
    SystemUpdates.refreshIntervalSec = Math.max(300, root.refreshIntervalSec)
    root.refresh()
  }

  SystemUpdatesPopup {
    id: popup
    output: root.screen
    monitorName: root.monitorName
  }

  component SystemUpdatesPopup: PanelWindow {
    id: panel

    property Item anchorItem: null
    property var output: null
    property string monitorName: ""

    property real anchorX: 0
    property real anchorW: 0

    readonly property bool barAtBottom: (Config.bar.position || "top") === "bottom"
    readonly property int barHeight: Config.bar.height || 38

    screen: panel.output

    anchors {
      left: true
      right: true
      top: true
      bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-menu"

    color: "transparent"
    visible: false

    function openFor(item) {
      root.refresh()
      panel.anchorItem = item
      const pos = item.mapToItem(null, 0, 0)
      panel.anchorX = pos.x
      panel.anchorW = item.width
      panel.visible = true
    }

    function closeTree() {
      panel.visible = false
    }

    HyprlandFocusGrab {
      active: panel.visible
      windows: [panel]
      onCleared: panel.closeTree()
    }

    Connections {
      target: Hypr
      enabled: panel.visible
      function onActiveToplevelChanged() {
        if (Hypr.activeToplevel !== null)
          panel.closeTree()
      }
    }

    Item {
      id: panelRoot

      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: panel.closeTree()

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: panel.closeTree()
      }

      Rectangle {
        id: card

        color: Colours.popup.background
        border.color: Colours.popup.border
        border.width: 1
        radius: Style.radius

        implicitWidth: Style.padding * 2 + 320
        implicitHeight: column.implicitHeight + Style.padding * 2

        x: Math.max(4, Math.min(panel.anchorX + panel.anchorW - implicitWidth, panelRoot.width - implicitWidth - 4))
        y: panel.barAtBottom
            ? Math.max(4, panelRoot.height - panel.barHeight - implicitHeight - Style.popupGap)
            : panel.barHeight + Style.popupGap

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onClicked: {}
        }

        Column {
          id: column

          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Style.padding
          }
          spacing: Style.spacing

          Item {
            width: parent.width
            implicitHeight: Math.max(titleIcon.implicitHeight, titleText.implicitHeight, refreshBtn.height)

            Text {
              id: titleIcon
              text: root.glyph
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize + 6
              color: root.total > 0 ? Colours.accentAlt : Colours.popup.text
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: titleText
              anchors.left: titleIcon.right
              anchors.leftMargin: Style.spacing
              anchors.right: refreshBtn.left
              anchors.rightMargin: Style.spacing
              anchors.verticalCenter: parent.verticalCenter
              text: "System Updates"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize
              font.bold: true
              color: Colours.popup.text
              elide: Text.ElideRight
            }

            Rectangle {
              id: refreshBtn
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: refreshLabel.implicitWidth + Style.padding * 2
              height: 22
              radius: Style.radiusSmall
              color: refreshHover.containsMouse ? Colours.hover : "transparent"
              border.color: Qt.alpha(Colours.accentAlt, 0.4)
              border.width: 1

              Text {
                id: refreshLabel
                anchors.centerIn: parent
                text: (SystemUpdates.refreshing ? "Refreshing\u2026" : "Refresh")
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Colours.popup.text
              }

              MouseArea {
                id: refreshHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refresh()
              }
            }
          }

          Separator {}

          Repeater {
            model: root.installedRepos

            delegate: Rectangle {
              required property var modelData
              width: parent.width
              implicitHeight: repoRow.implicitHeight + Style.spacing
              radius: Style.radiusSmall
              color: Qt.alpha(Colours.accentAlt, 0.06)
              border.color: Colours.popup.border
              border.width: 1

              RowLayout {
                id: repoRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Style.spacing
                anchors.rightMargin: Style.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.spacing

                Column {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    text: modelData.name
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSize
                    font.bold: true
                    color: Colours.popup.text
                  }

                  Text {
                    text: modelData.count > 0
                      ? modelData.count + (modelData.count === 1 ? " update available" : " updates available")
                      : "Up to date"
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: modelData.count > 0 ? Colours.popup.text : Colours.bar.textMuted
                  }
                }

                Text {
                  visible: modelData.pkgCount > 0
                  text: modelData.pkgCount + " pkgs"
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                  color: Colours.bar.textMuted
                }

                UpdateButton {
                  text: "Update"
                  active: modelData.count > 0
                  onClicked: root.launchUpdate(modelData)
                }
              }
            }
          }

          Text {
            width: parent.width
            visible: {
              if (root.installedRepos.length === 0)
                return false
              for (var i = 0; i < root.installedRepos.length; i++)
                if (root.installedRepos[i].count > 0)
                  return false
              return true
            }
            text: "System is up to date."
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.bar.textMuted
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            width: parent.width
            text: "esc to close"
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.bar.textMuted
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }

  component Separator: Rectangle {
    width: parent ? parent.width : 0
    height: 1
    color: Colours.popup.border
  }

  component UpdateButton: Rectangle {
    id: btn

    property string text: ""
    property bool active: true

    signal clicked()

    implicitHeight: Math.max(24, label.implicitHeight + Style.spacingSmall)
    implicitWidth: label.implicitWidth + Style.padding * 2
    radius: Style.radiusSmall
    color: btnHover.containsMouse
        ? Colours.hover
        : Qt.alpha(Colours.accentAlt, 0.08)
    border.color: Qt.alpha(Colours.accentAlt, btn.active ? 0.5 : 0.25)
    border.width: 1

    Text {
      id: label
      anchors.centerIn: parent
      text: btn.text
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      color: btn.active ? Colours.popup.text : Colours.bar.textMuted
    }

    MouseArea {
      id: btnHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: btn.clicked()
    }
  }
}
