pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// The volume panel: a full-screen, transparent, input-grabbing surface just
// like MenuPopup/DisplayPopup, with an audio card anchored to the bar button
// that opened it. Same dismissal model - any click anywhere, Escape, or
// focusing another window closes it.
//
// Controls:
//   - OUTPUT: every audio sink (default first, radio-highlighted). A slider
//     plus mute per device; clicking a device's name makes it the default.
//   - INPUT: the same for sources (mics).
//   - PLAYBACK / RECORDING: active application streams, each with its own
//     volume and mute - a lightweight pavucontrol. Recording streams render
//     with a mic glyph so it is obvious what is being captured.
//
// Volumes are written live while dragging, like pavucontrol. Writes go
// through Audio.setNodeVolume so over-amplification past 1.0 is never set
// from the panel.
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
  }

  function closeTree() {
    root.visible = false;
  }

  // Hover tooltip for elided device/stream names. `at` is the row the pointer
  // is over; the tip hangs above it, flipping below when that would leave the
  // screen. mapToItem handles the Flickable scroll offset for stream rows.
  function showTip(text, at) {
    if (!text) {
      root.hideTip();
      return;
    }
    tip.text = text;
    tip.visible = true;
    const pos = at.mapToItem(panelRoot, at.width / 2, 0);
    tip.x = Math.max(4, Math.min(pos.x - tip.width / 2, panelRoot.width - tip.width - 4));
    tip.y = pos.y - tip.height - 6;
    if (tip.y < 4)
      tip.y = pos.y + at.height + 6;
  }

  function hideTip() {
    tip.visible = false;
  }

  // Default sink/source first, then the rest, so the highlighted device is
  // always on top no matter how many nodes Pipewire reports.
  function sortedByDefault(nodes, defNode) {
    const arr = nodes.slice();
    if (defNode)
      arr.sort((a, b) => (a === defNode ? -1 : 0) - (b === defNode ? -1 : 0));
    return arr;
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
  // keyboard focus on open ALSO fires this signal - with null, since no
  // toplevel is focused any more - so only a non-null toplevel counts as a
  // real "user clicked a window".
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

      implicitWidth: Style.padding * 2 + 340
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

        // ---- hero: speaker glyph + title + default output ----
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            text: "\uf028"
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
              text: "Volume"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize
              font.bold: true
              color: Colours.popup.text
              width: parent.width
            }

            Text {
              text: Audio.sinkName || "no output"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeSmall
              color: Colours.bar.textMuted
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        Separator {}

        // ---- output devices ----
        SectionHeader { text: "OUTPUT" }

        Repeater {
          model: root.sortedByDefault(Audio.sinks, Audio.sink)

          delegate: Item {
            required property var modelData
            width: column.width
            height: 48

            DeviceRow {
              node: modelData
              isDefault: modelData === Audio.sink
              anchors.fill: parent
            }
          }
        }

        EmptyHint {
          visible: Audio.sinks.length === 0
          text: "No output devices"
        }

        Separator {}

        // ---- input devices ----
        SectionHeader { text: "INPUT" }

        Repeater {
          model: root.sortedByDefault(Audio.sources, Audio.source)

          delegate: Item {
            required property var modelData
            width: column.width
            height: 48

            DeviceRow {
              node: modelData
              isDefault: modelData === Audio.source
              mic: true
              anchors.fill: parent
            }
          }
        }

        EmptyHint {
          visible: Audio.sources.length === 0
          text: "No input devices"
        }

        Separator {}

        // ---- active streams ----
        SectionHeader { text: "PLAYBACK" }

        StreamList {
          nodes: Audio.outStreams
          width: column.width
        }

        EmptyHint {
          visible: Audio.outStreams.length === 0
          text: "No active playback"
        }

        SectionHeader {
          text: "RECORDING"
          visible: Audio.inStreams.length > 0
        }

        StreamList {
          nodes: Audio.inStreams
          mic: true
          width: column.width
          visible: Audio.inStreams.length > 0
        }
      }
    }

    // Hover tooltip overlay, declared last so it sits above the card. Driven
    // by root.showTip/hideTip from the device and stream rows.
    Rectangle {
      id: tip
      visible: false
      z: 10
      property string text: ""

      color: Colours.popup.background
      border.color: Colours.popup.border
      border.width: 1
      radius: Style.radiusSmall

      height: tipText.implicitHeight + Style.paddingSmall * 2
      width: Math.min(360, tipText.implicitWidth) + Style.paddingSmall * 2

      Text {
        id: tipText
        anchors.centerIn: parent
        width: parent.width - Style.paddingSmall * 2
        wrapMode: Text.Wrap
        text: tip.text
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        color: Colours.popup.text
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

  component EmptyHint: Text {
    width: parent ? parent.width : 0
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSizeSmall
    color: Colours.bar.textMuted
  }

  // Continuous volume slider: drag or click, committed live (the caller
  // writes the node, which feeds back into `value` - no preview state, no
  // fighting the binding).
  component VolumeSlider: Item {
    id: slider

    property real value: 0
    property color foreground: Colours.popup.text

    signal changed(real value)

    implicitHeight: 20
    height: 20

    readonly property real knobSize: 12
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
      x: track.x + slider.trackWidth * Math.max(0, Math.min(1, slider.value))
      anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      onPressed: m => setFromX(m.x)
      onPositionChanged: m => {
        if (pressed)
          setFromX(m.x);
      }

      function setFromX(x) {
        const v = Math.max(0, Math.min(1, (x - slider.knobSize / 2) / slider.trackWidth));
        slider.changed(v);
      }
    }
  }

  // Mute toggle button: a small pill that also reads as the state.
  component MuteButton: Rectangle {
    id: btn

    required property var node
    property bool mic: false

    readonly property bool muted: btn.node && btn.node.audio ? btn.node.audio.muted : false

    width: 24
    height: 20
    radius: Style.radiusSmall
    color: btn.muted
        ? Qt.alpha(Colours.urgent, 0.22)
        : (btnArea.containsMouse ? Colours.hover : "transparent")

    Text {
      anchors.centerIn: parent
      text: btn.muted
          ? (btn.mic ? "\uf131" : "\uf466")
          : (btn.mic ? "\uf130" : "\uf028")
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      color: btn.muted ? Colours.urgent : Colours.popup.text
    }

    MouseArea {
      id: btnArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: Audio.toggleNodeMute(btn.node)
    }
  }

  // One device: name row (click sets it as default) plus controls row.
  component DeviceRow: Item {
    id: row

    required property var node
    property bool isDefault: false
    property bool mic: false

    height: 48

    readonly property real volume: row.node && row.node.audio ? row.node.audio.volume : 0
    readonly property bool muted: row.node && row.node.audio ? row.node.audio.muted : false

    Rectangle {
      anchors.fill: parent
      radius: Style.radiusSmall
      color: row.isDefault
          ? Qt.alpha(Colours.accentAlt, 0.12)
          : (headArea.containsMouse ? Colours.hover : "transparent")
      border.width: row.isDefault ? 1 : 0
      border.color: Qt.alpha(Colours.accentAlt, 0.4)
    }

    // Name line: radio-style default indicator + label, click to select.
    Item {
      id: head
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.leftMargin: Style.padding
      anchors.rightMargin: Style.padding
      anchors.topMargin: 3
      height: 18

      Text {
        id: indicator
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        text: row.isDefault ? "●" : "○"
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        color: row.isDefault ? Colours.accentAlt : Colours.bar.textMuted
      }

      Text {
        id: nameLabel
        anchors.left: indicator.right
        anchors.right: parent.right
        anchors.leftMargin: Style.spacingSmall
        anchors.verticalCenter: parent.verticalCenter
        text: Audio.nodeLabel(row.node)
        elide: Text.ElideRight
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        color: row.muted ? Colours.bar.textMuted : Colours.popup.text
      }

      MouseArea {
        id: headArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (row.mic)
            Audio.setDefaultSource(row.node);
          else
            Audio.setDefaultSink(row.node);
        }
        onEntered: {
          if (nameLabel.implicitWidth > nameLabel.width)
            root.showTip(Audio.nodeLabel(row.node), row);
        }
        onExited: root.hideTip()
      }
    }

    // Controls line: mute + slider + percentage.
    Item {
      id: controls
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.leftMargin: Style.padding
      anchors.rightMargin: Style.padding
      anchors.bottomMargin: 4
      height: 20

      MuteButton {
        id: muteBtn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        node: row.node
        mic: row.mic
      }

      Text {
        id: percentText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: `${Math.round(row.volume * 100)}%`
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        font.bold: true
        color: Colours.bar.textMuted
        horizontalAlignment: Text.AlignRight
      }

      VolumeSlider {
        anchors.left: muteBtn.right
        anchors.right: percentText.left
        anchors.leftMargin: Style.spacing
        anchors.rightMargin: Style.spacing
        anchors.verticalCenter: parent.verticalCenter
        value: row.volume
        foreground: row.isDefault ? Colours.accentAlt : Colours.popup.text
        onChanged: v => Audio.setNodeVolume(row.node, v)
      }
    }
  }

  // One application stream: same controls as a device, without the
  // set-default behaviour. Recording streams get a red mic glyph.
  component StreamRow: Item {
    id: row

    required property var node
    property bool mic: false

    height: 40

    readonly property real volume: row.node && row.node.audio ? row.node.audio.volume : 0
    readonly property bool muted: row.node && row.node.audio ? row.node.audio.muted : false

    Rectangle {
      anchors.fill: parent
      radius: Style.radiusSmall
      color: streamHover.containsMouse ? Colours.hover : "transparent"
    }

    MouseArea {
      id: streamHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: {
        if (nameText.implicitWidth > nameText.width)
          root.showTip(Audio.nodeLabel(row.node), row);
      }
      onExited: root.hideTip()
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.padding
      anchors.rightMargin: Style.padding
      spacing: Style.spacing

      Text {
        id: nameText
        text: (row.mic ? "\uf130 " : "") + Audio.nodeLabel(row.node)
        elide: Text.ElideRight
        Layout.maximumWidth: 160
        Layout.alignment: Qt.AlignVCenter
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        color: row.muted
            ? Colours.bar.textMuted
            : (row.mic ? Colours.urgent : Colours.popup.text)
      }

      VolumeSlider {
        id: slider
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        value: row.volume
        foreground: Colours.popup.text
        onChanged: v => Audio.setNodeVolume(row.node, v)
      }

      MuteButton {
        id: muteBtn
        Layout.alignment: Qt.AlignVCenter
        node: row.node
        mic: row.mic
      }

      Text {
        id: percentText
        text: `${Math.round(row.volume * 100)}%`
        Layout.alignment: Qt.AlignVCenter
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        font.bold: true
        color: Colours.bar.textMuted
        horizontalAlignment: Text.AlignRight
      }
    }
  }

  // Scrollable list of streams, capped so a dozen open apps cannot stretch
  // the card to fill the screen.
  component StreamList: Item {
    id: list

    property var nodes: []
    property bool mic: false
    property int maxRows: 4

    readonly property int rowHeight: 40

    height: list.nodes.length === 0 ? 0 : Math.min(list.nodes.length, list.maxRows) * list.rowHeight

    Flickable {
      id: flick
      anchors.fill: parent
      clip: true
      contentWidth: width
      contentHeight: list.nodes.length * list.rowHeight
      flickableDirection: Flickable.VerticalFlick
      boundsBehavior: Flickable.StopAtBounds

      Column {
        width: flick.width

        Repeater {
          model: list.nodes

          delegate: Item {
            required property var modelData
            width: list.width
            height: list.rowHeight

            StreamRow {
              node: modelData
              mic: list.mic
              anchors.fill: parent
            }
          }
        }
      }
    }
  }
}