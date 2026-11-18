import QtQuick
import "../"

// Card — a rounded gray box that stacks whatever you put in it.
Rectangle {
  id: card
  default property alias content: col.data
  property int padding: 14
  property int spacing: 10

  implicitHeight: col.implicitHeight + padding * 2
  radius: Sizes.cardRadius
  color: Theme.surfaceRaised

  Column {
    id: col
    x: card.padding
    y: card.padding
    width: card.width - card.padding * 2
    spacing: card.spacing
  }
}
