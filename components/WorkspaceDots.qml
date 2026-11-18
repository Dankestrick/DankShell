import QtQuick
import Quickshell.Hyprland
import "../"

// WorkspaceDots — one dot per workspace on this monitor. The one you're on
// stretches into a pill in the accent color (saneAspect: no slide animation
// on the switch, only the width/color ease). Click a dot to go there.
Row {
  id: dots

  property string screenName: ""
  spacing: 5

  Repeater {
    model: Hyprland.workspaces

    Rectangle {
      required property var modelData
      readonly property bool here: modelData.focused
      readonly property bool mine: modelData.id > 0
        && modelData.monitor && modelData.monitor.name === dots.screenName

      visible: mine
      width: here ? 22 : 7
      height: 7
      radius: height / 2
      color: here ? Theme.accent : Theme.textDim
      anchors.verticalCenter: parent.verticalCenter

      Behavior on width { NumberAnimation { duration: Motion.ms(Motion.hover * 2); easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }

      MouseArea {
        anchors.fill: parent
        anchors.margins: -3
        cursorShape: Qt.PointingHandCursor
        onClicked: parent.modelData.activate()
      }
    }
  }
}
