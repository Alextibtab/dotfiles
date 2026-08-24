import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Output volume: icon plus percentage. Clicking opens the volume panel
// (device levels, defaults, and per-app stream control).
//
//   click        toggle the volume panel
//   right click  toggle mic mute
//   middle click open pwvucontrol
//   scroll       adjust volume
//
// A red dot appears on the icon while any app is recording so mic use is
// visible at a glance.
//
// Glyphs match the previous waybar setup so the bar looks familiar:
// \uf026/\uf027/\uf028 for rising level, \uf466 for muted.
BarButton {
  id: root

  property real step: 0.05
  property string mixerCommand: "pwvucontrol"

  // The output this bar instance is on; the panel needs it to cover the
  // correct screen on multi-monitor setups.
  property var screen: null
  property string monitorName: ""

  visible: Audio.ready

  onClicked: popup.visible ? popup.closeTree() : popup.openFor(root)
  onRightClicked: Audio.toggleMicMute()
  onMiddleClicked: Quickshell.execDetached([root.mixerCommand])
  onScrolled: delta => Audio.stepVolume(delta * root.step)

  Row {
    spacing: Style.spacingSmall

    Item {
      width: iconText.implicitWidth
      height: iconText.implicitHeight

      Text {
        id: iconText
        text: {
          if (Audio.muted)
            return "\uf466";
          const v = Audio.volume;
          if (v < 0.34)
            return "\uf026";
          if (v < 0.67)
            return "\uf027";
          return "\uf028";
        }
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        color: Audio.muted ? Colours.muted : Colours.bar.text
      }

      // Mic-in-use indicator: any open capture stream lights a red dot in
      // the glyph's top corner.
      Rectangle {
        visible: Audio.isRecording
        anchors.top: parent.top
        anchors.right: parent.right
        width: 8
        height: 8
        radius: 4
        color: Colours.urgent
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: `${Math.round(Audio.volume * 100)}%`
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      // Dim the number while muted so the state reads at a glance without
      // having to decode the glyph.
      color: Audio.muted ? Colours.muted : Colours.bar.text
    }
  }

  VolumePanel {
    id: popup
    output: root.screen
    monitorName: root.monitorName
  }
}