pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Japanese study review counts (WaniKani, Bunpro, Anki) from
// services/japanese_reviews.py, which emits one JSON object.
//
// A singleton rather than a per-bar Process so that only ONE scanner runs at
// a time, mirroring SystemUpdates/OpencodeStats: every monitor's bar has its
// own widget, and only one copy of the data is needed.
Singleton {
  id: root

  readonly property string scannerPath: Quickshell.env("HOME") + "/.config/quickshell/services/japanese_reviews.py"

  property var services: []
  property int total: 0
  property bool refreshing: false

  property int refreshIntervalSec: 300

  Timer {
    id: timer
    interval: Math.max(60, root.refreshIntervalSec) * 1000
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
      id: stderrCollector
      waitForEnd: true
      onStreamFinished: {
        const t = String(stderrCollector.text || "").trim();
        if (t !== "")
          console.warn("japanese-reviews:", t);
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
      root.services = (data && Array.isArray(data.services)) ? data.services : [];
      root.total = (data && typeof data.total === "number") ? data.total : 0;
    } catch (e) {
      console.warn("japanese-reviews: failed to parse scanner output:", e);
    }
  }
}
