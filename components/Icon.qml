import QtQuick
import "../"

// Icon — a Material Symbols icon by name. Usage: Icon { name: "wifi" }
// `nudge` moves it sideways a pixel or two when it looks off-center
// (saneAspect's trick: fonts carry their own padding).
Text {
  id: icon

  property string name: ""
  property real nudge: 0
  property bool filled: false

  text: name
  color: Theme.text
  font.family: Theme.iconFont
  font.pixelSize: Theme.iconSize
  font.variableAxes: ({ "FILL": filled || Theme.iconAxes.FILL ? 1 : 0, "wght": Theme.iconAxes.wght, "GRAD": Theme.iconAxes.GRAD, "opsz": Theme.iconSize })
  transform: Translate { x: icon.nudge }
}
