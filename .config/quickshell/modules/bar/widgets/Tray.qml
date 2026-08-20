import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.theme
import qs.components

// StatusNotifierItem tray.
//
// Items provide their icon as a Quickshell image URL, either a themed name
// (image://icon/nordvpn-tray-white) or an embedded pixmap
// (image://qspixmap/2/1) for apps that ship their icon over D-Bus rather than
// by name - discord does this. Image handles both directly, so there is no icon
// lookup to do here.
//
// Themed names only resolve because the shell runs with
// QT_QPA_PLATFORMTHEME=qt6ct (set in hyprland/env.lua), which puts the icon
// theme chosen in qt6ct (breeze-dark) on Qt's search path. Without it Qt
// searches only hicolor and Quickshell's provider renders its pink/black
// "missing icon" square - which counts as Ready, so it wins over the glyph
// fallback below. The glyph remains for artwork that is genuinely absent.
//
//   left click    activate; opens the menu instead for onlyMenu items
//   middle click  secondary activate
//   right click   open the item's menu (components/MenuPopup)
//
// Menus close on a click ANYWHERE: MenuPopup is a full-screen input-grabbing
// window, so no click reaches the tray while one is open.
//
// Collapsible: with `collapsible` set, the items are hidden behind a chevron
// at the section's end. Clicking pins the tray open; hovering expands it only
// while hovered. The chevron is the LAST row child on purpose: the section is
// right-anchored, so the last child is the only one that does not move when
// the row grows - the hover target stays under the pointer.
Row {
  id: root

  property int iconSize: 18

  // The output this bar instance is on; the menu popup needs it to cover the
  // correct screen on multi-monitor setups.
  property var screen: null

  // When false, every item is always shown and no chevron is rendered.
  property bool collapsible: true

  // Sticky expand, toggled by clicking the chevron.
  property bool pinned: false

  // Set when the chevron is clicked to close the tray: the pointer is still
  // hovering us at that moment, and plain hover would instantly re-expand.
  // Suppressed until the pointer has fully left and come back.
  property bool suppressHover: false

  // Hovering any part of the tray (chevron or revealed icons) expands it.
  // Collapse is delayed a beat so the pointer can wander off for a moment
  // without the row snapping shut under it.
  readonly property bool hoverLive: trayHover.hovered || collapseTimer.running
  readonly property bool hovered: hoverLive && !suppressHover
  onHoverLiveChanged: {
    if (!hoverLive)
      suppressHover = false;
  }

  // An open menu keeps the icons shown: they are its anchor, and the pointer
  // is expected to leave the tray while browsing the menu.
  readonly property bool expanded: !collapsible || pinned || hovered || menuPopup.visible

  // Zero so the collapsed tray leaves no phantom gap between the (zero-width)
  // item container and the chevron. Inter-item spacing lives on iconsRow.
  spacing: 0

  HoverHandler {
    id: trayHover
  }

  Timer {
    id: collapseTimer
    interval: 350
  }

  // Clipped so the width animation reads as the icons sliding in from behind
  // the chevron. Delegates stay alive while collapsed - tray items must keep
  // their D-Bus registration regardless of visibility.
  Item {
    id: trayItems

    clip: true
    implicitWidth: iconsRow.implicitWidth
    implicitHeight: iconsRow.implicitHeight
    width: root.expanded ? implicitWidth : 0

    Behavior on width {
      NumberAnimation {
        duration: Style.animNormal
        easing.type: Style.animEasing
      }
    }

    Row {
      id: iconsRow
      spacing: Style.spacingSmall

      Repeater {
        model: SystemTray.items

        delegate: BarButton {
          id: item

          required property var modelData

          horizontalPadding: Style.paddingSmall

          // Passive items are, by SNI convention, ones the app considers not worth
          // showing. Hiding them keeps the tray to what is actually relevant.
          visible: item.modelData.status !== Status.Passive

          onClicked: {
            if (item.modelData.onlyMenu) {
              // Activation is a no-op on these by definition; the menu is the
              // interaction, so open it on any click.
              if (item.modelData.hasMenu)
                menuPopup.openFor(item, item.modelData.menu);
              return;
            }
            item.modelData.activate();
          }
          onRightClicked: {
            if (item.modelData.hasMenu)
              menuPopup.openFor(item, item.modelData.menu);
          }
          onMiddleClicked: item.modelData.secondaryActivate()

          // Icon, with a glyph fallback: a missing icon would otherwise leave an
          // invisible but clickable gap. See the header comment for why themed
          // icons resolve at all.
          Item {
            width: root.iconSize
            height: root.iconSize

            Image {
              id: icon
              anchors.fill: parent
              source: item.modelData.icon

              // Request a concrete size. Without sourceSize, Image asks the
              // provider for its default 100x100, which fails for themed icons
              // that only ship 16/22/24/32 variants even when the theme is found.
              sourceSize: Qt.size(32, 32)

              // Tray icons often arrive at a mismatched size; smoothing avoids the
              // aliasing from scaling a 22px pixmap down to 18px.
              smooth: true
              mipmap: true
              fillMode: Image.PreserveAspectFit
              visible: status === Image.Ready
            }

            Text {
              anchors.centerIn: parent
              visible: icon.status !== Image.Ready
              // Generic "application" glyph rather than a broken-image marker: the
              // item works, only its artwork is missing.
              text: "\udb80\udd0b"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeSmall
              color: Colours.bar.textMuted
            }
          }
        }
      }
    }
  }

  // One popup shared by every item; openFor() retargets it, so clicking a
  // second icon moves the menu rather than stacking copies.
  MenuPopup {
    id: menuPopup
    output: root.screen
  }

  BarButton {
    id: toggle

    visible: root.collapsible
    horizontalPadding: Style.paddingSmall

    onClicked: {
      if (root.pinned) {
        // Close NOW, even though the pointer is still hovering us.
        root.pinned = false;
        root.suppressHover = true;
      } else {
        root.pinned = true;
      }
    }

    Text {
      // md-chevron-right when expanded (clicking slides the icons back into
      // it), md-chevron-left when collapsed (they slide out to the left).
      text: root.expanded ? "󰅂" : "󰅁"
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      color: Colours.bar.textMuted
    }
  }
}
