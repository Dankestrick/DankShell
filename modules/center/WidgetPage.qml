import QtQuick
import "../../"

// WidgetPage — the Plugins tab page for a bar widget (network, mail,
// Dropbox...). Its dropdown is the real thing, so "Open" drops it under the
// island, the same as clicking it in the top row.
Column {
  id: page
  property var plugin: null
  property bool showing: false
  signal closeRequested()
  spacing: 10

  Card {
    width: parent.width
    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      text: "This one is a bar widget: it opens its own dropdown under the island. Pin it to keep its icon in the island's top row."
      color: Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 12
    }
    Rectangle {
      width: openRow.implicitWidth + 32
      height: 36
      radius: 18
      color: openTap.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
      Row {
        id: openRow
        anchors.centerIn: parent
        spacing: 6
        Icon { name: "open_in_new"; color: Theme.surface; anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Open " + (page.plugin ? page.plugin.name : ""); color: Theme.surface; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
      }
      MouseArea {
        id: openTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: { const id = page.plugin.key; Popouts.closeCenter(); Popouts.summon(id) }
      }
    }
  }
}
