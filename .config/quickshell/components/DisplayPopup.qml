import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// The display panel: a full-screen, transparent, input-grabbing surface just
// like MenuPopup, with the display controls in a card anchored to the button
// that opened it. Same dismissal model - any click anywhere, or Escape, or
// focusing another window, closes it.
//
// Controls mirror Omarchy's Quattro display panel:
//   - TEXT SIZE: a notched slider over curated px stops. Each commit runs
//     display-text-size, which moves the shell font, GTK text-scaling-factor
//     and the terminal point size together. The shell's own Config watches
//     shell.json, so the slider re-tracks the live value after the change.
//   - SCALE: preset pills for the focused monitor. The displayed value is the
//     cleaned scale (what Hyprland will actually apply); clicking runs
//     display-scale, which persists to hyprland/general.lua and reloads.
PanelWindow {
  id: root

  // The bar button the panel opened from; used for placement only.
  property Item anchorItem: null

  // The output this panel lives on, set by the bar. Required for multi-monitor:
  // without it the window would cover the default screen only.
  property var output: null

  // The output NAME of the bar this panel belongs to. The scale section reads
  // and writes THIS monitor, not whatever happens to be focused - clicking the
  // display button on one monitor's bar always controls that monitor.
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

  // Reuses the quickshell-menu namespace so hyprland's existing no_anim
  // layer_rule (hyprland/general.lua) applies to this window too.
  WlrLayershell.namespace: "quickshell-menu"

  color: "transparent"
  visible: false

  function openFor(item) {
    root.anchorItem = item;
    const pos = item.mapToItem(null, 0, 0);
    root.anchorX = pos.x;
    root.anchorW = item.width;
    root.visible = true;
    // The panel is the most likely moment the user is about to read the
    // state, so refresh it on open rather than relying on the poll.
    Display.refresh();
  }

  function closeTree() {
    root.visible = false;
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
        root.closeTree();
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

      implicitWidth: Style.padding * 2 + 320
      implicitHeight: column.implicitHeight + Style.padding * 2

      // Right edge aligns with the button's right edge, clamped on-screen;
      // hangs off the bar's inner edge (above it for a bottom bar).
      x: Math.max(4, Math.min(root.anchorX + root.anchorW - implicitWidth, panelRoot.width - implicitWidth - 4))
      y: root.barAtBottom
          ? Math.max(4, panelRoot.height - root.barHeight - implicitHeight - Style.popupGap)
          : root.barHeight + Style.popupGap

      // Swallows clicks on the card padding so they cannot fall through to the
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

        // ---- hero: display icon + title/status ----
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            text: Display.displays.length > 1 ? "\udb80\udf7a" : "\udb80\udf79"
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize + 6
            color: Colours.popup.text
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.spacing
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              text: "Display"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize
              font.bold: true
              color: Colours.popup.text
              width: parent.width
            }

            Text {
              text: root.monitorName + "  " + Display.scaleFor(root.monitorName) + "x"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeSmall
              color: Colours.bar.textMuted
              width: parent.width
            }
          }
        }

        Separator {}

        // ---- text size ----
        Item {
          width: parent.width
          implicitHeight: Math.max(header.implicitHeight, pxLabel.implicitHeight)

          SectionHeader {
            id: header
            text: "TEXT SIZE"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            id: pxLabel
            text: (textSlider.dragging
                   ? Display.textSizeStops[Math.round(textSlider.liveValue)]
                   : Display.textSize) + "px"
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            font.bold: true
            color: Colours.bar.textMuted
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        TextSizeSlider {
          id: textSlider

          // Snaps to the configured text size, but on a set of curated stops.
          // The "value" is the stop index; drag previews a stop without
          // committing until release.
          property real liveValue: textSlider.knobIndex

          width: parent.width
          stops: Display.textSizeStops.length
          valueIndex: nearestStop(Display.textSize)
          foreground: Colours.popup.text

          function nearestStop(px) {
            let best = 0, bestDist = 1e9;
            for (let i = 0; i < Display.textSizeStops.length; i++) {
              const d = Math.abs(Display.textSizeStops[i] - px);
              if (d < bestDist) {
                bestDist = d;
                best = i;
              }
            }
            return best;
          }

          onCommitted: index => Display.setTextSize(Display.textSizeStops[index])
        }

        Separator {}

        // ---- scale ----
        Item {
          width: parent.width
          implicitHeight: Math.max(scaleHeader.implicitHeight, scaleMonitor.implicitHeight)

          SectionHeader {
            id: scaleHeader
            text: "SCALE"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            id: scaleMonitor
            text: root.monitorName
            visible: Display.displays.length > 1
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            font.bold: true
            color: Colours.bar.textMuted
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Grid {
          id: scaleRow

          width: parent.width
          columns: scalePills.count
          spacing: Style.spacingSmall

          Repeater {
            id: scalePills
            model: ["1", "1.25", "1.6", "2", "3", "4"]

            delegate: ScalePill {
              required property string modelData
              required property int index

              scaleValue: modelData
              monitor: root.monitorName
              cellWidth: (scaleRow.width - scaleRow.spacing * (scaleRow.columns - 1)) / scaleRow.columns
              active: Math.abs(Display.cleanScale(modelData, root.monitorName) - Display.scaleFor(root.monitorName)) < 0.01
            }
          }
        }
      }
    }
  }

  // ---- pieces -----------------------------------------------------------

  component Separator: Rectangle {
    width: parent ? parent.width : 0
    height: 1
    color: Colours.popup.border
  }

  component SectionHeader: Text {
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSizeSmall
    font.bold: true
    font.letterSpacing: 1.1
    color: Colours.bar.textMuted
  }

  // Notched horizontal slider: drag or click, snapping to the nearest stop.
  component TextSizeSlider: Item {
    id: slider

    property int stops: 1
    property int valueIndex: 0
    property color foreground: Colours.popup.text
    property bool dragging: false
    // Hold preview while the helper updates shell.json and the value returns
    // through FileView and Config.
    property int previewIndex: -1
    property int knobIndex: slider.previewIndex >= 0 ? slider.previewIndex : slider.valueIndex

    onValueIndexChanged: {
      if (!slider.dragging && slider.previewIndex === slider.valueIndex) {
        slider.previewIndex = -1;
        commitHold.stop();
      }
    }

    Timer {
      id: commitHold
      interval: 4000
      onTriggered: slider.previewIndex = -1
    }

    signal changed(int index)
    signal committed(int index)

    implicitHeight: 22
    height: 22

    readonly property real knobSize: 14
    readonly property real trackWidth: width - slider.knobSize

    Rectangle {
      id: track

      height: 4
      radius: 2
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: slider.knobSize / 2
      anchors.rightMargin: slider.knobSize / 2
      color: Qt.alpha(slider.foreground, 0.18)
    }

    Rectangle {
      height: 4
      radius: 2
      anchors.left: track.left
      anchors.verticalCenter: parent.verticalCenter
      width: knob.x - track.x
      color: Qt.alpha(slider.foreground, 0.45)
    }

    Rectangle {
      id: knob

      width: slider.knobSize
      height: slider.knobSize
      radius: slider.knobSize / 2
      color: slider.foreground
      x: track.x + slider.trackWidth * knobFraction
      anchors.verticalCenter: parent.verticalCenter

      readonly property real knobFraction: slider.stops > 1 ? slider.knobIndex / (slider.stops - 1) : 0
    }

    Repeater {
      model: slider.stops
      delegate: Rectangle {
        width: 2
        height: 3
        radius: 1
        color: Qt.alpha(slider.foreground, 0.3)
        x: track.x + slider.trackWidth * (slider.stops > 1 ? index / (slider.stops - 1) : 0) - 1
        y: track.y + track.height + 4
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      onPressed: m => {
        slider.dragging = true;
        setFromX(m.x);
      }
      onPositionChanged: m => {
        if (slider.dragging)
          setFromX(m.x);
      }
      onReleased: {
        slider.dragging = false;
        if (slider.previewIndex < 0)
          return;
        if (slider.previewIndex === slider.valueIndex) {
          slider.previewIndex = -1;
          return;
        }
        commitHold.restart();
        slider.committed(slider.previewIndex);
      }
      onCanceled: {
        slider.dragging = false;
        slider.previewIndex = -1;
        commitHold.stop();
      }

      function setFromX(x) {
        const f = Math.max(0, Math.min(1, (x - slider.knobSize / 2) / slider.trackWidth));
        const idx = Math.min(slider.stops - 1, Math.round(f * (slider.stops - 1)));
        slider.previewIndex = idx;
        slider.changed(idx);
      }
    }
  }

  component ScalePill: Rectangle {
    id: pill

    required property string scaleValue
    required property string monitor
    required property real cellWidth
    property bool active: false

    width: pill.cellWidth
    height: 26
    radius: Style.radiusSmall

    color: pill.active
        ? Qt.alpha(Colours.accentAlt, 0.25)
        : (pillArea.containsMouse ? Colours.hover : "transparent")
    border.color: pill.active ? Colours.accentAlt : Qt.alpha(Colours.accentAlt, 0.3)
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: Display.scaleLabel(pill.scaleValue, pill.monitor)
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      color: pill.active ? Colours.popup.text : Colours.bar.textMuted
    }

    MouseArea {
      id: pillArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: Display.setScale(pill.scaleValue, pill.monitor)
    }
  }
}
