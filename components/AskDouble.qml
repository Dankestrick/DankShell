import QtQuick
import "../"

// AskDouble — "this is already in the other row": Move it here, Keep both,
// or Cancel. Used when adding a widget to the Glance row or the Top row while
// it already sits in the other one, so the island doesn't clutter by accident.
Rectangle {
  id: ask
  property string otherRow: ""        // "Top row" or "Glance row"
  signal move()
  signal both()
  signal cancel()

  width: parent ? parent.width : 300
  implicitHeight: col.implicitHeight + 20
  radius: 12
  color: Theme.surface
  border.width: 1
  border.color: Theme.accent

  component Choice: Rectangle {
    id: c
    property string label: ""
    property bool primary: false
    signal clicked()
    width: t.implicitWidth + 22; height: 26; radius: 13
    color: primary ? Theme.accent : tap.containsMouse ? Theme.surfaceRaised : "transparent"
    border.width: primary ? 0 : 1; border.color: Theme.edge
    Text { id: t; anchors.centerIn: parent; text: c.label; color: c.primary ? Theme.surface : Theme.text; font.family: Theme.fontText; font.pixelSize: 11; font.weight: c.primary ? Font.DemiBold : Font.Normal }
    MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.clicked() }
  }

  Column {
    id: col
    x: 10; y: 10
    width: parent.width - 20
    spacing: 8
    Text {
      width: parent.width; wrapMode: Text.WordWrap
      text: "It's already in the " + ask.otherRow + ". Move it here, or show it in both?"
      color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11
    }
    Row {
      spacing: 6
      Choice { label: "Move it here"; primary: true; onClicked: ask.move() }
      Choice { label: "Keep both"; onClicked: ask.both() }
      Choice { label: "Cancel"; onClicked: ask.cancel() }
    }
  }
}
