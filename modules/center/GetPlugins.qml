import QtQuick
import Quickshell
import "../../"

// GetPlugins — the Plugins window's "Updates" page: plugins with an update
// waiting, and git installs (God's Eye View, ComfyUI, the CloneWars clones)
// that are behind their repo. Tick one, some or all, then Update selected.
// Everything runs through services/PluginManager.qml.
Column {
  id: page
  property bool showing: false
  property string filter: ""          // the window's search box
  signal closeRequested()
  spacing: 10

  onShowingChanged: if (showing) PluginManager.checkAll(false)
  Component.onCompleted: if (showing) PluginManager.checkAll(false)

  readonly property bool checking: PluginManager.checking || PluginManager.gitChecking

  // Every row that can be updated: { key, kind, name, sub, note }
  readonly property var rows: {
    const q = filter.trim().toLowerCase()
    const out = []
    for (const id of PluginManager.updatable) {
      const info = Installed.items.find(p => p.id === id) || Installed.all.find(p => p.id === id) || { name: id, version: "" }
      out.push({ key: "plugin:" + id, kind: "plugin", name: info.name, icon: info.icon || "extension",
                 sub: (info.version ? "v" + info.version + " · " : "") + "update ready",
                 note: PluginManager.updates[id].note || "" })
    }
    for (const g of PluginManager.gitUpdatable)
      out.push({ key: "git:" + g.path, kind: "git", name: g.name, icon: "commit",
                 sub: g.behind.toLocaleString(Qt.locale("en_US"), "f", 0) + (g.behind === 1 ? " new commit" : " new commits")
                      + (g.note ? "" : g.last ? " · " + g.last : ""),
                 note: g.note || "" })
    return q === "" ? out : out.filter(r => (r.name + " " + r.sub).toLowerCase().includes(q))
  }
  readonly property var pluginRows: rows.filter(r => r.kind === "plugin")
  readonly property var gitRows: rows.filter(r => r.kind === "git")

  // What's ticked (key -> true). Rows that went away drop out on their own.
  property var picked: ({})
  readonly property var pickedKeys: rows.map(r => r.key).filter(k => picked[k])
  readonly property bool allPicked: rows.length > 0 && pickedKeys.length === rows.length
  function toggle(key) { const p = Object.assign({}, picked); if (p[key]) delete p[key]; else p[key] = true; picked = p }
  function pickAll(on) { const p = {}; if (on) for (const r of rows) p[r.key] = true; picked = p }
  function updatePicked() {
    const keys = pickedKeys
    if (!keys.length) return
    PluginManager.updateMany(keys)
    picked = ({})
  }

  component Pill: Rectangle {
    id: pb
    property string label: ""
    property string icon: ""
    property bool primary: false
    signal clicked()
    width: pr.implicitWidth + 22; height: 28; radius: 14
    opacity: enabled ? 1 : 0.4
    color: primary ? Theme.accent : tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surface
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Row {
      id: pr; anchors.centerIn: parent; spacing: 5
      Icon { visible: pb.icon !== ""; name: pb.icon; font.pixelSize: 15; color: pb.primary ? Theme.surface : Theme.text; anchors.verticalCenter: parent.verticalCenter }
      Text { text: pb.label; color: pb.primary ? Theme.surface : Theme.text; font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; enabled: pb.enabled; cursorShape: Qt.PointingHandCursor; onClicked: pb.clicked() }
  }
  component Head: Text { color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }

  // A tile you can tick: click anywhere on it.
  component UpdateTile: Tile {
    required property var modelData
    width: (page.width - 16) / 3
    icon: modelData.icon
    name: modelData.name
    status: modelData.sub + (modelData.note ? " · " + modelData.note : "")
    alert: false
    checkable: true
    picked: !!page.picked[modelData.key]
    clickable: !PluginManager.busy
    onClicked: page.toggle(modelData.key)
  }

  // ── What's happening ──────────────────────────
  Card {
    width: parent.width
    visible: PluginManager.jobText !== ""
    Row {
      spacing: 10
      Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: PluginManager.busy ? "progress_activity" : PluginManager.job.state === "failed" ? "error" : "check_circle"
        color: PluginManager.job.state === "failed" ? Theme.urgent : Theme.accent
        RotationAnimation on rotation { running: PluginManager.busy; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: page.width - 70; wrapMode: Text.WordWrap
        text: PluginManager.jobText
        color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12
      }
    }
  }

  // ── The list ──────────────────────────────────
  Card {
    width: parent.width
    Item {
      width: parent.width; height: 28
      Head {
        anchors.verticalCenter: parent.verticalCenter
        text: page.checking ? "Checking for updates…"
            : page.rows.length === 0 ? "Everything is up to date"
            : page.rows.length + (page.rows.length === 1 ? " update ready" : " updates ready")
      }
      Pill {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        icon: "refresh"; label: "Check again"
        enabled: !page.checking && !PluginManager.busy
        onClicked: PluginManager.checkAll(true)
      }
    }
    Item {
      visible: page.rows.length > 0
      width: parent.width; height: 30
      Pill {
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        icon: page.allPicked ? "deselect" : "select_all"; label: page.allPicked ? "Select none" : "Select all"
        enabled: !PluginManager.busy
        onClicked: page.pickAll(!page.allPicked)
      }
      Pill {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        icon: "download"; primary: true
        label: page.pickedKeys.length ? "Update " + page.pickedKeys.length + " selected" : "Pick what to update"
        enabled: page.pickedKeys.length > 0 && !PluginManager.busy
        onClicked: page.updatePicked()
      }
    }

  }

  Head { visible: page.pluginRows.length > 0; text: "Plugins" }
  Flow { visible: page.pluginRows.length > 0; width: page.width; spacing: 8; Repeater { model: page.pluginRows; UpdateTile { } } }

  Head { visible: page.gitRows.length > 0; text: "Git installs" }
  Flow { visible: page.gitRows.length > 0; width: page.width; spacing: 8; Repeater { model: page.gitRows; UpdateTile { } } }

  // What was checked, so an empty list still says something.
  Text {
    visible: !page.checking && PluginManager.gitInstalls.length > 0
    width: parent.width; wrapMode: Text.WordWrap
    readonly property var gi: PluginManager.gitInstalls
    text: {
      const fine = gi.filter(g => !g.update && !g.note).length
      const off = gi.filter(g => !g.update && g.note)
      return fine + " git installs are up to date"
        + (off.length ? "  ·  skipped: " + off.map(g => g.name + " (" + g.note + ")").join(", ") : "")
        + "  ·  more go in ~/.config/dankshell/git-installs.json"
    }
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
  }
}
