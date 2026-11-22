import QtQuick
import "../"

// ToggleTile — a rounded button with a round icon chip, a name and a status
// line (saneAspect's control-center tiles). The chip lights up in the accent
// color when it's on.
Rectangle {
  id: tile

  property string icon: ""
  property string title: ""
  property string status: ""
  property bool on: false
  property bool busy: false
  property bool hasMore: false   // a › on the right that opens its page
  signal clicked()
  signal more()
  signal rightClicked()   // a tile with its own right-click (Bluetooth opens its window)
  property bool hasRightClick: false

  implicitHeight: 54
  radius: Sizes.cardRadius
  color: tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surfaceRaised
  Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }

  Rectangle {
    id: chip
    anchors.left: parent.left
    anchors.leftMargin: 9
    anchors.verticalCenter: parent.verticalCenter
    width: 36; height: 36; radius: 18
    color: tile.on ? Theme.accent : Theme.surfaceRaised
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Icon {
      anchors.centerIn: parent
      name: tile.icon
      filled: tile.on
      color: tile.on ? Theme.surface : Theme.text
      opacity: tile.busy ? 0.4 : 1
    }
  }

  Column {
    anchors.left: chip.right
    anchors.leftMargin: 10
    anchors.right: parent.right
    anchors.rightMargin: tile.hasMore ? 38 : 10
    anchors.verticalCenter: parent.verticalCenter
    Text {
      width: parent.width
      text: tile.title
      elide: Text.ElideRight
      color: Theme.text
      font.family: Theme.fontText
      font.pixelSize: 12
      font.weight: Font.DemiBold
    }
    Text {
      width: parent.width
      text: tile.busy ? "…" : tile.status
      elide: Text.ElideRight
      color: Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 10
    }
  }

  MouseArea {
    id: tap
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: tile.hasRightClick ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
    onClicked: (m) => {
      if (m.button === Qt.RightButton) tile.rightClicked()
      else if (!tile.busy) tile.clicked()
    }
  }

  Rectangle {
    visible: tile.hasMore
    anchors.right: parent.right
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    width: 28; height: 28; radius: 14
    color: moreTap.containsMouse ? Theme.surface : "transparent"
    Icon { anchors.centerIn: parent; name: "chevron_right"; color: moreTap.containsMouse ? Theme.text : Theme.textDim }
    MouseArea { id: moreTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.more() }
  }
}
