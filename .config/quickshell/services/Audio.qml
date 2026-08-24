pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Default sink/source volume and mute state, plus the full device/stream
// node lists for the volume panel.
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
//     explicitly tracked. Without the PwObjectTrackers below, `sink` resolves
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

  // ---- device / stream lists -------------------------------------------
  // ObjectModel.values is a reactive list property, so rebuilding these arrays
  // every time the node set changes is automatic. PwNodeType is a bitmask:
  // AudioSink = Audio|Sink, AudioDuplex = Audio|Sink|Source (a headset shows
  // in both device lists, like pavucontrol), AudioOutStream = Audio|Sink|Stream.
  readonly property var allNodes: Pipewire.nodes.values

  readonly property var sinks: root.allNodes.filter(n =>
    n && n.ready && n.audio && (n.type & PwNodeType.Sink) && !(n.type & PwNodeType.Stream))
  readonly property var sources: root.allNodes.filter(n =>
    n && n.ready && n.audio && (n.type & PwNodeType.Source) && !(n.type & PwNodeType.Stream))
  readonly property var outStreams: root.allNodes.filter(n =>
    n && n.ready && n.audio && (n.type & PwNodeType.Sink) && (n.type & PwNodeType.Stream))
  readonly property var inStreams: root.allNodes.filter(n =>
    n && n.ready && n.audio && (n.type & PwNodeType.Source) && (n.type & PwNodeType.Stream))

  // Any capture stream open = something is listening to the mic. The bar
  // glyph lights up on this so a leak is visible at a glance.
  readonly property bool isRecording: root.inStreams.length > 0

  // Track every audio node, not just the defaults, so their volume/mute data
  // populates (see header comment).
  PwObjectTracker {
    objects: root.allNodes.filter(n =>
      n && ((n.type & PwNodeType.Sink) || (n.type & PwNodeType.Source)))
  }

  function nodeLabel(node) {
    if (!node)
      return "";
    const props = node.properties || {};
    const appName = props["application.name"] || "";
    const mediaName = String(props["media.name"] || "").trim();
    const desc = node.description || "";
    const nodeName = node.name || "";

    // Streams: sites with a media session make the browser expose the
    // tab/page title in media.name (Firefox reliably, Chromium for
    // MediaSession pages). Otherwise the prop is a generic "Playback" and we
    // fall back to the app name - pipewire does not expose a per-tab title.
    if (node.isStream) {
      const generic = ["", "playback", "audio", "media", "stream", "default", "output", "input"];
      const l = mediaName.toLowerCase();
      if (mediaName && generic.indexOf(l) === -1 && mediaName !== appName && mediaName !== nodeName)
        return mediaName;
      return appName || desc || nodeName;
    }

    // Devices: description is the friendliest name.
    return desc || nodeName || appName;
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
  function setNodeVolume(node, v) {
    if (!node || !node.audio)
      return;
    node.audio.volume = Math.max(0, Math.min(1, v));
  }

  function setVolume(v) {
    root.setNodeVolume(root.sink, v);
  }

  function stepVolume(delta) {
    root.setVolume(root.volume + delta);
  }

  function toggleNodeMute(node) {
    if (!node || !node.audio)
      return;
    node.audio.muted = !node.audio.muted;
  }

  function toggleMute() {
    root.toggleNodeMute(root.sink);
  }

  function toggleMicMute() {
    root.toggleNodeMute(root.source);
  }

  // preferred* is a request Pipewire may reject (e.g. the node is gone);
  // the panel highlights the ACTUAL default (root.sink/root.source), which
  // reflects whether the request landed.
  function setDefaultSink(node) {
    if (node && (node.type & PwNodeType.AudioSink))
      Pipewire.preferredDefaultAudioSink = node;
  }

  function setDefaultSource(node) {
    if (node && (node.type & PwNodeType.AudioSource))
      Pipewire.preferredDefaultAudioSource = node;
  }
}