pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Network state, via the ~/.local/bin/net-status helper.
//
// Quickshell ships a Networking service, but it is NetworkManager-only and this
// machine runs systemd-networkd + iwd - it logs "Network will not work. Could
// not find an available backend." and reports zero devices. Quickshell also
// exposes no generic D-Bus API to QML, so the shell cannot query
// net.connman.iwd directly. The helper script does that with busctl and hands
// back one JSON line.
//
// Polling rather than event-driven for the same reason: without generic D-Bus
// there is nothing to subscribe to. The script costs ~28ms, so a 5s interval is
// negligible. If Quickshell ever grows an iwd backend, this whole file
// collapses into a few bindings on Networking.
Singleton {
  id: root

  property var data: ({})

  readonly property string kind: data.kind || "none"          // wifi | wired | none
  readonly property string state: data.state || "disconnected"
  readonly property bool connected: root.state === "connected"
  readonly property string ssid: data.ssid || ""
  readonly property int quality: data.quality || 0            // 0-70 from /proc/net/wireless
  readonly property int rssi: data.rssi || 0                  // dBm
  readonly property string iface: data.iface || ""
  readonly property string ip: data.ip || ""

  // /proc/net/wireless reports link quality on a 0-70 scale, not a percentage.
  readonly property int qualityPercent: Math.max(0, Math.min(100, Math.round(root.quality / 70 * 100)))

  // Label preferring the most useful identifier available.
  readonly property string label: {
    if (!root.connected)
      return "offline";
    if (root.kind === "wifi")
      return root.ssid || "wifi";
    if (root.kind === "wired")
      return "wired";
    return "offline";
  }

  Process {
    id: proc
    command: [Quickshell.env("HOME") + "/.local/bin/net-status"]

    stdout: StdioCollector {
      // streamFinished rather than dataChanged: the script emits one JSON
      // object and exits, and parsing a partially-read line would throw.
      onStreamFinished: {
        const t = String(text || "").trim();
        if (!t)
          return;
        try {
          root.data = JSON.parse(t);
        } catch (e) {
          console.warn("net: could not parse net-status output:", e);
        }
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    // Assigning running=true on an already-running Process is a no-op, so a
    // slow poll cannot stack up overlapping invocations.
    onTriggered: proc.running = true
  }

  function refresh() {
    proc.running = true;
  }
}
