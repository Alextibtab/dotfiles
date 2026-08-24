import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.theme

// OpenCode usage pill: opencode glyph plus today's token count. Clicking
// toggles the stats popup (today / last 7 days / all-time); right or middle
// click forces an immediate refresh.
//
// Settings come from the bar layout entry, e.g.
//   { "id": "opencodeUsage", "refreshIntervalSec": 300 }
BarButton {
  id: root

  // The output this bar instance is on; the popup needs it to cover the
  // correct screen on multi-monitor setups.
  property var screen: null
  property string monitorName: ""

  property int refreshIntervalSec: 300

  horizontalPadding: 0

  onRefreshIntervalSecChanged: OpencodeStats.refreshIntervalSec = Math.max(30, root.refreshIntervalSec)

  onClicked: popup.visible ? popup.closeTree() : popup.openFor(root)
  onRightClicked: OpencodeStats.refresh()
  onMiddleClicked: OpencodeStats.refresh()

  Row {
    spacing: Style.spacingSmall

    Image {
      anchors.verticalCenter: parent.verticalCenter
      source: Quickshell.shellPath("assets/opencode.svg")
      width: 18
      height: 18
      sourceSize.width: 18
      sourceSize.height: 18
      fillMode: Image.PreserveAspectFit
    }

    Text {
      visible: OpencodeStats.ready && OpencodeStats.todayTotalTokens > 0
      text: OpencodeStats.formatTokenCount(OpencodeStats.todayTotalTokens)
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      font.bold: true
      color: Colours.bar.text
    }
  }

  OpencodePopup {
    id: popup
    output: root.screen
    monitorName: root.monitorName
  }

  Component.onCompleted: OpencodeStats.refreshIntervalSec = Math.max(30, root.refreshIntervalSec)

  component OpencodePopup: PanelWindow {
    id: panel

    property Item anchorItem: null
    property var output: null
    property string monitorName: ""

    property real anchorX: 0
    property real anchorW: 0

    readonly property bool barAtBottom: (Config.bar.position || "top") === "bottom"
    readonly property int barHeight: Config.bar.height || 38

    // Reserved width on the card's right edge so the scrollbar has its own
    // column instead of sitting on top of the content.
    readonly property real scrollbarGutter: 10

    screen: panel.output

    anchors {
      left: true
      right: true
      top: true
      bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-menu"

    color: "transparent"
    visible: false

    function openFor(item) {
      OpencodeStats.refresh()
      panel.anchorItem = item
      const pos = item.mapToItem(null, 0, 0)
      panel.anchorX = pos.x
      panel.anchorW = item.width
      panel.visible = true
    }

    function closeTree() {
      panel.visible = false
    }

    HyprlandFocusGrab {
      active: panel.visible
      windows: [panel]
      onCleared: panel.closeTree()
    }

    Connections {
      target: Hypr
      enabled: panel.visible
      function onActiveToplevelChanged() {
        if (Hypr.activeToplevel !== null)
          panel.closeTree()
      }
    }

    Item {
      id: panelRoot

      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: panel.closeTree()
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_R) {
          OpencodeStats.refresh()
          event.accepted = true
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: panel.closeTree()
      }

      Rectangle {
        id: card

        color: Colours.popup.background
        border.color: Colours.popup.border
        border.width: 1
        radius: Style.radius

        implicitWidth: Style.padding * 2 + 360 + panel.scrollbarGutter
        implicitHeight: Math.min(560, column.implicitHeight + Style.padding * 2)

        x: Math.max(4, Math.min(panel.anchorX + panel.anchorW - implicitWidth, panelRoot.width - implicitWidth - 4))
        y: panel.barAtBottom
            ? Math.max(4, panelRoot.height - panel.barHeight - implicitHeight - Style.popupGap)
            : panel.barHeight + Style.popupGap

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onClicked: {}
        }

        Flickable {
          id: flick
          anchors.fill: parent
          anchors.margins: Style.padding
          anchors.rightMargin: Style.padding + panel.scrollbarGutter
          clip: true
          contentWidth: width
          contentHeight: column.implicitHeight
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: column
            width: flick.width
            spacing: Style.spacing

          Item {
            width: parent.width
            implicitHeight: Math.max(headerIcon.implicitHeight, headerText.implicitHeight, refreshBtn.height)

            Image {
              id: headerIcon
              source: Quickshell.shellPath("assets/opencode.svg")
              width: 18
              height: 18
              sourceSize.width: 18
              sourceSize.height: 18
              fillMode: Image.PreserveAspectFit
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: headerText
              anchors.left: headerIcon.right
              anchors.leftMargin: Style.spacing
              anchors.right: refreshBtn.left
              anchors.rightMargin: Style.spacing
              anchors.verticalCenter: parent.verticalCenter
              text: "OpenCode Usage"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize
              font.bold: true
              color: Colours.popup.text
              elide: Text.ElideRight
            }

            Rectangle {
              id: refreshBtn
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: refreshLabel.implicitWidth + Style.padding * 2
              height: 22
              radius: Style.radiusSmall
              color: refreshHover.containsMouse ? Colours.hover : "transparent"
              border.color: Qt.alpha(Colours.accentAlt, 0.4)
              border.width: 1

              Text {
                id: refreshLabel
                anchors.centerIn: parent
                text: (OpencodeStats.refreshing ? "Refreshing\u2026" : "Refresh")
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeSmall
                color: Colours.popup.text
              }

              MouseArea {
                id: refreshHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: OpencodeStats.refresh()
              }
            }
          }

          Separator {}

          Text {
            width: parent.width
            visible: OpencodeStats.todayTotalTokens === 0 && OpencodeStats.totalSessions === 0
            text: "No usage data yet. Start an OpenCode session to see stats."
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.bar.textMuted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }

          StatCard {
            visible: OpencodeStats.todayTotalTokens > 0
            title: "TODAY"

            RowLayout {
              width: parent.width
              spacing: Style.spacingLarge

              StatBlock {
                value: String(OpencodeStats.todaySessions || 0)
                label: "sessions"
              }

              StatBlock {
                value: OpencodeStats.formatTokenCount(OpencodeStats.todayTotalTokens)
                label: "tokens"
              }
            }

            Repeater {
              model: {
                var out = []
                for (var k in OpencodeStats.todayTokensByModel)
                  out.push({ modelId: k, count: OpencodeStats.todayTokensByModel[k] })
                return out
              }

              delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Style.spacing

                Text {
                  Layout.fillWidth: true
                  text: OpencodeStats.friendlyModelName(modelData.modelId)
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                  color: Colours.bar.textMuted
                  elide: Text.ElideRight
                }

                Text {
                  text: OpencodeStats.formatTokenCount(modelData.count) + " tokens"
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                  font.bold: true
                  color: Colours.popup.text
                }
              }
            }
          }

          StatCard {
            visible: {
              var days = OpencodeStats.recentDays || []
              for (var i = 0; i < days.length; i++)
                if (Number(days[i].messageCount || 0) > 0)
                  return true
              return false
            }
            title: "LAST 7 DAYS"

            Repeater {
              model: OpencodeStats.recentDays

              delegate: Item {
                required property var modelData
                width: parent.width
                height: 14

                readonly property real dayCount: Number(modelData.messageCount || 0)
                readonly property real dayMax: {
                  var days = OpencodeStats.recentDays || []
                  var max = 1
                  for (var i = 0; i < days.length; i++)
                    if (Number(days[i].messageCount || 0) > max)
                      max = Number(days[i].messageCount || 0)
                  return max
                }

                RowLayout {
                  anchors.fill: parent
                  spacing: Style.spacing

                  Text {
                    Layout.preferredWidth: 84
                    text: {
                      var d = modelData.date
                      if (!d)
                        return ""
                      var dt = new Date(d + "T00:00:00")
                      var names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                      return names[dt.getDay()] + " " + String(dt.getMonth() + 1).padStart(2, "0") + "/" + String(dt.getDate()).padStart(2, "0")
                    }
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: Colours.bar.textMuted
                  }

                  Rectangle {
                    id: dayBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                    Layout.alignment: Qt.AlignVCenter
                    radius: 2
                    color: Qt.alpha(Colours.popup.text, 0.14)

                    Rectangle {
                      anchors.left: parent.left
                      anchors.top: parent.top
                      anchors.bottom: parent.bottom
                      width: dayBar.width * (dayCount / dayMax)
                      radius: 2
                      color: Qt.alpha(Colours.popup.text, 0.75)

                      Behavior on width {
                        NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic }
                      }
                    }
                  }

                  Text {
                    Layout.preferredWidth: 48
                    horizontalAlignment: Text.AlignRight
                    text: OpencodeStats.formatTokenCount(dayCount)
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    font.bold: true
                    color: Colours.popup.text
                  }
                }
              }
            }
          }

          StatCard {
            visible: {
              var usage = OpencodeStats.modelUsage || {}
              for (var k in usage)
                return true
              return false
            }
            title: "ALL-TIME"

            RowLayout {
              width: parent.width
              spacing: Style.spacingLarge

              StatBlock {
                value: String(OpencodeStats.totalSessions || 0)
                label: "sessions"
              }
            }

            Repeater {
              model: {
                var out = []
                for (var k in OpencodeStats.modelUsage)
                  out.push({ modelId: k, data: OpencodeStats.modelUsage[k] })
                return out
              }

              delegate: Column {
                required property var modelData
                Layout.fillWidth: true
                width: parent.width
                spacing: 2

                Text {
                  width: parent.width
                  text: OpencodeStats.friendlyModelName(modelData.modelId)
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeSmall
                  font.bold: true
                  color: Colours.popup.text
                  elide: Text.ElideRight
                }

                GridLayout {
                  width: parent.width
                  Layout.leftMargin: Style.spacing
                  columns: 2
                  columnSpacing: Style.spacingLarge
                  rowSpacing: 2

                  DetailPair { name: "Input"; value: OpencodeStats.formatTokenCount(modelData.data.inputTokens || 0) }
                  DetailPair { name: "Output"; value: OpencodeStats.formatTokenCount(modelData.data.outputTokens || 0) }
                  DetailPair { name: "Cache Read"; value: OpencodeStats.formatTokenCount(modelData.data.cacheReadInputTokens || 0) }
                  DetailPair { name: "Cache Write"; value: OpencodeStats.formatTokenCount(modelData.data.cacheCreationInputTokens || 0) }
                }
              }
            }
          }

          Separator {}

          Text {
            width: parent.width
            text: "r refresh \u00b7 esc close"
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.bar.textMuted
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

        Rectangle {
          anchors.top: flick.top
          anchors.bottom: flick.bottom
          anchors.right: parent.right
          anchors.rightMargin: Style.padding
          width: 4
          radius: 2
          color: Qt.alpha(Colours.popup.text, 0.1)
          visible: flick.contentHeight > flick.height

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: flick.visibleArea.yPosition * parent.height
            height: Math.max(14, flick.visibleArea.heightRatio * parent.height)
            radius: parent.radius
            color: Qt.alpha(Colours.popup.text, 0.35)
          }
        }
      }
    }
  }

  component Separator: Rectangle {
    width: parent ? parent.width : 0
    height: 1
    color: Colours.popup.border
  }

  component StatCard: Rectangle {
    id: statCard

    property string title: ""

    default property alias content: body.data

    width: parent ? parent.width : 0
    color: Qt.alpha(Colours.accentAlt, 0.06)
    border.color: Colours.popup.border
    border.width: 1
    radius: Style.radiusSmall
    implicitHeight: body.implicitHeight + Style.padding * 2

    Column {
      id: body

      anchors {
        left: statCard.left
        right: statCard.right
        top: statCard.top
        margins: Style.padding
      }
      spacing: Style.spacingSmall

      Text {
        width: body.width
        visible: statCard.title !== ""
        text: statCard.title
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeSmall
        font.bold: true
        font.letterSpacing: 1.1
        color: Colours.bar.textMuted
      }
    }
  }

  component StatBlock: Column {
    property string value: "0"
    property string label: ""

    spacing: 2

    Text {
      text: parent.value
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize + 6
      font.bold: true
      color: Colours.popup.text
    }

    Text {
      text: parent.label
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      color: Colours.bar.textMuted
    }
  }

  component DetailPair: RowLayout {
    property string name: ""
    property string value: ""

    spacing: Style.spacingSmall

    Text {
      Layout.fillWidth: true
      text: parent.name
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      color: Colours.bar.textMuted
      elide: Text.ElideRight
    }

    Text {
      text: parent.value
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeSmall
      font.bold: true
      color: Colours.popup.text
    }
  }
}
