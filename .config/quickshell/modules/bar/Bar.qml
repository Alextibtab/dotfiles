import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.theme
import qs.services
import qs.components
import "widgets"

// The bar, one instance per connected monitor.
//
// Layout is data-driven from Config.bar.layout: each section is an array of
// { "id": ..., ...settings } entries, resolved against the widget registry
// below. Adding a widget in phase 4 means adding one Component here and one
// entry in defaults.json, with no change to this file's structure.
Scope {
  id: root

  Variants {
    model: Quickshell.screens

    delegate: BarPanel {
      id: panel

      required property var modelData

      screen: modelData

      // ShellScreen.name matches the Wayland output name, which is what
      // Hyprland calls the monitor. monitorFor is the authoritative mapping
      // though, so prefer it and only fall back if it has not resolved yet
      // (it is briefly null during hotplug).
      readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
      readonly property string monitorName: hyprMonitor ? hyprMonitor.name : modelData.name

      // Hyprland <= 0.56 does not move existing layer surfaces when an output
      // changes position at runtime (a scale change re-flows auto-positioned
      // monitors). Only a fresh configure re-commits them, so a bar whose
      // screen moved keeps rendering at its old spot. Unmap/remap the window
      // when the screen geometry changes to force that re-commit.
      Connections {
        target: panel.screen
        function onGeometryChanged() {
          if (!panel.screen)
            return;
          panel.visible = false;
          Qt.callLater(() => {
            panel.visible = true;
          });
        }
      }

      // ---- widget registry ---------------------------------------------
      // id -> Component. Each component may declare `monitorName`; the
      // loader below feeds it in along with any per-entry settings.
      readonly property var registry: ({
        "workspaces": workspacesComponent,
        "clock": clockComponent,
        "activeWindow": activeWindowComponent,
        "volume": volumeComponent,
        "network": networkComponent,
        "media": mediaComponent,
        "display": displayComponent,
        "tray": trayComponent,
        "weather": weatherComponent,
        "quake": quakeComponent,
        "session": sessionComponent,
        "gitSwitcher": gitSwitcherComponent,
        "opencodeUsage": opencodeUsageComponent,
        "systemUpdates": systemUpdatesComponent,
        "japaneseReviews": japaneseReviewsComponent
      })

      Component {
        id: workspacesComponent
        Workspaces {
          monitorName: panel.monitorName
        }
      }

      Component {
        id: clockComponent
        Clock {
          screen: panel.screen
          monitorName: panel.monitorName
        }
      }

      Component {
        id: activeWindowComponent
        ActiveWindow {
          monitorName: panel.monitorName
        }
      }

      Component {
        id: volumeComponent
        Volume {
          screen: panel.screen
          monitorName: panel.monitorName
        }
      }

      Component {
        id: networkComponent
        Network {}
      }

      Component {
        id: mediaComponent
        Media {}
      }

      Component {
        id: displayComponent
        Display {
          screen: panel.screen
          monitorName: panel.monitorName
        }
      }

      Component {
        id: trayComponent
        Tray {
          screen: panel.screen
        }
      }

      Component {
        id: weatherComponent
        WeatherWidget {
          screen: panel.screen
          monitorName: panel.monitorName
        }
      }

      Component {
        id: quakeComponent
        QuakeWidget {
          screen: panel.screen
          monitorName: panel.monitorName
        }
      }

      Component {
        id: sessionComponent
        SessionButtons {}
      }

      Component {
        id: gitSwitcherComponent
        GitSwitcher {
          screen: panel.screen
          monitorName: panel.monitorName
        }
      }

      Component {
        id: opencodeUsageComponent
        OpencodeUsage {
          screen: panel.screen
          monitorName: panel.monitorName
        }
      }

      Component {
        id: systemUpdatesComponent
        SystemUpdates {
          screen: panel.screen
          monitorName: panel.monitorName
        }
      }

      Component {
        id: japaneseReviewsComponent
        JapaneseReviews {
          screen: panel.screen
          monitorName: panel.monitorName
        }
      }

      // ---- sections ------------------------------------------------------
      Row {
        id: leftSection
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing

        Repeater {
          model: (Config.bar.layout && Config.bar.layout.left) || []
          delegate: WidgetLoader {
            registry: panel.registry
          }
        }
      }

      Row {
        id: rightSection
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing

        Repeater {
          model: (Config.bar.layout && Config.bar.layout.right) || []
          delegate: WidgetLoader {
            registry: panel.registry
          }
        }
      }

      // Centre is positioned against the monitor, not against the gap between
      // the side sections, so the clock does not drift as the left section
      // grows. It is clamped to the space actually free between the two
      // sections so a long window title cannot overlap them.
      Row {
        id: centerSection
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing

        readonly property real freeSpace: {
          const half = panel.width / 2;
          const leftEdge = leftSection.width + Style.spacingLarge;
          const rightEdge = rightSection.width + Style.spacingLarge;
          return Math.max(0, (half - Math.max(leftEdge, rightEdge)) * 2);
        }

        clip: true
        width: Math.min(implicitWidth, freeSpace)

        Repeater {
          model: (Config.bar.layout && Config.bar.layout.center) || []
          delegate: WidgetLoader {
            registry: panel.registry
          }
        }
      }
    }
  }
}
