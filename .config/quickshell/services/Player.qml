pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The "current" MPRIS player.
//
// Several players can be on the bus at once (here: firefox plus playerctld).
// The bar needs exactly one, and it should be the one the user last had making
// sound - not whichever happens to be first in the list.
//
// Selection: the first player that is currently playing, else the first player
// present.
//
// An earlier version also remembered the last chosen player by uniqueId, so
// that pausing could not make the widget jump to a different player. That
// created a binding loop - `active` read `rememberedId` while
// onActiveChanged wrote it - and QML reported:
//
//   Binding loop detected for property "active"
//
// The remembered-player refinement is only meaningful with two or more
// simultaneous players, which is not the case here (firefox is the only one on
// the bus; playerctld is merely activatable). Simple and correct beats clever
// and cyclic; if multiple players become common, the fix is to drive selection
// from a function on explicit change signals rather than from a binding.
//
// Like Pipewire, Mpris is a lazy singleton - it needs a declarative reference
// to start enumerating, not just an access inside a callback.
Singleton {
  id: root

  readonly property var players: Mpris.players
  readonly property var list: players ? players.values : []

  readonly property var active: {
    const l = root.list;
    if (!l || l.length === 0)
      return null;
    for (const p of l) {
      if (p.isPlaying)
        return p;
    }
    return l[0];
  }

  readonly property bool hasPlayer: !!active
  readonly property bool isPlaying: active ? active.isPlaying : false
  readonly property string title: active ? (active.trackTitle || "") : ""
  readonly property string artist: active ? (active.trackArtist || "") : ""
  readonly property string identity: active ? (active.identity || "") : ""

  readonly property bool canGoNext: !!(active && active.canGoNext)
  readonly property bool canGoPrevious: !!(active && active.canGoPrevious)
  readonly property bool canToggle: !!(active && active.canTogglePlaying)

  // "Artist - Title", degrading to whichever half exists.
  readonly property string label: {
    if (!root.hasPlayer)
      return "";
    if (root.artist && root.title)
      return `${root.artist} - ${root.title}`;
    return root.title || root.artist || root.identity;
  }

  function toggle() {
    if (root.canToggle)
      root.active.togglePlaying();
  }

  function next() {
    if (root.canGoNext)
      root.active.next();
  }

  function previous() {
    if (root.canGoPrevious)
      root.active.previous();
  }
}
