import QtQuick
import "../"

// RoundButton — a round icon button. `big` = the main one (accent filled),
// `on` = a lit toggle (like Pandora's heart).
Rectangle {
  id: btn

  property string icon: ""
  property bool big: false
  property bool on: false
  signal clicked()

  width: big ? 46 : 36
  height: width
  radius: width / 2
  opacity: enabled ? 1 : 0.35
  color: big || on ? Theme.accent : tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.8) : Theme.surface
  Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }

  Icon {
    anchors.centerIn: parent
    name: btn.icon
    filled: btn.big || btn.on
    color: btn.big || btn.on ? Theme.surface : Theme.text
    font.pixelSize: btn.big ? 22 : 18
  }
  MouseArea {
    id: tap
    anchors.fill: parent
    hoverEnabled: true
    enabled: btn.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: btn.clicked()
  }
}
