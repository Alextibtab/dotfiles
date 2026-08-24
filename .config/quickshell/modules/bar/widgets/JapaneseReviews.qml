import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.theme

// Japanese study review tracker: one glyph showing the total reviews due
// across WaniKani, Bunpro and Anki. Clicking toggles the panel, which lists
// each service with its count and a Study button that jumps straight into
// that service's review session.
//
//   click        toggle the panel
//   middle click force a refresh
//
// Settings come from the bar layout entry, e.g.
//   { "id": "japaneseReviews", "refreshIntervalSec": 120 }
//
// Tokens for WaniKani/Bunpro live in services/secrets.json; Anki needs the
// AnkiConnect addon running.
BarButton {
  id: root

  // The output this bar instance is on; the panel must cover the correct
  // screen on multi-monitor setups.
  property var screen: null
  property string monitorName: ""

  property int refreshIntervalSec: Config.japaneseReviews.refreshIntervalSec || 300

  readonly property int total: JapaneseReviews.total

  readonly property string glyph: "\uF02D" //  (nf-fa-book)

  function statusText(s) {
    if (!s.ok) {
      if (s.status !== "")
        return s.status;
      return "unavailable";
    }
    if (s.due === 0)
      return "up to date";
    const parts = [s.due + " due"];
    if (s.lessons > 0)
      parts.push(s.lessons + " lessons");
    return parts.join(" \u00b7 ");
  }

  function openService(id) {
    if (root.monitorName)
      Hypr.dispatch(`hl.dsp.focus({ monitor = "${root.monitorName}" })`);
    Quickshell.execDetached(["python3", JapaneseReviews.scannerPath, "--open", id]);
    popup.closeTree();
  }

  onRefreshIntervalSecChanged: JapaneseReviews.refreshIntervalSec = Math.max(60, root.refreshIntervalSec)

  onClicked: popup.visible ? popup.closeTree() : popup.openFor(root)
  onMiddleClicked: JapaneseReviews.refresh()

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

  Component.onCompleted: {
    JapaneseReviews.refreshIntervalSec = Math.max(60, root.refreshIntervalSec)
    JapaneseReviews.refresh()
  }

  JapanesePopup {
    id: popup
    output: root.screen
    monitorName: root.monitorName
  }

  component JapanesePopup: PanelWindow {
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
      JapaneseReviews.refresh()
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
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_R) {
          JapaneseReviews.refresh()
          event.accepted = true
        }
      }

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
              text: "Japanese Reviews"
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
                text: (JapaneseReviews.refreshing ? "Refreshing\u2026" : "Refresh")
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Colours.popup.text
              }

              MouseArea {
                id: refreshHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: JapaneseReviews.refresh()
              }
            }
          }

          Separator {}

          Repeater {
            model: JapaneseReviews.services

            delegate: Rectangle {
              required property var modelData
              width: parent.width
              implicitHeight: serviceRow.implicitHeight + Style.spacing
              radius: Style.radiusSmall
              color: Qt.alpha(Colours.accentAlt, 0.06)
              border.color: Colours.popup.border
              border.width: 1

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openService(modelData.id)
              }

              RowLayout {
                id: serviceRow
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
                    text: root.statusText(modelData)
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: modelData.ok
                        ? (modelData.due > 0 ? Colours.popup.text : Colours.bar.textMuted)
                        : Colours.urgent
                  }
                }

                StudyButton {
                  text: (modelData.id === "anki" && !modelData.ok) ? "Launch" : "Study"
                  onClicked: root.openService(modelData.id)
                }
              }
            }
          }

          Text {
            width: parent.width
            visible: {
              if (JapaneseReviews.services.length === 0)
                return true
              for (var i = 0; i < JapaneseReviews.services.length; i++)
                if (JapaneseReviews.services[i].ok)
                  return false
              return true
            }
            text: "No reviews tracked. Add tokens to services/secrets.json (and install the AnkiConnect addon for Anki)."
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.bar.textMuted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
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

  component StudyButton: Rectangle {
    id: btn

    property string text: ""

    signal clicked()

    implicitHeight: Math.max(24, label.implicitHeight + Style.spacingSmall)
    implicitWidth: label.implicitWidth + Style.padding * 2
    radius: Style.radiusSmall
    color: btnHover.containsMouse
        ? Colours.hover
        : Qt.alpha(Colours.accentAlt, 0.08)
    border.color: Qt.alpha(Colours.accentAlt, 0.5)
    border.width: 1

    Text {
      id: label
      anchors.centerIn: parent
      text: btn.text
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      color: Colours.popup.text
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