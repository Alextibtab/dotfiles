pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.config

// Display state and controls for the display panel.
//
// Monitor state comes from Quickshell's event-backed Hyprland monitor model.
//
// Text size is the shell config itself: Config watches shell.json, so the
// display-text-size helper writing theme.fontSize reflows the whole shell
// live, and this singleton just mirrors it for the slider.
Singleton {
  id: root

  readonly property var displays: Hyprland.monitors ? Hyprland.monitors.values : []
  readonly property string focusedMonitor: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""

  // Look up one display entry by output name; null if absent (e.g. before the
  // first poll lands, or during hotplug).
  function displayFor(name) {
    for (const d of root.displays) {
      if (d.name === name)
        return d;
    }
    return null;
  }

  // Current scale of the named monitor, defaulting to 1 when unknown.
  function scaleFor(name) {
    const d = root.displayFor(name);
    return d ? (parseFloat(d.scale) || 1) : 1;
  }

  // Curated stops for the text-size slider, like Omarchy's. The shell accepts
  // any integer 9-20 (set via the CLI); the slider snaps to these.
  readonly property var textSizeStops: [9, 10, 11, 12, 13, 14, 16, 20]
  readonly property int textSize: Config.theme.fontSize || 13

  readonly property string home: Quickshell.env("HOME")
  readonly property string binDir: root.home + "/.local/bin"

  Process {
    id: setProc
    command: []
    stdout: StdioCollector { waitForEnd: true }
    // Re-poll right after a change lands so the panel reflects it immediately
    // instead of waiting out the poll interval. The scale change goes through
    // `hyprctl reload`, so the fresh query catches the settled state.
    onRunningChanged: if (!running && setProc.command.length > 0) root.refresh()
  }

  function refresh() {
    Hyprland.refreshMonitors()
  }

  function setTextSize(px) {
    setProc.command = [root.binDir + "/display-text-size", String(px)];
    setProc.running = true;
  }

  function setScale(value, monitorName) {
    const args = [root.binDir + "/display-scale", String(value)];
    if (monitorName)
      args.push(monitorName);
    setProc.command = args;
    setProc.running = true;
  }

  // The scale a monitor actually accepts is the requested value rounded up to
  // one that divides the monitor's mode into whole logical pixels. Mirrors the
  // display-scale helper so the pills can show what will really apply.
  function cleanScale(scale, monitorName) {
    const d = root.displayFor(monitorName);
    const s = parseFloat(scale) || 1;
    if (!d || !d.width || !d.height)
      return s;
    const w = d.width, h = d.height;
    function gcd(a, b) {
      while (b) {
        const t = a % b;
        a = b;
        b = t;
      }
      return a;
    }
    const g = gcd(Math.round(w * 120), Math.round(h * 120));
    let k = Math.max(1, Math.round(s * 120));
    if (k > g)
      k = g;
    while (g % k !== 0)
      k++;
    return k / 120;
  }

  // Cleaned value formatted for a pill label, e.g. "1x", "1.25x", "1.6x".
  function scaleLabel(value, monitorName) {
    const c = root.cleanScale(value, monitorName);
    return `${Math.round(c * 100) / 100}x`;
  }
}
