import QtQuick
import qs.config
import qs.theme
import qs.services

Text {
  id: root

  // Set from the bar layout entry in shell.json, e.g.
  //   { "id": "clock", "format": "ddd d MMM  HH:mm" }
  property string format: "HH:mm"

  text: Time.format(root.format)
  font.family: Style.fontFamily
  font.pixelSize: Style.fontSize
  color: Colours.bar.text
  verticalAlignment: Text.AlignVCenter
}
