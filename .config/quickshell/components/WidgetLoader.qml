import QtQuick
import qs.theme

// Resolves one bar layout entry into a live widget.
//
// A layout entry looks like { "id": "clock", "format": "HH:mm" }. The `id`
// selects a Component from the registry; every other key is applied to the
// created object as a property. That is what lets shell.json configure a
// widget inline without the widget needing to know about the config system.
Loader {
  id: root

  required property var modelData
  required property var registry

  readonly property string widgetId: modelData && modelData.id ? String(modelData.id) : ""

  anchors.verticalCenter: parent ? parent.verticalCenter : undefined

  sourceComponent: {
    if (!root.widgetId)
      return null;
    const c = root.registry[root.widgetId];
    if (!c) {
      // Loud, because a typo in shell.json otherwise just silently produces
      // a missing widget and no explanation.
      console.warn(`bar: unknown widget id "${root.widgetId}"`);
      return null;
    }
    return c;
  }

  onLoaded: {
    const entry = root.modelData;
    if (!item || !entry)
      return;

    for (const key in entry) {
      if (key === "id")
        continue;
      // Only assign properties the widget actually declares. Writing an
      // unknown property onto a QML object silently does nothing, so check
      // first and say something useful instead.
      if (key in item)
        item[key] = entry[key];
      else
        console.warn(`bar: widget "${root.widgetId}" has no property "${key}"`);
    }
  }
}
