pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// OpenCode token/session usage, via services/opencode_usage_scanner.py which
// queries ~/.local/share/opencode/opencode.db (SQLite) and emits one JSON
// object. The scanner costs ~40ms, so polling every few minutes is free.
Singleton {
  id: root

  readonly property string scannerPath: Quickshell.env("HOME") + "/.config/quickshell/services/opencode_usage_scanner.py"
  readonly property string dbPath: Quickshell.env("HOME") + "/.local/share/opencode/opencode.db"

  property bool ready: false
  property bool refreshing: false
  property bool hasLocalStats: false

  property int todaySessions: 0
  property int todayTotalTokens: 0
  property var todayTokensByModel: ({})

  property var recentDays: []
  property int totalSessions: 0
  property var modelUsage: ({})

  property int refreshIntervalSec: 300

  Timer {
    id: timer
    interval: Math.max(30, root.refreshIntervalSec) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  onRefreshIntervalSecChanged: timer.restart()

  Process {
    id: proc
    command: ["python3", root.scannerPath, root.dbPath]

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
          console.warn("opencode-usage:", t);
      }
    }

    onRunningChanged: if (!running) root.refreshing = false
  }

  function refresh() {
    root.refreshing = true;
    proc.running = true;
  }

  function apply(content) {
    try {
      const data = JSON.parse(String(content || "{}").trim());
      if (!data || data.ready !== true)
        return;
      root.ready = true;
      root.hasLocalStats = data.hasLocalStats !== false;
      root.todaySessions = Math.max(0, Number(data.todaySessions || 0));
      root.todayTotalTokens = Math.max(0, Number(data.todayTotalTokens || 0));
      root.todayTokensByModel = data.todayTokensByModel || ({});
      root.recentDays = data.recentDays || [];
      root.totalSessions = Math.max(0, Number(data.totalSessions || 0));
      root.modelUsage = data.modelUsage || ({});
    } catch (e) {
      console.warn("opencode-usage: failed to parse scanner output:", e);
    }
  }

  function formatTokenCount(n) {
    const v = Number(n || 0);
    if (v >= 1e9)
      return (v / 1e9).toFixed(1) + "B";
    if (v >= 1e6)
      return (v / 1e6).toFixed(1) + "M";
    if (v >= 1e3)
      return (v / 1e3).toFixed(1) + "K";
    return String(v);
  }

  function friendlyModelName(id) {
    const raw = String(id || "");
    if (raw === "")
      return "Unknown";
    if (raw.charAt(0) === "{") {
      try {
        const parsed = JSON.parse(raw);
        const modelId = String(parsed.id || "");
        const provider = String(parsed.providerID || "");
        if (modelId !== "" && provider !== "")
          return modelId + " (" + provider + ")";
        if (modelId !== "")
          return modelId;
      } catch (e) {}
    }
    return raw;
  }
}
