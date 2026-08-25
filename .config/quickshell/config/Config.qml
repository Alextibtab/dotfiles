pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Loads the shipped defaults.json and, on top of it, the user's shell.json.
//
// Merge rules:
//   - plain objects are merged key by key (so shell.json only needs the keys
//     you actually want to change)
//   - arrays REPLACE wholesale, never merge element-wise. This is what makes
//     it possible to remove a widget from a bar section: if arrays merged,
//     a shorter user layout could never drop a default entry.
//
// Both files are watched, so editing either retheme/relayouts live.
Singleton {
  id: root

  readonly property string defaultsPath: Quickshell.shellPath("defaults.json")
  readonly property string userPath: Quickshell.shellPath("shell.json")

  // Last-resort config, used only if defaults.json is missing or unparseable.
  // Deliberately minimal: enough to render a bar you can see, so a broken
  // defaults.json shows up as a stripped-down bar rather than a blank screen.
  readonly property var builtin: ({
    version: 1,
    bar: {
      position: "top",
      height: 38,
      margin: 0,
      transparent: false,
      layout: {
        left: [{ id: "workspaces" }],
        center: [],
        right: [{ id: "clock", format: "HH:mm" }]
      }
    },
    workspaces: {
      perMonitor: 5,
      monitorPriority: [],
      showEmpty: true,
      localNumbering: true
    },
    theme: { name: "dynamic", font: "monospace", fontSize: 13 },
    japaneseReviews: { refreshIntervalSec: 300 }
  })

  property var values: builtin

  // Cache each public subtree. Rebuild creates fresh objects, but downstream
  // bindings should only react when that subtree's contents actually change.
  property var _bar: builtin.bar
  property var _workspaces: builtin.workspaces
  property var _theme: builtin.theme
  property var _japaneseReviews: builtin.japaneseReviews
  property var _layoutLeft: []
  property var _layoutCenter: []
  property var _layoutRight: []

  property string _barKey: ""
  property string _workspacesKey: ""
  property string _themeKey: ""
  property string _japaneseReviewsKey: ""
  property string _layoutLeftKey: ""
  property string _layoutCenterKey: ""
  property string _layoutRightKey: ""

  readonly property var bar: root._bar
  readonly property var workspaces: root._workspaces
  readonly property var theme: root._theme
  readonly property var japaneseReviews: root._japaneseReviews
  readonly property var layoutLeft: root._layoutLeft
  readonly property var layoutCenter: root._layoutCenter
  readonly property var layoutRight: root._layoutRight

  function isObject(v) {
    return v !== null && typeof v === "object" && !Array.isArray(v);
  }

  function merge(base, over) {
    if (!isObject(base))
      return over;
    if (!isObject(over))
      return base;

    let out = {};
    for (let k in base)
      out[k] = base[k];
    for (let k in over) {
      if (isObject(out[k]) && isObject(over[k]))
        out[k] = merge(out[k], over[k]);
      else
        out[k] = over[k];   // arrays and scalars replace
    }
    return out;
  }

  function parse(text, label) {
    const t = String(text || "").trim();
    if (!t)
      return null;
    try {
      const parsed = JSON.parse(t);
      if (!isObject(parsed)) {
        console.warn(`config: ${label} is not a JSON object, ignoring`);
        return null;
      }
      if (parsed.version !== 1) {
        console.warn(`config: ${label} missing "version": 1, ignoring`);
        return null;
      }
      return parsed;
    } catch (e) {
      console.warn(`config: ${label} parse failed, ignoring: ${e}`);
      return null;
    }
  }

  function rebuild() {
    const d = parse(defaultsFile.text(), "defaults.json") || builtin;
    const u = parse(userFile.text(), "shell.json");
    const next = u ? merge(d, u) : d;
    root.values = next;

    const nextBar = next.bar || builtin.bar;
    const nextLayout = nextBar.layout || {};

    root.adopt("bar", nextBar);
    root.adopt("workspaces", next.workspaces || builtin.workspaces);
    root.adopt("theme", next.theme || builtin.theme);
    root.adopt("japaneseReviews", next.japaneseReviews || builtin.japaneseReviews);
    root.adopt("layoutLeft", nextLayout.left || []);
    root.adopt("layoutCenter", nextLayout.center || []);
    root.adopt("layoutRight", nextLayout.right || []);
  }

  function adopt(name, next) {
    const keyProp = "_" + name + "Key";
    const key = JSON.stringify(next === undefined ? null : next);
    if (root[keyProp] === key)
      return;
    root[keyProp] = key;
    root["_" + name] = next;
  }

  // blockLoading makes the initial read synchronous. Without it the shell
  // paints one frame using `builtin` before the file lands, which shows up as
  // a visible flash of the wrong font and colours at every startup and reload.
  // These are two small local files; blocking on them is cheap.
  // The FileViews below are declared after these properties, so their
  // onLoaded has already fired (and been missed) by the time the singleton is
  // fully constructed. Read once more here, synchronously, so the first
  // consumer sees real values rather than `builtin`.
  Component.onCompleted: root.rebuild()

  FileView {
    id: defaultsFile
    path: root.defaultsPath
    blockLoading: true
    watchChanges: true
    printErrors: false
    onLoaded: root.rebuild()
    onFileChanged: reload()
    onLoadFailed: {
      console.warn("config: could not read defaults.json, using builtin");
      root.rebuild();
    }
  }

  // shell.json is optional; a missing file is the normal fresh state, not an
  // error, so onLoadFailed still rebuilds rather than complaining.
  FileView {
    id: userFile
    path: root.userPath
    blockLoading: true
    watchChanges: true
    printErrors: false
    onLoaded: root.rebuild()
    onFileChanged: reload()
    onLoadFailed: root.rebuild()
  }
}
