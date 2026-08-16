import QtQuick
import qs.theme
import qs.services
import qs.components

// Now playing, from MPRIS.
//
//   click        play/pause
//   right click  next track
//   middle click previous track
//   scroll       next/previous
//
// Replaces waybar's custom/music module, which shelled out to
// `playerctl metadata` on a timer. This reads the D-Bus properties directly, so
// it updates on change rather than on a poll interval.
BarButton {
  id: root

  property int maxWidth: 320

  // Collapse entirely when nothing is playing rather than leaving a stray
  // icon and an empty gap on the bar.
  visible: Player.hasPlayer && Player.label !== ""

  onClicked: Player.toggle()
  onRightClicked: Player.next()
  onMiddleClicked: Player.previous()
  onScrolled: delta => delta > 0 ? Player.previous() : Player.next()

  Row {
    spacing: Style.spacingSmall

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Player.isPlaying ? "\uf04b" : "\uf04c"   // play / pause
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      color: Player.isPlaying ? Colours.accentAlt : Colours.muted

      Behavior on color {
        ColorAnimation {
          duration: Style.animFast
        }
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Player.label
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      color: Colours.bar.text
      elide: Text.ElideRight
      maximumLineCount: 1
      width: Math.min(implicitWidth, root.maxWidth)
    }
  }
}
