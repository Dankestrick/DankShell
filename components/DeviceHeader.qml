import QtQuick
import "../"

// DeviceHeader — icon in a circle, name, status line, and an optional icon on
// the right (a battery). The circle lights up when the device is connected.
Item {
  id: h
  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property bool active: true
  property string trailingIcon: ""
  property color trailingColor: Theme.textDim

  width: parent ? parent.width : 300
  implicitHeight: 44

  Rectangle {
    id: chip
    width: 44; height: 44; radius: 22
    color: h.active ? Theme.accent : Theme.surface
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Icon { anchors.centerIn: parent; name: h.icon; filled: h.active; color: h.active ? Theme.surface : Theme.textDim; font.pixelSize: 22 }
  }
  Column {
    anchors.left: chip.right
    anchors.leftMargin: 12
    anchors.right: trail.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    Text { width: parent.width; text: h.title; elide: Text.ElideRight; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 14; font.weight: Font.DemiBold }
    Text { width: parent.width; visible: text !== ""; text: h.subtitle; elide: Text.ElideRight; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11 }
  }
  Icon {
    id: trail
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    visible: h.trailingIcon !== ""
    name: h.trailingIcon
    filled: true
    color: h.trailingColor
    font.pixelSize: 20
  }
}
