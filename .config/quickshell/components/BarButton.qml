import QtQuick
import qs.config
import qs.theme

// Clickable, hoverable bar element with a consistent hit area.
//
// Bar widgets are small glyphs, and a hit area the size of the glyph is
// unpleasant to click, so the target is padded out well beyond the content.
Rectangle {
  id: root

  default property alias content: contentItem.data

  property bool hoverEnabled: true
  property real horizontalPadding: Style.padding

  signal clicked
  signal rightClicked
  signal middleClicked
  signal scrolled(real delta)

  readonly property bool hovered: mouse.containsMouse

  implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2

  // Derived from the configured bar height, NOT from parent.height.
  //
  // Each widget is instantiated inside a Loader, and a Loader takes its size
  // from its item. Sizing the item off parent.height therefore asks the Loader
  // how tall it is while the Loader is asking the item the same question; the
  // cycle resolves to 0 and the widget renders as an invisible zero-height
  // strip. Nothing errors, and the width still computes correctly, which makes
  // it a genuinely confusing failure - the bar looks empty apart from widgets
  // that happen to set their own explicit height.
  implicitHeight: Math.max(20, (Config.bar.height || 38) - 8)

  radius: Style.radiusSmall
  color: root.hovered ? Qt.alpha(Colours.accentAlt, 0.18) : "transparent"

  Behavior on color {
    ColorAnimation {
      duration: Style.animFast
    }
  }

  Item {
    id: contentItem
    anchors.centerIn: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    width: implicitWidth
    height: implicitHeight
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: root.hoverEnabled
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function (event) {
      if (event.button === Qt.RightButton)
        root.rightClicked();
      else if (event.button === Qt.MiddleButton)
        root.middleClicked();
      else
        root.clicked();
    }

    onWheel: function (event) {
      // Normalise to notches. angleDelta is in eighths of a degree and a
      // typical notch is 120, so this yields +/-1 per detent.
      root.scrolled(event.angleDelta.y / 120);
    }
  }
}
