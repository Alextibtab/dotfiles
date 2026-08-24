import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme
import "../services/QuakeModel.js" as Model

// Earthquake detail panel: a full-screen, transparent, input-grabbing surface
// just like DisplayPopup/WeatherPopup, with a card anchored to the bar button.
// Same dismissal model - any click anywhere, or Escape, or focusing another
// window, closes it.
//
// Content: a hero (big magnitude, place, time/depth/distance) followed by the
// other recent events in the watch region. Each event opens the official USGS
// page; the map glyph opens the coordinates on OpenStreetMap.
PanelWindow {
  id: root

  property Item anchorItem: null
  property var output: null
  property string monitorName: ""

  property real anchorX: 0
  property real anchorW: 0

  readonly property bool barAtBottom: (Config.bar.position || "top") === "bottom"
  readonly property int barHeight: Config.bar.height || 38

  screen: root.output

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

  function roleColor(role) {
    if (role === "urgent") return Colours.urgent
    if (role === "accent") return Colours.accent
    return Colours.muted
  }

  function openUrl(url) {
    if (!url) return
    Quickshell.execDetached(["xdg-open", url])
  }

  function openFor(item) {
    root.anchorItem = item
    const pos = item.mapToItem(null, 0, 0)
    root.anchorX = pos.x
    root.anchorW = item.width
    root.visible = true
    Quake.refresh()
  }

  function closeTree() {
    root.visible = false
  }

  HyprlandFocusGrab {
    active: root.visible
    windows: [root]
    onCleared: root.closeTree()
  }

  Connections {
    target: Hypr
    enabled: root.visible
    function onActiveToplevelChanged() {
      if (Hypr.activeToplevel !== null)
        root.closeTree()
    }
  }

  Item {
    id: panelRoot

    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.closeTree()
    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_R) {
        Quake.refresh()
        event.accepted = true
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: root.closeTree()
    }

    Rectangle {
      id: card

      color: Colours.popup.background
      border.color: Colours.popup.border
      border.width: 1
      radius: Style.radius

      implicitWidth: Style.padding * 2 + 420
      implicitHeight: Math.min(Style.padding * 2 + column.implicitHeight, panelRoot.height - root.barHeight - Style.popupGap - 4)

      x: Math.max(4, Math.min(root.anchorX + root.anchorW - implicitWidth, panelRoot.width - implicitWidth - 4))
      y: root.barAtBottom
          ? Math.max(4, panelRoot.height - root.barHeight - implicitHeight - Style.popupGap)
          : root.barHeight + Style.popupGap

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

        // ---- header: glyph + title + refresh ----
        Item {
          width: parent.width
          implicitHeight: Math.max(titleIcon.implicitHeight, titleText.implicitHeight, refreshBtn.height)

          Text {
            id: titleIcon
            text: Quake.glyph
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize + 6
            color: Quake.alerting ? Colours.urgent : Colours.popup.text
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
            text: "Earthquakes · " + Quake.locationName
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
              text: Quake.refreshing ? "syncing" : "Refresh"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeSmall
              color: Colours.popup.text
            }

MouseArea {
                id: refreshHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quake.refresh()
              }
          }
        }

        // ---- hero: big magnitude + place + meta ----
        Rectangle {
          width: parent.width
          implicitHeight: Math.max(heroMag.height, heroCopy.height)
          radius: Style.radiusSmall
          color: heroMouse.containsMouse && !!Quake.hero ? Colours.hover : "transparent"

          // Clicking the hero opens its official USGS event page.
          MouseArea {
            id: heroMouse
            anchors.fill: parent
            enabled: !!Quake.hero
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openUrl(Model.eventPageUrl(Quake.hero))
          }

          Text {
            id: heroMag
            anchors.left: parent.left
            anchors.leftMargin: Style.paddingSmall
            anchors.verticalCenter: parent.verticalCenter
            text: Quake.hero ? Model.formatMagnitude(Quake.hero.mag) : "—"
            color: Quake.hero ? root.roleColor(Model.magnitudeRole(Quake.hero.mag)) : Colours.bar.textMuted
            font.family: Style.fontFamily
            font.pixelSize: 52
            font.bold: true
          }

          Column {
            id: heroCopy
            anchors.left: heroMag.right
            anchors.leftMargin: Style.spacingLarge
            anchors.right: parent.right
            anchors.rightMargin: Style.paddingSmall
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              width: parent.width
              text: Quake.hero ? Quake.hero.place : "No recent earthquakes"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize
              font.bold: true
              color: Colours.popup.text
              wrapMode: Text.WordWrap
            }

            Text {
              width: parent.width
              text: Quake.hero ? Model.cardMeta(Quake.hero, Quake.useImperial, Quake.nowMs) : Quake.emptyMessage
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeSmall
              color: Colours.bar.textMuted
              wrapMode: Text.WordWrap
            }
          }
        }

        // ---- list of the rest ----
        Flickable {
          id: listScroll
          width: parent.width
          height: Math.min(listCol.implicitHeight, 300)
          contentWidth: width
          contentHeight: listCol.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          visible: Quake.restEvents.length > 0

          Column {
            id: listCol
            width: listScroll.width
            spacing: Style.spacingSmall

            Repeater {
              model: Quake.restEvents

              Rectangle {
                required property var modelData
                required property int index

                width: listCol.width
                implicitHeight: cardRow.implicitHeight + Style.spacing
                radius: Style.radiusSmall
                color: rowMouse.containsMouse ? Colours.hover : Qt.alpha(Colours.accentAlt, 0.05)

                Row {
                  id: cardRow
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.leftMargin: Style.spacingSmall
                  anchors.rightMargin: Style.spacingSmall
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.spacing

                  Rectangle {
                    width: 44
                    height: 26
                    radius: Style.radiusSmall
                    color: Qt.alpha(root.roleColor(Model.magnitudeRole(modelData.mag)), 0.18)

                    Text {
                      anchors.centerIn: parent
                      text: Model.formatMagnitude(modelData.mag)
                      color: root.roleColor(Model.magnitudeRole(modelData.mag))
                      font.family: Style.fontFamily
                      font.pixelSize: Style.fontSize
                      font.bold: true
                    }
                  }

                  Column {
                    width: parent.width - 52
                    spacing: 1

                    Text {
                      width: parent.width
                      text: modelData.place
                      font.family: Style.fontFamily
                      font.pixelSize: Style.fontSize
                      color: Colours.popup.text
                      elide: Text.ElideRight
                    }

                    Text {
                      width: parent.width
                      text: Model.cardMeta(modelData, Quake.useImperial, Quake.nowMs)
                      font.family: Style.fontFamily
                      font.pixelSize: Style.fontSizeSmall
                      color: Colours.bar.textMuted
                      elide: Text.ElideRight
                    }
                  }
                }

                MouseArea {
                  id: rowMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.openUrl(Model.eventPageUrl(modelData))
                }
              }
            }
          }
        }

        // ---- empty / error state ----
        Text {
          visible: Quake.restEvents.length === 0 && Quake.hero === null
          width: parent.width
          text: Quake.emptyMessage
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSizeSmall
          font.italic: true
          color: Colours.bar.textMuted
          horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Colours.popup.border
        }

        // ---- footer ----
        Item {
          width: parent.width
          implicitHeight: Math.max(footerLeft.implicitHeight, footerRight.implicitHeight)

          Text {
            id: footerLeft
            text: Quake.refreshing ? "syncing…" : (Quake.events.length + " events · R refresh")
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.bar.textMuted
          }

          Text {
            id: footerRight
            anchors.right: parent.right
            text: "esc to close"
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.bar.textMuted
          }
        }
      }
    }
  }
}
