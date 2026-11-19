import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

// Keys — every keyboard shortcut you have (Omarchy's, yours and DankShell's),
// read from `omarchy menu keybindings --print`. Type in the window's search box
// to find one by key or by what it does.
Column {
  id: page
  property bool showing: false
  property string filter: ""
  signal closeRequested()
  spacing: 10

  property var binds: []               // [{ keys: ["SUPER", "K"], alt: [...], action }]
  onShowingChanged: if (showing && !binds.length) reader.running = true
  Component.onCompleted: if (showing) reader.running = true

  Process {
    id: reader
    command: ["omarchy", "menu", "keybindings", "--print"]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = []
        for (const line of String(text).split("\n")) {
          const m = line.match(/^(.+?)\s+→\s+(.+)$/)
          if (!m) continue
          // "SUPER + W / SUPER + Q" = two ways to do the same thing
          const combos = m[1].trim().split(/\s+\/\s+/).map(c => c.split(/\s+\+\s+|\s+/).filter(k => k && k !== "+"))
          out.push({ combos: combos, action: m[2].trim() })
        }
        page.binds = out
      }
    }
  }

  readonly property var shown: {
    const q = filter.trim().toLowerCase()
    if (!q) return binds
    return binds.filter(b => (b.action + " " + b.combos.map(c => c.join(" ")).join(" ")).toLowerCase().includes(q))
  }

  Text {
    text: page.binds.length === 0 ? "Reading your shortcuts…"
        : page.filter.trim() === "" ? page.binds.length + " shortcuts  ·  type in the search box to find one"
        : page.shown.length + " found"
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase
  }

  Card {
    width: parent.width
    visible: page.shown.length > 0
    spacing: 2
    Repeater {
      model: page.shown
      Item {
        required property var modelData
        width: parent.width
        height: Math.max(30, keysFlow.implicitHeight + 8)
        Flow {
          id: keysFlow
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width * 0.48
          spacing: 4
          Repeater {
            model: modelData.combos
            Row {
              required property var modelData
              required property int index
              spacing: 3
              Text { visible: index > 0; text: "or"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
              Repeater {
                model: modelData
                Rectangle {
                  required property var modelData
                  width: kt.implicitWidth + 12; height: 20; radius: 6
                  color: Theme.surface
                  border.width: 1; border.color: Theme.edge
                  Text { id: kt; anchors.centerIn: parent; text: modelData; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold }
                }
              }
            }
          }
        }
        Text {
          anchors.left: keysFlow.right; anchors.leftMargin: 10
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          text: modelData.action
          color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12
        }
      }
    }
  }
}
