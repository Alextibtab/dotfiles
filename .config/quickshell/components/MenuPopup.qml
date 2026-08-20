import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

// Host window for DBus menus (tray right-click menus): a full-screen,
// transparent, input-grabbing surface. components/MenuLevel.qml renders the
// actual menu inside it.
//
// The window doubles as the dismissal layer: it covers the whole output above
// every other surface, so a click anywhere - desktop, bar, another window -
// lands on the catcher MouseArea and closes the menu. The click is swallowed,
// the standard "first click dismisses" menu behavior. Deliberately not
// PopupWindow + a separate catcher: the bar is a layer surface that never
// takes keyboard focus, so focus-grab dismissal cannot see clicks on the bar,
// and stacking a catcher below a popup relies on same-layer mapping order.
// One window has no ordering questions.
PanelWindow {
  id: root

  // The menu the root level shows: a SystemTrayItem.menu handle.
  property var menu: null

  // The tray button the menu opened from.
  property Item anchorItem: null

  // The output this menu lives on; set by the tray. Required for multi-monitor:
  // without it the window would cover the default screen only.
  property var output: null

  // The anchor button's position within its bar window. The bar spans its
  // output's full width, so bar-window coordinates ARE output coordinates,
  // which is what makes them usable for placement here.
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

  // Distinct layer namespace so hyprland can switch off its layer animation
  // for this window (a full-screen surface with a popin animation reads as
  // the menu flying in from the centre of the screen). The matching
  // no_anim layer_rule lives in hyprland/general.lua.
  WlrLayershell.namespace: "quickshell-menu"

  color: "transparent"
  visible: false

  function openFor(item, handle) {
    root.anchorItem = item;
    root.menu = handle;
    const pos = item.mapToItem(null, 0, 0);
    root.anchorX = pos.x;
    root.anchorW = item.width;
    root.visible = true;
  }

  function closeTree() {
    root.visible = false;
  }

  // Fold any open submenus so a reopened menu starts collapsed. MenuLevels
  // persist while closed (their model does not change), so this is not
  // automatic.
  onVisibleChanged: {
    if (!visible)
      rootLevel.collapseSubmenus();
  }

  // Keyboard: the grab routes input to this window while open, which is what
  // makes Escape work. Click dismissal is the catcher's job, not the grab's.
  HyprlandFocusGrab {
    active: root.visible
    windows: [root]
    onCleared: root.closeTree()
  }

  // Dismissal for clicks landing on another output (this window covers only
  // its own): focusing a window elsewhere closes the menu. The grab stealing
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
    id: menuRoot

    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.closeTree()

    // The catcher, declared first so every menu level stacks above it. Any
    // click that is not on a menu row lands here and closes the menu.
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: root.closeTree()
    }

    MenuLevel {
      id: rootLevel

      menu: root.menu
      windowWidth: menuRoot.width
      windowHeight: menuRoot.height

      onRequestClose: root.closeTree()

      // Right edge aligns with the tray button's right edge, clamped
      // on-screen; hangs off the bar's inner edge (above it for a bottom
      // bar). Bindings re-clamp as the async D-Bus content changes the size.
      x: Math.max(4, Math.min(root.anchorX + root.anchorW - implicitWidth, menuRoot.width - implicitWidth - 4))
      y: root.barAtBottom
          ? Math.max(4, menuRoot.height - root.barHeight - implicitHeight)
          : root.barHeight
    }
  }
}
