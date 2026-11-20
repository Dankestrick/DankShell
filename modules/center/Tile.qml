import QtQuick
import "../../"

// Tile — one square in the Plugins window's grids (All plugins, Running,
// Background, Omarchy, Updates). Three to a row.
//   checkable: a tick box in the corner (Updates); `picked` lights the tile.
Rectangle {
  id: tile
  property string icon: ""
  property string name: ""
  property string status: ""
  property bool alert: false          // status in the accent color (unread, low battery)
  property bool off: false            // dimmed
  property bool pinned: false         // pin in the corner
  property bool checkable: false
  property bool picked: false
  property bool clickable: true
  signal clicked()

  width: 160; height: 96
  radius: Sizes.cardRadius
  color: picked ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
       : tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surfaceRaised
  border.width: picked ? 1 : 0
  border.color: Theme.accent
  opacity: off ? 0.55 : 1
  scale: tap.pressed ? 0.97 : 1
  Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
  Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.hover) } }

  readonly property bool lit: tap.containsMouse || picked
  Rectangle {
    x: 12; y: 12
    width: 34; height: 34; radius: 17
    color: tile.lit ? Theme.accent : Theme.surface
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Icon { anchors.centerIn: parent; name: tile.icon; color: tile.lit ? Theme.surface : Theme.accent; font.pixelSize: 17 }
  }
  Icon {
    visible: tile.pinned && !tile.checkable
    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
    name: "push_pin"; filled: true; color: Theme.textDim; font.pixelSize: 13
  }
  Icon {
    visible: tile.checkable
    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 9
    name: tile.picked ? "check_box" : "check_box_outline_blank"; filled: tile.picked
    color: tile.picked ? Theme.accent : Theme.textDim; font.pixelSize: 19
  }
  Column {
    x: 12
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10
    width: parent.width - 24
    spacing: 1
    Text { width: parent.width; text: tile.name; elide: Text.ElideRight; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
    Text {
      width: parent.width
      text: tile.status
      elide: Text.ElideRight
      color: tile.alert ? Theme.accent : Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 10
    }
  }
  MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; enabled: tile.clickable; cursorShape: Qt.PointingHandCursor; onClicked: tile.clicked() }
}
