import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.theme
import "ClockModel.js" as ClockModel

// The clock's calendar popup: a month grid anchored to the clock button.
//
// Composition and dismissal mirror WeatherPopup — a full-screen transparent,
// input-grabbing surface with a card hung off the bar button; any click
// anywhere, Escape, or focusing another window closes it. The calendar itself
// is the month-grid from omarchy's Quattro clock panel (six fixed rows, today
// outlined, out-of-month days dimmed), without that panel's year-progress and
// memento-mori rails.
PanelWindow {
  id: root

  // The bar button the panel opened from; used for placement only.
  property Item anchorItem: null

  // The output this panel lives on, set by the bar. Required for
  // multi-monitor: without it the window would cover the default screen only.
  property var output: null

  property string monitorName: ""

  property real anchorX: 0
  property real anchorW: 0

  // ---- calendar state -------------------------------------------------
  // SystemClock keeps this honest across midnight so the highlighted day
  // rolls over without the panel being reopened.
  property date today: new Date()
  readonly property string todayKey: ClockModel.keyForDate(today)

  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()

  // Always Monday-start: the day columns run Mon..Sun. (1 = Monday in
  // JS Date.getDay() terms.)
  readonly property int weekStart: 1
  readonly property var weekdays: ClockModel.weekdayOrder(weekStart)
  readonly property var weeks: ClockModel.monthGrid(viewYear, viewMonth, weekStart, todayKey)

  // Share of the year already gone, pinned to today, not to the month being
  // browsed — stepping through the calendar does not change this.
  readonly property real yearDone: ClockModel.yearProgress(today.getFullYear(), today.getMonth(), today.getDate())
  readonly property int yearDonePercent: ClockModel.yearProgressPercent(today.getFullYear(), today.getMonth(), today.getDate())

  // ---- geometry -------------------------------------------------------
  readonly property int cellWidth: 44
  readonly property int cellHeight: 30
  readonly property int cellSpacing: 3
  readonly property int gridWidth: 7 * root.cellWidth + 6 * root.cellSpacing

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

  // Same layer namespace as the other menus so hyprland's existing no_anim
  // layer_rule (hyprland/general.lua) applies to this window too.
  WlrLayershell.namespace: "quickshell-menu"

  color: "transparent"
  visible: false

  SystemClock {
    precision: SystemClock.Minutes
    onDateChanged: root.today = date
  }

  function openFor(item) {
    root.anchorItem = item
    const pos = item.mapToItem(null, 0, 0)
    root.anchorX = pos.x
    root.anchorW = item.width
    root.today = new Date()
    root.goToToday()
    root.visible = true
  }

  function closeTree() {
    root.visible = false
  }

  function goToToday() {
    root.viewYear = today.getFullYear()
    root.viewMonth = today.getMonth()
  }

  function moveMonth(delta) {
    const next = ClockModel.stepMonth(root.viewYear, root.viewMonth, delta)
    root.viewYear = next.year
    root.viewMonth = next.month
  }

  // JS getDay() (0=Sun) to Qt Locale.dayName() (1=Mon..7=Sun).
  function weekdayLabel(jsDay) {
    return String(Qt.locale().dayName((jsDay + 6) % 7 + 1, Locale.ShortFormat)).toUpperCase()
  }

  // Keyboard: the grab routes input to this window while open, which is what
  // makes Escape work. Click dismissal is the catcher's job.
  HyprlandFocusGrab {
    active: root.visible
    windows: [root]
    onCleared: root.closeTree()
  }

  // Dismissal for clicks landing on another output (this window covers only
  // its own): focusing a window elsewhere closes the panel.
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

      implicitWidth: root.gridWidth + Style.padding * 2
      implicitHeight: column.implicitHeight + Style.padding * 2

      // Centred over the clock button, clamped on-screen; hangs off the
      // bar's inner edge (above it for a bottom bar).
      x: Math.max(4, Math.min(root.anchorX + root.anchorW / 2 - implicitWidth / 2, panelRoot.width - implicitWidth - 4))
      y: root.barAtBottom
          ? Math.max(4, panelRoot.height - root.barHeight - implicitHeight - Style.popupGap)
          : root.barHeight + Style.popupGap

      // Swallows clicks on the card so they cannot fall through to the
      // catcher and close the panel.
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

        // ---- header: month/year centred, prev/next at the grid's edges ----
        Item {
          width: parent.width
          height: 26

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.bold: true
            color: Colours.popup.text
          }

          Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: parent.height
            radius: Style.radiusSmall
            color: prevMouse.containsMouse ? Colours.hover : "transparent"

            Text {
              anchors.centerIn: parent
              text: "‹"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize + 4
              color: prevMouse.containsMouse ? Colours.accentAlt : Colours.popup.text
            }

            MouseArea {
              id: prevMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.moveMonth(-1)
            }
          }

          Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: parent.height
            radius: Style.radiusSmall
            color: nextMouse.containsMouse ? Colours.hover : "transparent"

            Text {
              anchors.centerIn: parent
              text: "›"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize + 4
              color: nextMouse.containsMouse ? Colours.accentAlt : Colours.popup.text
            }

            MouseArea {
              id: nextMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.moveMonth(1)
            }
          }
        }

        // ---- year progress rail: a rule under the header showing how much
        //      of the year is gone ----
        Item {
          width: parent.width
          height: 14

          Text {
            id: yearLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.today.getFullYear()
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            font.letterSpacing: 1
            color: Colours.bar.textMuted
          }

          Text {
            id: yearPercent
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.yearDonePercent + "%"
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.popup.text
          }

          Rectangle {
            id: yearTrack
            anchors.left: yearLabel.right
            anchors.right: yearPercent.left
            anchors.leftMargin: Style.spacing
            anchors.rightMargin: Style.spacing
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Qt.alpha(Colours.popup.text, 0.12)

            Rectangle {
              width: Math.round(parent.width * root.yearDone)
              height: parent.height
              radius: parent.radius
              color: Colours.accent

              Behavior on width {
                NumberAnimation {
                  duration: Style.animNormal
                   easing.type: Style.animEasing
                }
              }
            }
          }
        }

        // ---- weekday heading row: Mon..Sun ----
        Item {
          width: parent.width
          height: 16

          Row {
            spacing: root.cellSpacing

            Repeater {
              model: root.weekdays

              Text {
                required property int modelData
                width: root.cellWidth
                height: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.weekdayLabel(modelData)
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                font.letterSpacing: 1
                font.bold: true
                color: Colours.bar.textMuted
              }
            }
          }
        }

        // ---- month grid ----
        Column {
          width: parent.width
          spacing: root.cellSpacing

          Repeater {
            model: root.weeks

            Row {
              required property var modelData
              spacing: root.cellSpacing

              Repeater {
                model: modelData.days

                Rectangle {
                  required property var modelData

                  width: root.cellWidth
                  height: root.cellHeight
                  radius: Style.radiusSmall
                  // Today is outlined, not filled: a lit-up block shouts over
                  // a grid this quiet.
                  color: "transparent"
                  border.width: modelData.today ? 1 : 0
                  border.color: Colours.accentAlt

                  Text {
                    anchors.centerIn: parent
                    text: modelData.day
                    color: modelData.inMonth
                        ? (modelData.weekend ? Colours.bar.textMuted : Colours.popup.text)
                        : Qt.alpha(Colours.bar.textMuted, 0.5)
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSize
                    font.bold: modelData.today
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
