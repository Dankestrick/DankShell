import QtQuick
import "../../"

// PluginGrid — a tile for every plugin, with its live status. Click one to use
// it. All plugins shows every group; the Running / Not running / Background /
// Omarchy tabs show one (`only`). The window's search box narrows it.
Column {
  id: grid
  property bool showing: false
  property string only: ""            // one group, or "" for all of them
  property string filter: ""
  spacing: 14

  readonly property var groups: only !== "" ? [only] : ["Running", "Not running", "Background", "Omarchy"]
  readonly property string q: filter.trim().toLowerCase()
  readonly property real tileWidth: (width - 16) / 3

  Text {
    visible: grid.q !== "" && !grid.groups.some(g => Installed.items.some(p => p.group === g && grid.matches(p)))
    text: "Nothing here matches"
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
  }
  function matches(p) { return q === "" || (p.name + " " + p.id + " " + (p.description || "")).toLowerCase().includes(q) }

  Repeater {
    model: grid.groups
    Column {
      id: section
      required property string modelData
      readonly property var tiles: Installed.items.filter(p => p.group === modelData && grid.matches(p))
      visible: tiles.length > 0
      width: grid.width
      spacing: 8

      Text {
        visible: grid.only === ""
        text: section.modelData
        color: Theme.textDim
        font.family: Theme.fontText
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
      }
      Flow {
        width: parent.width
        spacing: 8
        Repeater {
          model: section.tiles
          Tile {
            required property var modelData
            readonly property var st: Status.of(modelData.key)
            width: grid.tileWidth
            icon: modelData.icon
            name: modelData.name
            off: !modelData.enabled
            status: off ? "Off" : st.text !== "" ? st.text : modelData.group === "Background" ? "In the background" : "Running"
            alert: st.alert
            pinned: { void(Settings.v.pinned); return Settings.isPinned(modelData.key) }
            onClicked: Popouts.center = modelData.key
          }
        }
      }
    }
  }
}
