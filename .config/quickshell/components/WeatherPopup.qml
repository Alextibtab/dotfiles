import QtQuick
import QtQuick.Controls as QC
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// The weather detail panel: a full-screen, transparent, input-grabbing
// surface just like DisplayPopup, with a card anchored to the bar button.
// Same dismissal model - any click anywhere, or Escape, or focusing another
// window, closes it.
//
// Content mirrors omarchy's Quattro weather panel:
//   - hero: big condition glyph + temperature, location (click to edit, with
//     geocoded suggestions), and feels/wind/humidity stats
//   - a three-day forecast row below a divider
PanelWindow {
  id: root

  // The bar button the panel opened from; used for placement only.
  property Item anchorItem: null

  // The output this panel lives on, set by the bar. Required for multi-monitor:
  // without it the window would cover the default screen only.
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

  // Covering the screen must not reserve an exclusive zone.
  exclusionMode: ExclusionMode.Ignore

  // Same layer namespace as the other menus so hyprland's existing no_anim
  // layer_rule (hyprland/general.lua) applies to this window too.
  WlrLayershell.namespace: "quickshell-menu"

  color: "transparent"
  visible: false

  function openFor(item) {
    root.anchorItem = item
    const pos = item.mapToItem(null, 0, 0)
    root.anchorX = pos.x
    root.anchorW = item.width
    root.visible = true
    Weather.refresh()
  }

  function closeTree() {
    root.visible = false
    Weather.cancelEditingLocation()
  }

  // The search field is created once with the popup, so Component.onCompleted
  // is too early to focus it; only act once editing actually starts.
  Connections {
    target: Weather
    function onEditingLocationChanged() {
      if (Weather.editingLocation)
        Qt.callLater(function () {
          locationField.selectAll()
          locationField.forceActiveFocus()
        })
    }
  }

  // Keyboard: the grab routes input to this window while open, which is what
  // makes Escape work. Click dismissal is the catcher's job.
  HyprlandFocusGrab {
    active: root.visible
    windows: [root]
    onCleared: root.closeTree()
  }

  // Dismissal for clicks landing on another output (this window covers only
  // its own): focusing a window elsewhere closes the panel. The grab stealing
  // keyboard focus on open ALSO fires this signal with null, so only a
  // non-null toplevel counts as a real "user clicked a window".
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

    // The catcher, declared first so the card stacks above it.
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
      implicitHeight: column.implicitHeight + Style.padding * 2

      // Right edge aligns with the button's right edge, clamped on-screen;
      // hangs off the bar's inner edge (above it for a bottom bar).
      x: Math.max(4, Math.min(root.anchorX + root.anchorW - implicitWidth, panelRoot.width - implicitWidth - 4))
      y: root.barAtBottom
          ? Math.max(4, panelRoot.height - root.barHeight - implicitHeight)
          : root.barHeight

      // Swallows clicks on the card padding so they cannot fall through to
      // the catcher and close the panel.
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

        // ---- hero: icon + temp centred in the space left of the location
        //      and stats column, which stays anchored to the right edge ----
        Item {
          width: parent.width
          height: Math.max(heroLeft.implicitHeight, heroRight.height)

          Column {
            id: heroRight
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing

            // Location, or the search field while editing.
            Row {
              visible: !Weather.editingLocation && Weather.reportLocation !== ""
              spacing: Style.spacingSmall

              TapHandler {
                onTapped: Weather.startEditingLocation()
              }
              HoverHandler {
                cursorShape: Qt.PointingHandCursor
              }

              Text {
                text: "\uf041" // nf-fa-map_marker
                anchors.verticalCenter: parent.verticalCenter
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Colours.bar.textMuted
              }

              Text {
                text: Weather.reportLocation.toUpperCase()
                anchors.verticalCenter: parent.verticalCenter
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                font.letterSpacing: 1
                color: Colours.bar.textMuted
              }
            }

            Row {
              visible: Weather.editingLocation
              spacing: Style.spacingSmall

              QC.TextField {
                id: locationField
                width: Style.padding * 2 + 230
                enabled: !Weather.savingLocation
                placeholderText: "Search city"
                placeholderTextColor: Colours.bar.textMuted
                text: Weather.searchText
                color: Colours.popup.text
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                selectByMouse: true
                leftPadding: Style.paddingSmall
                rightPadding: Style.paddingSmall

                background: Rectangle {
                  radius: Style.radiusSmall
                  color: Qt.alpha(Colours.popup.text, 0.06)
                  border.color: Qt.alpha(Colours.popup.text, 0.25)
                  border.width: 1
                }

                onTextChanged: {
                  if (Weather.editingLocation && !Weather.savingLocation)
                    Weather.search(text)
                }

                Keys.onPressed: function (event) {
                  if (event.key === Qt.Key_Escape) {
                    Weather.cancelEditingLocation()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Down) {
                    if (Weather.suggestionIndex < Weather.locationSuggestions.length - 1)
                      Weather.suggestionIndex++
                    event.accepted = true
                  } else if (event.key === Qt.Key_Up) {
                    if (Weather.suggestionIndex > 0)
                      Weather.suggestionIndex--
                    event.accepted = true
                  } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    Weather.commitSearch()
                    event.accepted = true
                  }
                }

              }

              // Clear back to IP auto-detect. While a committed location is
              // loading, this same compact affordance becomes a spinner.
              Rectangle {
                width: Style.fontSize + 6
                height: Style.fontSize + 6
                anchors.verticalCenter: parent.verticalCenter
                radius: Style.radiusSmall
                color: !Weather.savingLocation && clearArea.containsMouse
                    ? Qt.alpha(Colours.accentAlt, 0.25) : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: Weather.savingLocation ? "\uf110" : "\uf00d"
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                  color: Colours.bar.textMuted

                  RotationAnimator on rotation {
                    running: Weather.savingLocation
                    from: 0
                    to: 360
                    duration: 800
                    loops: Animation.Infinite
                  }
                }

                MouseArea {
                  id: clearArea
                  anchors.fill: parent
                  enabled: !Weather.savingLocation
                  hoverEnabled: true
                  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                  onClicked: Weather.clearLocation()
                }
              }
            }

            // Feels / wind / humidity.
            Row {
              visible: !!Weather.current
              spacing: Style.spacing * 3

              Column {
                spacing: 2
                Text {
                  text: "FEELS"
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                  font.letterSpacing: 1
                  color: Colours.bar.textMuted
                }
                Text {
                  text: Weather.reportFeels
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSize
                  color: Colours.popup.text
                }
              }

              Column {
                spacing: 2
                Text {
                  text: "WIND"
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                  font.letterSpacing: 1
                  color: Colours.bar.textMuted
                }
                Text {
                  text: Weather.reportWind
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSize
                  color: Colours.popup.text
                }
              }

              Column {
                spacing: 2
                Text {
                  text: "HUMID"
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                  font.letterSpacing: 1
                  color: Colours.bar.textMuted
                }
                Text {
                  text: Weather.reportHumidity
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSize
                  color: Colours.popup.text
                }
              }
            }
          }

          // The condition glyph + temperature, centred in the space between
          // the card's left edge and the right-hand column.
          Item {
            id: heroLeftZone
            anchors.left: parent.left
            anchors.right: heroRight.left
            anchors.rightMargin: Style.spacingLarge
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Row {
              id: heroLeft
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.spacingSmall

              Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 4
                text: Weather.label || "—"
                font.family: Style.fontFamily
                // Decorative condition glyph; deliberately larger than the
                // body scale.
                font.pixelSize: Style.fontSize + 26
                color: Colours.popup.text
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.reportTempNum || "—"
                font.family: Style.fontFamily
                // Hero temperature read-out; deliberately oversized.
                font.pixelSize: Style.fontSize + 24
                font.bold: true
                color: Colours.popup.text
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 8
                text: Weather.tempUnit
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                color: Colours.popup.text
              }
            }
          }
        }

        // ---- geocoding suggestions while the location is being edited ----
        Column {
          visible: Weather.editingLocation && !Weather.savingLocation && Weather.locationSuggestions.length > 0
          width: parent.width
          spacing: 0

          Repeater {
            model: Weather.locationSuggestions

            Rectangle {
              required property var modelData
              required property int index

              width: parent.width
              height: suggestionRow.implicitHeight + Style.spacing
              radius: Style.radiusSmall
              color: index === Weather.suggestionIndex
                  ? Qt.alpha(Colours.accentAlt, 0.18) : "transparent"

              Row {
                id: suggestionRow
                anchors.left: parent.left
                anchors.leftMargin: Style.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.spacingSmall

                Text {
                  text: modelData.name
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSize
                  color: index === Weather.suggestionIndex ? Colours.accentAlt : Colours.popup.text
                }

                Text {
                  visible: modelData.description !== ""
                  text: modelData.description
                  anchors.verticalCenter: parent.verticalCenter
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                  color: Colours.bar.textMuted
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: Weather.suggestionIndex = index
                onClicked: Weather.pickSuggestion(modelData)
              }
            }
          }
        }

        Text {
          visible: !Weather.current
          text: "Fetching forecast…"
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSizeSmall
          font.italic: true
          color: Colours.bar.textMuted
        }

        // ---- divider between current conditions and forecast ----
        Rectangle {
          visible: Weather.forecastDays.length > 0
          width: parent.width
          height: 1
          color: Colours.popup.border
        }

        // ---- forecast row: day icon + day name + hi/lo, centred ----
        Item {
          visible: Weather.forecastDays.length > 0
          width: parent.width
          height: forecastRow.height

          Row {
            id: forecastRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.spacing * 4

            Repeater {
              model: Weather.forecastDays

              Row {
                required property var modelData
                required property int index

                spacing: Style.spacing

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: Weather.dayIcon(modelData)
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSize + 6
                  color: Colours.popup.text
                }

                Column {
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 2

                  Text {
                    text: Weather.dayName(modelData.date).toUpperCase()
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    font.letterSpacing: 1
                    color: Colours.bar.textMuted
                  }

                  Row {
                    spacing: Style.spacingSmall

                    Text {
                      text: Weather.bareTempForDay(modelData, "max")
                      font.family: Style.fontFamily
                      font.pixelSize: Style.fontSize
                      color: Colours.popup.text
                    }

                    Text {
                      text: Weather.bareTempForDay(modelData, "min")
                      font.family: Style.fontFamily
                      font.pixelSize: Style.fontSize
                      color: Colours.bar.textMuted
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
