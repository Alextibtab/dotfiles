import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme

// One level of a DBus menu: the frame, its entries, and any open submenu.
//
// Lives inside MenuPopup's full-screen window rather than in its own window,
// so every level shares one coordinate space and the window's click-catcher
// sits deterministically beneath all of them.
//
// Submenus recurse: a row with children opens another MenuLevel cascading
// from it, flipping to the left near the window's edge. One shared Loader per
// level, retargeted as hover moves between rows, sitting OUTSIDE the clipped
// scrollport - a submenu parented to its row would be clipped away by the
// Flickable. The Loader dodges the compile-time ban on direct type recursion
// by loading this file by URL.
Item {
  id: root

  // The handle whose children this level shows: SystemTrayItem.menu on the
  // root level, a QsMenuEntry (itself a handle) on submenus.
  property var menu: null

  // null on the root level; the MenuLevel this one cascades from otherwise.
  property var parentLevel: null

  // The row this level cascades from; null on the root level, which is
  // positioned by MenuPopup instead. Bound to the parent level's
  // openSubmenuRow, so retargeting re-runs the placement bindings.
  property Item anchorRow: null

  // Size of the hosting window, handed down so overflow checks need no
  // non-reactive window lookups.
  property real windowWidth: 0
  property real windowHeight: 0

  // Tallest content height before the level scrolls instead of growing: a
  // share of the screen so a long menu (nordvpn's "All connections" ships an
  // entry per country) never dominates the display. The rest is reachable by
  // scrolling.
  property real maxHeightRatio: 0.35
  readonly property real maxContentHeight: Math.max(120, Math.floor(windowHeight * root.maxHeightRatio))

  // Wheel scroll multiplier: one notch (angleDelta 120) moves the content by
  // 120 * wheelSpeed px. Higher scrolls faster through long lists.
  property real wheelSpeed: 2.5

  // Asks the hosting window to close the whole tree. Only connected on the
  // root level; closeTree() walks up to it.
  signal requestClose()

  function closeTree() {
    let l = root;
    while (l.parentLevel)
      l = l.parentLevel;
    l.requestClose();
  }

  // Collapse any open submenu; the window calls this on close so a reopened
  // menu starts with every level folded.
  function collapseSubmenus() {
    column.openSubmenuRow = null;
  }

  implicitWidth: frame.implicitWidth
  implicitHeight: frame.implicitHeight

  // Submenu self-placement. The level is parented to the parent level's
  // submenu Loader, which sits at that level's origin, so the anchor row is
  // mapped into parentLevel's coordinates for placement and into window
  // coordinates for the overflow check. Open at the row's right edge,
  // flipping to its left when that would leave the window; drop from the
  // row's top, shifting up when it would run off the bottom. mapToItem is
  // not reactive; these bindings re-read it when anchorRow changes or when
  // the async D-Bus content changes our size - rows never move otherwise
  // (scrolling the parent with a submenu open is not tracked).
  x: {
    if (!root.anchorRow || !root.parentLevel)
      return 0;
    const p = root.anchorRow.mapToItem(root.parentLevel, root.anchorRow.width, 0);
    const winX = root.anchorRow.mapToItem(null, root.anchorRow.width, 0).x;
    const fitsRight = winX + root.implicitWidth <= root.windowWidth - 4;
    return fitsRight ? p.x : p.x - root.anchorRow.width - root.implicitWidth;
  }
  y: {
    if (!root.anchorRow || !root.parentLevel)
      return 0;
    const p = root.anchorRow.mapToItem(root.parentLevel, 0, 0);
    const winY = root.anchorRow.mapToItem(null, 0, 0).y;
    const overflow = winY + root.implicitHeight - (root.windowHeight - 4);
    return p.y - (overflow > 0 ? overflow : 0);
  }

  QsMenuOpener {
    id: opener
    menu: root.menu
  }

  Rectangle {
    id: frame

    anchors.fill: parent
    implicitWidth: column.implicitWidth + Style.paddingSmall * 2
    implicitHeight: Math.min(column.implicitHeight, root.maxContentHeight) + Style.paddingSmall * 2

    color: Colours.popup.background
    border.color: Colours.popup.border
    border.width: 1
    radius: Style.radius

    // Swallows clicks on the frame padding so they cannot fall through to the
    // window's click-catcher and close the menu. Doubles as the wheel
    // scroller: rows do not accept wheel events, so they fall through here.
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: {}
      onWheel: wheel => {
        if (flick.contentHeight <= flick.height)
          return;
        flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, flick.contentY - wheel.angleDelta.y * root.wheelSpeed));
        wheel.accepted = true;
      }
    }

    // Clipped scrollport for overlong menus. A Repeater inside a Flickable
    // rather than a ListView, deliberately: ListView destroys scrolled-out
    // delegates, which would drop any row's open submenu mid-flight; with a
    // Repeater every row lives as long as the menu does, and row positions
    // (submenu anchors) stay valid at any scroll offset.
    Flickable {
      id: flick

      anchors.centerIn: parent
      width: column.implicitWidth
      height: Math.min(column.implicitHeight, root.maxContentHeight)

      clip: true
      contentWidth: column.width
      contentHeight: column.height
      flickableDirection: Flickable.VerticalFlick
      boundsBehavior: Flickable.StopAtBounds

      // ColumnLayout rather than Column: positioners derive their implicit
      // size from children's width/height, unusable here (rows want
      // width: column.width for the full-width hover strip, deadlocking at
      // zero). Layouts derive implicit size from children's implicit sizes
      // and then stretch fillWidth children to it.
      ColumnLayout {
        id: column

        width: flick.width
        spacing: 0

        // Row whose submenu is open, so hovering a sibling replaces it. Leaving
        // a row does NOT close it - that slack is what lets the pointer travel
        // from the row into its submenu without the menu vanishing under it.
        property Item openSubmenuRow: null

        Repeater {
          model: opener.children
          delegate: Item {
            id: row

            required property var modelData

            Layout.fillWidth: true
            implicitWidth: rowContent.visible ? rowContent.implicitWidth : 1
            implicitHeight: rowContent.visible ? rowContent.implicitHeight : 9

            Rectangle {
              visible: row.modelData.isSeparator
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.leftMargin: Style.padding
              anchors.rightMargin: Style.padding
              height: 1
              color: Colours.popup.border
            }

            Rectangle {
              id: rowContent

              visible: !row.modelData.isSeparator
              anchors.fill: parent
              radius: Style.radiusSmall
              color: hoverArea.containsMouse && row.modelData.enabled
                  ? Qt.alpha(Colours.accentAlt, 0.18)
                  : "transparent"

              implicitWidth: Style.padding * 2 + gutter.width + Style.spacingSmall
                  + Math.min(label.implicitWidth, 360) + Style.spacing + 14
              implicitHeight: Style.fontSize + 16

              // Left gutter: the check/radio mark if the entry has one, else
              // its icon. Fixed width on every row so labels stay aligned.
              Item {
                id: gutter
                anchors.left: parent.left
                anchors.leftMargin: Style.padding
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14

                Text {
                  anchors.centerIn: parent
                  visible: row.modelData.buttonType !== QsMenuButtonType.None
                  text: row.modelData.checkState === Qt.Checked
                      ? (row.modelData.buttonType === QsMenuButtonType.RadioButton ? "●" : "✓")
                      : ""
                  color: Colours.popup.text
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                }

                Image {
                  anchors.fill: parent
                  visible: row.modelData.buttonType === QsMenuButtonType.None && row.modelData.icon !== ""
                  source: row.modelData.icon
                  sourceSize: Qt.size(14, 14)
                  smooth: true
                  fillMode: Image.PreserveAspectFit
                }
              }

              Text {
                id: label
                anchors.left: gutter.right
                anchors.leftMargin: Style.spacingSmall
                anchors.right: arrow.left
                anchors.rightMargin: Style.spacing
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.text
                color: row.modelData.enabled ? Colours.popup.text : Colours.bar.textMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                elide: Text.ElideRight
              }

              Text {
                id: arrow
                anchors.right: parent.right
                anchors.rightMargin: Style.padding
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? implicitWidth : 0
                visible: row.modelData.hasChildren
                text: "›"
                color: Colours.bar.textMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
              }

              MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: row.modelData.enabled
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                  if (row.modelData.hasChildren)
                    return;  // submenus open on hover; clicking does nothing
                  row.modelData.triggered();
                  root.closeTree();
                }

                onEntered: {
                  if (column.openSubmenuRow === row)
                    return;
                  column.openSubmenuRow = row.modelData.hasChildren ? row : null;
                }
              }
            }
          }
        }
      }
    }

    // Interactive scrollbar: a thin visible thumb inside a wider hit area, so
    // it is easy to grab without widening the bar itself. Dragging the thumb
    // scrolls 1:1 with the pointer; clicking the track jumps the menu there.
    // Only present when the content overflows. Wheel events fall through to
    // the scroller above, so scrolling also works while over the bar.
    Item {
      id: scrollbar

      visible: flick.contentHeight > flick.height + 1
      anchors.right: parent.right
      anchors.rightMargin: 2
      anchors.verticalCenter: parent.verticalCenter

      width: 14
      height: flick.height

      Rectangle {
        id: thumb

        width: 3
        height: Math.max(20, scrollbar.height * flick.visibleArea.heightRatio)
        x: (scrollbar.width - width) / 2
        y: flick.visibleArea.yPosition * (scrollbar.height - height)

        radius: 2
        color: Colours.bar.textMuted
        opacity: 0.5
      }

      MouseArea {
        id: bar

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        // True from press to release; pressing the thumb glues it to the
        // pointer, pressing the track jumps it (thumb centred on the click).
        property bool dragging: false
        property real dragOffset: 0

        function yToContent(y) {
          const track = scrollbar.height - thumb.height;
          const range = flick.contentHeight - flick.height;
          if (track <= 0 || range <= 0)
            return 0;
          return Math.max(0, Math.min(range, (y - bar.dragOffset) / track * range));
        }

        onPressed: mouse => {
          bar.dragging = true;
          if (mouse.y >= thumb.y && mouse.y <= thumb.y + thumb.height) {
            bar.dragOffset = mouse.y - thumb.y;
          } else {
            bar.dragOffset = thumb.height / 2;
            flick.contentY = bar.yToContent(mouse.y);
          }
        }

        onPositionChanged: mouse => {
          if (bar.dragging)
            flick.contentY = bar.yToContent(mouse.y);
        }

        onReleased: bar.dragging = false
      }
    }
  }

  // The one open submenu. Sits outside the clipped scrollport (see header)
  // and is retargeted via anchorRow as hover moves between rows rather than
  // reloaded per row.
  Loader {
    id: submenuLoader

    active: column.openSubmenuRow !== null
    source: "MenuLevel.qml"

    onLoaded: {
      item.parentLevel = root;
      item.windowWidth = root.windowWidth;
      item.windowHeight = root.windowHeight;
      item.anchorRow = Qt.binding(() => column.openSubmenuRow);
      item.menu = Qt.binding(() => column.openSubmenuRow ? column.openSubmenuRow.modelData : null);
    }
  }
}
