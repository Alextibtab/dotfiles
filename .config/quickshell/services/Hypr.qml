pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config

// Hyprland facade, with the split-monitor-workspaces layout baked in.
//
// zjeffer/split-monitor-workspaces gives each monitor a contiguous block of
// real Hyprland workspaces. With workspace_count=5 and
// monitor_priority = { "HDMI-A-1", "DP-1" }:
//
//     HDMI-A-1  ->  base 0  ->  workspaces 1..5
//     DP-1      ->  base 5  ->  workspaces 6..10
//
// The plugin computes base as the sum of workspace counts for every monitor
// with a strictly lower priority value (helpers.calc_base_index). Monitors
// absent from monitor_priority are assigned max_priority + 1 as they are
// mapped (monitors.map_monitor), i.e. they queue up after the configured ones.
// We mirror both rules here.
//
// Assumption: every monitor uses the same workspace count. The plugin supports
// per-monitor max_workspaces overrides; this config does not use them, so base
// reduces to priority * perMonitor. If you ever set an override in
// plugins.lua, this needs the full summation.
Singleton {
  id: root

  readonly property int perMonitor: Config.workspaces.perMonitor || 5
  readonly property var priorityList: Config.workspaces.monitorPriority || []

  readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
  readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel

  // Monitors not named in monitorPriority, in Hyprland id order. Recomputed
  // whenever the monitor list changes so hotplug lands in a stable place.
  readonly property var unlistedMonitors: {
    const mons = Hyprland.monitors ? Hyprland.monitors.values : [];
    let out = [];
    for (const m of mons) {
      if (root.priorityList.indexOf(m.name) === -1)
        out.push(m);
    }
    out.sort((a, b) => a.id - b.id);
    return out.map(m => m.name);
  }

  // Priority value for a monitor: its index in the configured list, or
  // (list length + position among unlisted monitors) for anything not named.
  function priorityFor(monitorName) {
    const i = root.priorityList.indexOf(monitorName);
    if (i !== -1)
      return i;

    const j = root.unlistedMonitors.indexOf(monitorName);
    if (j !== -1)
      return root.priorityList.length + j;

    return 0;
  }

  // First Hyprland workspace id belonging to this monitor, minus one.
  // Monitor's workspaces are base+1 .. base+perMonitor.
  function baseFor(monitorName) {
    return root.priorityFor(monitorName) * root.perMonitor;
  }

  // Map a global Hyprland workspace id back to its 1-based index within its
  // monitor's block. Returns the raw id if it falls outside any block.
  function localIndexOf(workspaceId) {
    if (root.perMonitor <= 0)
      return workspaceId;
    const idx = ((workspaceId - 1) % root.perMonitor) + 1;
    return idx;
  }

  // Look up a live HyprlandWorkspace by id, or null if it does not exist yet.
  // Hyprland creates workspaces lazily, so an empty workspace may have no
  // object at all even though the bar should still show a slot for it.
  function workspaceById(id) {
    const list = Hyprland.workspaces ? Hyprland.workspaces.values : [];
    for (const ws of list) {
      if (ws.id === id)
        return ws;
    }
    return null;
  }

  function windowCount(ws) {
    if (!ws || !ws.toplevels)
      return 0;
    const v = ws.toplevels.values;
    return v ? v.length : 0;
  }

  // Focus a workspace by its global id.
  //
  // IMPORTANT: this Hyprland runs the *Lua* config provider
  // (hyprctl systeminfo -> configProvider: lua). Under it, a dispatch string
  // is not a dispatcher name plus arguments, it is Lua source evaluated as
  // `hl.dispatch(<your string>)`. The classic form:
  //
  //     Hyprland.dispatch("workspace 6")
  //
  // becomes `hl.dispatch(workspace 6)`, which is a Lua syntax error. Every
  // dispatch from this shell must use the Lua dispatcher API instead.
  //
  // We use the absolute workspace id rather than the plugin's
  // `split-workspace` dispatcher: this setup has BOTH the C++ hyprpm plugin
  // and the Lua package loaded, and an absolute focus is unambiguous under
  // either. It also behaves correctly when the click lands on a bar belonging
  // to a monitor that is not currently focused.
  function dispatch(luaExpr) {
    Hyprland.dispatch(luaExpr);
  }

  function focusWorkspace(globalId) {
    root.dispatch(`hl.dsp.focus({ workspace = "${globalId}" })`);
  }

  function focusLocal(monitorName, localIndex) {
    root.focusWorkspace(root.baseFor(monitorName) + localIndex);
  }
}
