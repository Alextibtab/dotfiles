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
//   click        activate
//   middle click secondary activate
//
// Right-click menus are not wired up yet: that needs a QsMenuOpener plus a
// popup surface, which lands with the panel work in a later phase. Items whose
// only interaction is a menu (onlyMenu) would therefore do nothing on click, so
// they are marked visually rather than silently ignoring input.
Row {
  id: root

  property int iconSize: 18

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
          // Nothing useful to do until menus are implemented; say so rather
          // than appearing broken.
          console.log(`tray: ${item.modelData.id} is menu-only, menus land with the panel work`);
          return;
        }
        item.modelData.activate();
      }
      onMiddleClicked: item.modelData.secondaryActivate()

      // Icon, with a glyph fallback.
      //
      // This system has no working Qt icon theme: there is no
      // QT_QPA_PLATFORMTHEME, no qt6ct and no XDG_ICON_THEME, so Qt's loader
      // searches only `hicolor`. Quickshell.hasThemeIcon() returns false for
      // every standard name tried, including audio-volume-high and
      // input-keyboard-symbolic - the latter exists in both Adwaita and
      // breeze-dark, but neither theme is in Qt's search path. Icons shipped
      // directly into hicolor (nordvpn-tray-white) and embedded D-Bus pixmaps
      // (discord's image://qspixmap/...) resolve fine.
      //
      // So a themed-icon failure is expected here rather than exceptional, and
      // the tray must stay usable through it: a missing icon would otherwise
      // leave an invisible but clickable gap. Fixing it properly means
      // installing and configuring a Qt icon theme - worth doing, since
      // notification app icons will hit the same wall.
      Item {
        width: root.iconSize
        height: root.iconSize
        opacity: item.modelData.onlyMenu ? 0.65 : 1.0

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
