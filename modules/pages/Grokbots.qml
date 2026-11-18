import QtQuick
import Quickshell.Io
import "../../"

// Grok Bots — OmaGrokBots' roster as a dashboard page: who has news, who is
// working or waiting. Click a bot and its chat drops down. The roster is
// OmaGrokBots' own Inbox.qml (PluginHost runs it); windows only move through
// its focus.py, the same way its bar widget does it.
Column {
  id: page
  spacing: 10
  signal closeRequested()

  readonly property var service: PluginHost.service("grokbots")
  readonly property var hosted: PluginHost.hosted("grokbots")
  readonly property var bots: service && service.bots ? service.bots : []
  property string status: ""

  function helper(name) { return page.hosted ? page.hosted.dir + "/" + name : "" }
  function action(args, text) {
    if (focusProc.running || !hosted) return
    status = text
    focusProc.line = ""
    focusProc.command = ["timeout", "--foreground", "25", "bash", helper("bin/run-capped"), "--max-bytes", "4096", "--max-seconds", "25",
      "python3", "-B", helper("focus.py")].concat(args)
    focusProc.running = true
  }
  function drop(id) {
    if (!/^[A-Za-z0-9_-]{1,80}$/.test(String(id || ""))) return
    action(["--drop", String(id)], "Opening chat")
    page.closeRequested()
  }

  // While the page is showing, the roster watches for changes live.
  property bool showing: false
  onShowingChanged: if (service) { service.live = showing; if (showing) service.refresh(true) }
  onServiceChanged: if (service) service.live = showing

  Process {
    id: focusProc
    property string line: ""
    stdout: SplitParser { onRead: (l) => focusProc.line = String(l || "").slice(0, 4096) }
    onExited: (code) => {
      let ok = false, err = ""
      try { const d = JSON.parse(focusProc.line); ok = code === 0 && d.ok === true; err = d.error || "" } catch (e) {}
      page.status = ok ? "" : String(err || "Could not open Grok Bot").slice(0, 80)
      if (!ok) clearStatus.restart()
    }
  }
  Timer { id: clearStatus; interval: 2500; onTriggered: page.status = "" }

  Text {
    visible: !page.hosted
    width: parent.width
    wrapMode: Text.WordWrap
    text: "Grok Bots is still on Omarchy's side. Run `dankshell on` to hand it to DankShell."
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12
  }

  Card {
    visible: !!page.hosted
    width: parent.width
    Item {
      width: parent.width
      height: 44
      DeviceHeader {
        width: parent.width - btns.width - 8
        icon: "smart_toy"
        title: "Grok Bots"
        subtitle: !page.service ? "Starting"
          : [page.service.botCount + " bots",
             page.service.unreadCount ? page.service.unreadCount + " unread" : "",
             page.service.waitingCount ? page.service.waitingCount + " waiting" : ""].filter(t => t).join(" · ")
        active: !!(page.service && page.service.hasSnapshot)
      }
      Row {
        id: btns
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        RoundButton { icon: "refresh"; onClicked: page.service.refresh(true) }
        RoundButton { icon: "open_in_new"; onClicked: { page.action(["--open"], "Opening Grok Bot"); page.closeRequested() } }
      }
    }
    Text {
      width: parent.width
      visible: text !== ""
      text: page.status !== "" ? page.status : page.service && page.service.lastError ? page.service.lastError : ""
      wrapMode: Text.WordWrap
      color: page.status !== "" ? Theme.textDim : Theme.urgent
      font.family: Theme.fontText; font.pixelSize: 11
    }
  }

  Card {
    visible: page.bots.length > 0
    width: parent.width
    spacing: 2
    padding: 8
    Repeater {
      model: page.bots.slice(0, 8)
      Rectangle {
        id: row
        required property var modelData
        readonly property int unread: Number(modelData.unread || 0)
        width: parent.width
        height: 48
        radius: 12
        color: tap.containsMouse ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }

        // OmaGrokBots' own bot face, in the bot's color and shape.
        Loader {
          id: face
          x: 8
          anchors.verticalCenter: parent.verticalCenter
          width: 28; height: 28
          source: page.hosted ? "file://" + page.hosted.dir + "/BotFace.qml" : ""
          onLoaded: {
            item.iconSize = 28
            item.color = Qt.binding(() => row.modelData.color || Theme.accent)
            item.shape = Qt.binding(() => row.modelData.shape || "square")
            item.lively = Qt.binding(() => !!(row.modelData.waiting || row.modelData.busy || row.unread > 0))
            item.holeColor = Qt.binding(() => Theme.surfaceRaised)
          }
        }
        Column {
          anchors.left: face.right; anchors.leftMargin: 12
          anchors.right: badge.left; anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          Item {
            width: parent.width
            height: nameText.implicitHeight
            Text { id: nameText; text: row.modelData.name || "Bot"; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
            Text { anchors.left: nameText.right; anchors.leftMargin: 8; anchors.right: whenText.left; anchors.rightMargin: 6; anchors.baseline: nameText.baseline; text: row.modelData.team || ""; elide: Text.ElideRight; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
            Text { id: whenText; anchors.right: parent.right; anchors.baseline: nameText.baseline; text: row.modelData.when || ""; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
          }
          Text {
            width: parent.width
            text: {
              const line = String(row.modelData.preview || "No messages yet")
              return row.modelData.busy ? "Working · " + line : row.modelData.waiting ? "Waiting · " + line : line
            }
            elide: Text.ElideRight
            color: row.modelData.busy || row.modelData.waiting ? Theme.accent : Theme.textDim
            font.family: Theme.fontText; font.pixelSize: 11
          }
        }
        Rectangle {
          id: badge
          anchors.right: parent.right; anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          visible: row.unread > 0
          width: visible ? Math.max(20, countText.implicitWidth + 10) : 0
          height: 20
          radius: 10
          color: Theme.accent
          Text { id: countText; anchors.centerIn: parent; text: row.unread; color: Theme.surface; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.Bold }
        }
        MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.drop(row.modelData.id) }
      }
    }
  }

  Card {
    visible: !!page.hosted && page.bots.length === 0
    width: parent.width
    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      text: page.service && page.service.hasSnapshot ? "No bots yet." : "Open Grok Bot once and its bots show up here."
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12
    }
  }
}
