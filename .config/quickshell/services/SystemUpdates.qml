pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Arch + AUR update counts, from services/check_updates.py.
//
// A singleton rather than a per-bar Process so that only ONE scanner runs at
// a time: every monitor's bar has its own SystemUpdates widget, and running
// checkupdates concurrently from two of them collides (one wins the pacman
// db lock and the other reports 0 pacman updates). A single shared scan
// fixes that and avoids needless duplicate work.
Singleton {
  id: root

  readonly property string scannerPath: Quickshell.env("HOME") + "/.config/quickshell/services/check_updates.py"

  property var repos: []
  property int total: 0
  property bool refreshing: false

  property int refreshIntervalSec: 1800

  Timer {
    id: timer
    interval: Math.max(300, root.refreshIntervalSec) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  onRefreshIntervalSecChanged: timer.restart()

  Process {
    id: proc
    command: ["python3", root.scannerPath]

    stdout: StdioCollector {
      id: collector
      waitForEnd: true
      onStreamFinished: root.apply(String(text || ""))
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: function(text) {
        const t = String(text || "").trim();
        if (t !== "")
          console.warn("system-updates:", t);
      }
    }

    onRunningChanged: if (!running) root.refreshing = false
  }

  function refresh() {
    root.refreshing = true
    proc.running = true
  }

  function apply(content) {
    try {
      const data = JSON.parse(String(content || "{}").trim());
      root.repos = (data && Array.isArray(data.repos)) ? data.repos : [];
      root.total = (data && typeof data.total === "number") ? data.total : 0;
    } catch (e) {
      console.warn("system-updates: failed to parse scanner output:", e);
    }
  }
}
