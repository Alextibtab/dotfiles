pragma Singleton

import Quickshell
import QtQuick
import qs.config

// Non-colour visual constants: spacing, radii, typography, animation.
// Kept separate from Colours so a theme swap never changes geometry, and a
// density change never changes colour.
Singleton {
  id: root

  // ---- typography ------------------------------------------------------
  readonly property string fontFamily: Config.theme.font || "monospace"
  readonly property int fontSize: Config.theme.fontSize || 13
  readonly property int fontSizeSmall: Math.max(9, fontSize - 2)

  // ---- spacing ---------------------------------------------------------
  readonly property int spacingSmall: 4
  readonly property int spacing: 8
  readonly property int spacingLarge: 14

  readonly property int paddingSmall: 4
  readonly property int padding: 8

  // Gap between the bar and a panel/menu opened from a bar button, so the
  // popup does not sit flush against the bar's inner edge.
  readonly property int popupGap: 12

  // ---- shape -----------------------------------------------------------
  readonly property int radiusSmall: 4
  readonly property int radius: 8

  // ---- animation -------------------------------------------------------
  // One duration for anything that tracks a state change the user initiated
  // (workspace switch, hover). Long enough to read, short enough not to lag.
  readonly property int animFast: 100
  readonly property int animNormal: 180
  readonly property var animEasing: Easing.OutCubic
}
