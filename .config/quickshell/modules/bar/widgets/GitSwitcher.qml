import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.theme

// View and switch the global Git identity (user.name / user.email).
//
//   click        toggle the account popup
//   right click  refresh the displayed identity
//
// Accounts live in a JSON file, { "accounts": [ { label, name, email } ] },
// re-read every time the popup opens. Clicking an account runs
// `git config --global user.name` / `user.email` for it.
BarButton {
  id: root

  // The output this bar instance is on; the popup needs it to cover the
  // correct screen on multi-monitor setups.
  property var screen: null
  property string monitorName: ""

  property string accountsPath: Quickshell.env("HOME") + "/.config/quickshell/git-switcher.json"

  horizontalPadding: 0

  property var accounts: []
  property string currentName: ""
  property string currentEmail: ""
  property string currentLabel: ""
  property bool showEmails: true

  function loadAccounts() {
    accountsProc.running = true
  }

  function parseAccounts(raw) {
    var list = []
    var text = String(raw || "").trim()
    if (text !== "") {
      try {
        var data = JSON.parse(text)
        if (data && Array.isArray(data.accounts)) {
          for (var i = 0; i < data.accounts.length; i++) {
            var a = data.accounts[i] || {}
            list.push({
              label: String(a.label || a.name || ""),
              name: String(a.name || ""),
              email: String(a.email || "")
            })
          }
        }
      } catch (e) {
        list = []
      }
    }
    root.accounts = list
    root.matchActive()
  }

  function refresh() {
    root.loadAccounts()
    identityProc.running = true
  }

  function matchActive() {
    root.currentLabel = ""
    for (var i = 0; i < root.accounts.length; i++) {
      var a = root.accounts[i]
      if (a.email !== "" && a.email === root.currentEmail) {
        root.currentLabel = a.label
        return
      }
    }
    for (var j = 0; j < root.accounts.length; j++) {
      var b = root.accounts[j]
      if (b.name !== "" && b.name === root.currentName) {
        root.currentLabel = b.label
        return
      }
    }
  }

  function switchTo(account) {
    if (!account)
      return
    switchProc.command = ["bash", "-c",
      'git config --global user.name "$1" && git config --global user.email "$2"',
      "git-switcher", String(account.name || ""), String(account.email || "")]
    switchProc.running = true
  }

  function openAccounts() {
    Quickshell.execDetached(["sh", "-c",
      '${TERMINAL:-ghostty} -e ${EDITOR:-nvim} "$1"', "git-switcher", root.accountsPath])
  }

  onClicked: popup.visible ? popup.closeTree() : popup.openFor(root)
  onRightClicked: root.refresh()

  Text {
    text: "\uDB80\uDEA2"
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    color: Colours.bar.text
  }

  GitPopup {
    id: popup
    output: root.screen
    monitorName: root.monitorName
  }

  Process {
    id: identityProc
    command: ["bash", "-c", 'git config --global user.name; git config --global user.email']
    stdout: StdioCollector {
      id: identityOut
      waitForEnd: true
    }
    onExited: function(exitCode, exitStatus) {
      var lines = String(identityOut.text || "").split("\n")
      root.currentName = (lines[0] || "").trim()
      root.currentEmail = (lines[1] || "").trim()
      root.matchActive()
    }
  }

  Process {
    id: switchProc
    onExited: function(exitCode, exitStatus) { root.refresh() }
  }

  Process {
    id: accountsProc
    command: ["cat", root.accountsPath]
    stdout: StdioCollector {
      id: accountsOut
      waitForEnd: true
    }
    onExited: function(exitCode, exitStatus) {
      root.parseAccounts(accountsOut.text)
    }
  }

  Component.onCompleted: root.refresh()

  component GitPopup: PanelWindow {
    id: panel

    property Item anchorItem: null
    property var output: null
    property string monitorName: ""

    property real anchorX: 0
    property real anchorW: 0

    readonly property bool barAtBottom: (Config.bar.position || "top") === "bottom"
    readonly property int barHeight: Config.bar.height || 38

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
      root.refresh()
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

        implicitWidth: Style.padding * 2 + 320
        implicitHeight: column.implicitHeight + Style.padding * 2

        x: Math.max(4, Math.min(panel.anchorX + panel.anchorW - implicitWidth, panelRoot.width - implicitWidth - 4))
        y: panel.barAtBottom
            ? Math.max(4, panelRoot.height - panel.barHeight - implicitHeight)
            : panel.barHeight

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onClicked: {}
        }

        Column {
          id: column

          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Style.padding
          }
          spacing: Style.spacing

          Item {
            width: parent.width
            implicitHeight: Math.max(titleIcon.implicitHeight, titleText.implicitHeight)

            Text {
              id: titleIcon
              text: "\uDB80\uDEA2"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize + 6
              color: Colours.popup.text
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: titleText
              anchors.left: titleIcon.right
              anchors.leftMargin: Style.spacing
              anchors.right: emailToggle.left
              anchors.rightMargin: Style.spacing
              anchors.verticalCenter: parent.verticalCenter
              text: "Git Accounts"
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize
              font.bold: true
              color: Colours.popup.text
              elide: Text.ElideRight
            }

            Rectangle {
              id: emailToggle
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: 34
              height: 18
              radius: height / 2
              color: emailToggleHover.containsMouse
                  ? Qt.alpha(Colours.accentAlt, root.showEmails ? 0.6 : 0.25)
                  : Qt.alpha(Colours.accentAlt, root.showEmails ? 0.4 : 0.15)
              border.color: root.showEmails
                  ? Qt.alpha(Colours.accentAlt, 0.7)
                  : Qt.alpha(Colours.bar.textMuted, 0.35)
              border.width: 1

              Behavior on color {
                ColorAnimation { duration: Style.animFast }
              }

              Rectangle {
                id: toggleKnob
                width: 12
                height: 12
                radius: 6
                color: root.showEmails ? Colours.accentAlt : Colours.popup.text
                anchors.verticalCenter: parent.verticalCenter
                x: root.showEmails ? parent.width - width - 2 : 2

                Behavior on x {
                  NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic }
                }
              }

              HoverHandler {
                id: emailToggleHover
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showEmails = !root.showEmails
              }
            }
          }

          Separator {}

          Item {
            width: parent.width
            visible: root.currentName !== ""
            implicitHeight: activeCard.implicitHeight

            Rectangle {
              id: activeCard
              width: parent.width
              implicitHeight: Math.max(40,
                activeName.implicitHeight
                + (root.showEmails && root.currentEmail !== "" ? activeEmail.implicitHeight + 2 : 0)
                + Style.spacing)
              radius: Style.radiusSmall
              color: Qt.alpha(Colours.accentAlt, 0.25)
              border.color: "transparent"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.spacing
                anchors.rightMargin: Style.spacing
                anchors.topMargin: Style.paddingSmall
                anchors.bottomMargin: Style.paddingSmall
                spacing: Style.spacing

                Rectangle {
                  Layout.alignment: Qt.AlignVCenter
                  Layout.preferredWidth: Style.spacing
                  Layout.preferredHeight: Style.spacing
                  radius: Style.spacing / 2
                  color: "#4ade80"
                }

                Text {
                  Layout.alignment: Qt.AlignVCenter
                  text: "\uDB80\uDC04"
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSize + 2
                  color: Colours.popup.text
                }

                Column {
                  Layout.fillWidth: true
                  spacing: 2

                  Text {
                    id: activeName
                    width: parent.width
                    text: ((root.currentLabel || "") !== "" ? (root.currentLabel || "") : (root.currentName || ""))
                      + (((root.currentLabel || "") !== "" && (root.currentName || "") !== "")
                        ? " (" + (root.currentName || "") + ")" : "")
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSize
                    color: Colours.popup.text
                    elide: Text.ElideRight
                  }

                  Text {
                    id: activeEmail
                    width: parent.width
                    visible: root.showEmails && (root.currentEmail || "") !== ""
                    text: root.currentEmail || ""
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeSmall
                    color: Colours.bar.textMuted
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }

          Text {
            width: parent.width
            visible: root.currentName === ""
            text: "No global identity set"
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.bar.textMuted
            wrapMode: Text.WordWrap
          }

          Separator {
            visible: root.accounts.length > 0
          }

          Column {
            width: parent.width
            visible: root.accounts.length > 0
            spacing: Style.spacingSmall

            Repeater {
              model: root.accounts

              AccountButton {
                required property var modelData
                width: parent.width
                label: modelData.label
                accountName: modelData.name
                active: root.currentLabel !== "" && root.currentLabel === modelData.label
                onClicked: root.switchTo(modelData)
              }
            }
          }

          Text {
            width: parent.width
            visible: root.accounts.length === 0
            text: "No accounts configured. Add entries to " + root.accountsPath
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeSmall
            color: Colours.bar.textMuted
            wrapMode: Text.WordWrap
          }

          Separator {}

          AccountButton {
            width: parent.width
            label: "Add Account"
            onClicked: root.openAccounts()
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

  component AccountButton: Rectangle {
    id: btn

    property string label: ""
    property string accountName: ""
    property bool active: false

    signal clicked()

    implicitHeight: Math.max(34, nameText.implicitHeight + Style.spacing)
    radius: Style.radiusSmall
    color: btn.active
        ? Qt.alpha(Colours.accentAlt, 0.25)
        : (btnHover.containsMouse ? Qt.alpha(Colours.accentAlt, 0.12) : "transparent")
    border.color: btn.active ? Qt.alpha(Colours.accentAlt, 0.5) : Colours.popup.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.spacing
      anchors.rightMargin: Style.spacing
      anchors.topMargin: Style.paddingSmall
      anchors.bottomMargin: Style.paddingSmall
      spacing: Style.spacing

      Rectangle {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: Style.spacing
        Layout.preferredHeight: Style.spacing
        radius: Style.spacing / 2
        color: "#4ade80"
        opacity: btn.active ? 1 : 0
      }

      Text {
        Layout.alignment: Qt.AlignVCenter
        text: "\uDB80\uDC04"
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        color: Colours.bar.textMuted
      }

      Text {
        id: nameText
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: ((btn.label || "") !== "" ? (btn.label || "") : (btn.accountName || ""))
          + (((btn.label || "") !== "" && (btn.accountName || "") !== "")
            ? " (" + (btn.accountName || "") + ")" : "")
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        color: Colours.popup.text
        elide: Text.ElideRight
      }
    }

    HoverHandler {
      id: btnHover
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: btn.clicked()
    }
  }
}
