pragma Singleton

import Quickshell
import QtQuick

// Wraps Quickshell's SystemClock, which is tick-aligned to the wall clock
// rather than to process start. A naive Timer{interval:1000} drifts and can
// sit up to a second behind the real minute boundary; SystemClock fires on
// the boundary itself.
//
// Precision is minutes: nothing on the bar shows seconds, and waking the
// shell 60x more often to redraw an unchanged string is wasteful.
Singleton {
  id: root

  readonly property date now: clock.date

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  function format(fmt) {
    return Qt.formatDateTime(root.now, fmt || "HH:mm");
  }
}
