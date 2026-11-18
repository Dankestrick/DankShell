import QtQuick
import "../../"

// PluginGrid — the Plugins window's front page: a tile for every plugin
// you have running, with its live status. Click one to use it.
Column {
  id: grid
  property bool showing: false
  spacing: 14

  readonly property var groups: ["Running", "Not running"]

  Repeater {
    model: grid.groups
    Column {
      id: section
      required property string modelData
      readonly property var tiles: Installed.items.filter(p => p.group === modelData)
      visible: tiles.length > 0
      width: grid.width
      spacing: 8

      Text {
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
          Rectangle {
            id: tile
            required property var modelData
            readonly property var st: Status.of(modelData.key)
            readonly property bool off: !modelData.enabled
            width: (section.width - 16) / 3
            height: 96
            radius: Sizes.cardRadius
            color: tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surfaceRaised
            opacity: off ? 0.55 : 1
            scale: tap.pressed ? 0.97 : 1
            Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
            Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.hover) } }

            Rectangle {
              x: 12; y: 12
              width: 34; height: 34; radius: 17
              color: tap.containsMouse ? Theme.accent : Theme.surface
              Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
              Icon { anchors.centerIn: parent; name: tile.modelData.icon; color: tap.containsMouse ? Theme.surface : Theme.accent; font.pixelSize: 17 }
            }
            // pinned to the island's top row
            Icon {
              visible: { void(Settings.v.pinned); return Settings.isPinned(tile.modelData.key) }
              anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
              name: "push_pin"; filled: true; color: Theme.textDim; font.pixelSize: 13
            }
            Column {
              x: 12
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 10
              width: parent.width - 24
              spacing: 1
              Text { width: parent.width; text: tile.modelData.name; elide: Text.ElideRight; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
              Text {
                width: parent.width
                text: tile.off ? "Off" : tile.st.text !== "" ? tile.st.text : "Running"
                elide: Text.ElideRight
                color: tile.st.alert ? Theme.accent : Theme.textDim
                font.family: Theme.fontText
                font.pixelSize: 10
              }
            }
            MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Popouts.center = tile.modelData.key }
          }
        }
      }
    }
  }
}
