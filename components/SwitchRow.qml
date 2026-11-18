import QtQuick
import "../"

// SwitchRow — icon, label (with a small line under it) and an on/off switch.
Item {
  id: row
  property string icon: ""
  property string label: ""
  property string sub: ""
  property bool checked: false
  property bool disabled: false
  signal toggled(bool value)

  width: parent ? parent.width : 300
  implicitHeight: 36
  opacity: disabled ? 0.45 : 1

  Icon { id: ic; anchors.verticalCenter: parent.verticalCenter; name: row.icon; color: row.checked ? Theme.accent : Theme.textDim }
  Column {
    anchors.left: ic.right
    anchors.leftMargin: 10
    anchors.right: sw.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    Text { width: parent.width; text: row.label; elide: Text.ElideRight; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
    Text { width: parent.width; visible: text !== ""; text: row.sub; elide: Text.ElideRight; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
  }
  Rectangle {
    id: sw
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 40; height: 22; radius: 11
    color: row.checked ? Theme.accent : Theme.surface
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Rectangle {
      width: 16; height: 16; radius: 8
      anchors.verticalCenter: parent.verticalCenter
      x: row.checked ? parent.width - width - 3 : 3
      color: row.checked ? Theme.surface : Theme.textDim
      Behavior on x { NumberAnimation { duration: Motion.ms(Motion.hover * 1.5); easing.type: Easing.OutCubic } }
    }
  }
  MouseArea {
    anchors.fill: parent
    enabled: !row.disabled
    cursorShape: Qt.PointingHandCursor
    onClicked: row.toggled(!row.checked)
  }
}
