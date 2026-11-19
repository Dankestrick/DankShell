import QtQuick
import Quickshell
import "../../"

// GetPlugins — the Plugins window's "Get plugins" page: updates waiting for
// the plugins you have, then the Omarchy marketplace (plugins.omarchy.org) to
// search and install from. Everything runs through services/PluginManager.qml.
Column {
  id: page
  property bool showing: false
  property string filter: ""          // the window's search box
  signal closeRequested()
  spacing: 10

  onShowingChanged: if (showing) { PluginManager.loadCatalog(); PluginManager.checkUpdates(false) }
  Component.onCompleted: if (showing) { PluginManager.loadCatalog(); PluginManager.checkUpdates(false) }

  // Best matches first (the list is already verified-first, most stars first).
  readonly property var results: {
    const q = filter.trim().toLowerCase()
    const all = PluginManager.catalog.filter(p => !PluginManager.installed(p.id))
    const hit = q === "" ? all : all.filter(p => (p.name + " " + p.id + " " + p.description + " " + p.category + " " + p.author).toLowerCase().includes(q))
    return hit.slice(0, 40)
  }

  component Pill: Rectangle {
    id: pb
    property string label: ""
    property string icon: ""
    property bool primary: false
    property bool danger: false
    signal clicked()
    width: pr.implicitWidth + 22; height: 28; radius: 14
    opacity: enabled ? 1 : 0.4
    color: primary ? Theme.accent : danger ? Theme.urgent : tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surface
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Row {
      id: pr; anchors.centerIn: parent; spacing: 5
      Icon { visible: pb.icon !== ""; name: pb.icon; font.pixelSize: 15; color: pb.primary || pb.danger ? Theme.surface : Theme.text; anchors.verticalCenter: parent.verticalCenter }
      Text { text: pb.label; color: pb.primary || pb.danger ? Theme.surface : Theme.text; font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; enabled: pb.enabled; cursorShape: Qt.PointingHandCursor; onClicked: pb.clicked() }
  }
  component Head: Text { color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }

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

  // ── Updates ───────────────────────────────────
  Card {
    width: parent.width
    Item {
      width: parent.width; height: 28
      Head { anchors.verticalCenter: parent.verticalCenter; text: PluginManager.checking ? "Checking for updates…" : PluginManager.updatable.length ? "Updates ready" : "Your plugins are up to date" }
      Pill {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        icon: "refresh"; label: "Check again"
        enabled: !PluginManager.checking && !PluginManager.busy
        onClicked: PluginManager.checkUpdates(true)
      }
    }
    Repeater {
      model: PluginManager.updatable
      Item {
        required property var modelData
        readonly property var info: Installed.all.find(p => p.id === modelData) || { name: modelData, version: "" }
        width: parent.width; height: 40
        Column {
          anchors.verticalCenter: parent.verticalCenter
          Text { text: info.name; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
          Text { text: (info.version ? "v" + info.version + "  ·  " : "") + "new changes on its repo"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
        }
        Pill {
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          icon: "download"; label: "Update"; primary: true
          enabled: !PluginManager.busy
          onClicked: PluginManager.update(modelData)
        }
      }
    }
  }

  // ── Marketplace ───────────────────────────────
  Head {
    text: PluginManager.catalogLoading ? "Loading the marketplace…"
        : PluginManager.catalogError !== "" ? PluginManager.catalogError
        : page.filter.trim() === "" ? "Popular on the marketplace  ·  type in the search box to find more"
        : page.results.length + (page.results.length === 40 ? "+" : "") + " found"
  }
  Repeater {
    model: page.results
    Card {
      required property var modelData
      width: page.width
      Item {
        width: parent.width; height: 20
        Text {
          id: nm
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.name
          color: Theme.text; font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.DemiBold
        }
        Icon { visible: modelData.verified; anchors.left: nm.right; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter; name: "verified"; filled: true; color: Theme.accent; font.pixelSize: 14 }
        Pill {
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          icon: "add"; label: "Install"; primary: true
          enabled: !PluginManager.busy
          onClicked: PluginManager.install(modelData)
        }
      }
      Text {
        width: parent.width - 100; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
        text: modelData.description
        color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11
      }
      Text {
        text: [modelData.author ? "by " + modelData.author : "", modelData.kind, modelData.category, modelData.version ? "v" + modelData.version : "", modelData.stars ? "★ " + modelData.stars : ""].filter(x => x).join("  ·  ")
        color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
      }
    }
  }
}
