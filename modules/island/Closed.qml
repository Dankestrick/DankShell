import QtQuick
import "../../"

// Closed — what the pill shows when nothing is going on: just the clock.
Item {
  id: closed

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Text {
    id: label
    anchors.centerIn: parent
    text: Time.hhmm
    color: Theme.text
    font.family: Theme.fontDisplay
    font.pixelSize: Theme.clockSize
    font.weight: Theme.clockWeight
  }
}
