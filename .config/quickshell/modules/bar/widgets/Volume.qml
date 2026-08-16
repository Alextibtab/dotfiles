import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Output volume: icon plus percentage.
//
//   click        toggle mute
//   right click  toggle mic mute
//   middle click open pwvucontrol
//   scroll       adjust volume
//
// Glyphs match the previous waybar setup so the bar looks familiar:
// \uf026/\uf027/\uf028 for rising level, \uf466 for muted.
BarButton {
  id: root

  property real step: 0.05
  property string mixerCommand: "pwvucontrol"

  visible: Audio.ready

  onClicked: Audio.toggleMute()
  onRightClicked: Audio.toggleMicMute()
  onMiddleClicked: Quickshell.execDetached([root.mixerCommand])
  onScrolled: delta => Audio.stepVolume(delta * root.step)

  Row {
    spacing: Style.spacingSmall

    Text {
      anchors.verticalCenter: parent.verticalCenter
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
}
