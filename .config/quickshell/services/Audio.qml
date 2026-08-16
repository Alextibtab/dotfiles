pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Default sink/source volume and mute state.
//
// Two non-obvious requirements of Quickshell's Pipewire service:
//
//  1. The singleton is lazy. It only connects once something holds a
//     declarative reference to it. Reading Pipewire.ready from inside a
//     function or a Timer callback is not enough - it reports false and the
//     node list stays empty. The `property` bindings below are what actually
//     bring the service up.
//
//  2. Node data (volume, mute, channels) is only populated for nodes that are
//     explicitly tracked. Without the PwObjectTracker below, `sink` resolves
//     but `sink.audio.volume` never updates.
//
// Both were found the hard way: an initial probe reported ready=false and a
// null sink for 5 seconds on a machine where pactl was working fine.
Singleton {
  id: root

  // Deliberately `var` rather than the PwNode type: the underlying C++ type is
  // PwNodeIface and binding it to a PwNode-typed property is a type error.
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property bool ready: Pipewire.ready

  PwObjectTracker {
    objects: {
      const out = [];
      if (root.sink)
        out.push(root.sink);
      if (root.source)
        out.push(root.source);
      return out;
    }
  }

  // ---- output ----------------------------------------------------------
  readonly property bool hasSink: !!(sink && sink.audio)
  readonly property real volume: hasSink ? sink.audio.volume : 0
  readonly property bool muted: hasSink ? sink.audio.muted : true
  readonly property string sinkName: sink ? (sink.description || sink.nickname || sink.name || "") : ""

  // ---- input -----------------------------------------------------------
  readonly property bool hasSource: !!(source && source.audio)
  readonly property real micVolume: hasSource ? source.audio.volume : 0
  readonly property bool micMuted: hasSource ? source.audio.muted : true

  // Pipewire allows volumes above 1.0 (software over-amplification). We clamp
  // writes at 1.0 so a scroll on the bar can never push output into clipping,
  // while `volume` still reports a higher value honestly if something else set
  // one.
  function setVolume(v) {
    if (!root.hasSink)
      return;
    root.sink.audio.volume = Math.max(0, Math.min(1, v));
  }

  function stepVolume(delta) {
    root.setVolume(root.volume + delta);
  }

  function toggleMute() {
    if (!root.hasSink)
      return;
    root.sink.audio.muted = !root.sink.audio.muted;
  }

  function toggleMicMute() {
    if (!root.hasSource)
      return;
    root.source.audio.muted = !root.source.audio.muted;
  }
}
