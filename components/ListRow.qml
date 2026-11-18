import QtQuick
import "../"

// ListRow — one line in a list (a speaker, a Bluetooth device...).
// Icon, name, a small status on the right, and a highlight when it's the
// active one.
Rectangle {
  id: row

  property string icon: ""
  property string title: ""
  property string status: ""
  property bool active: false
  signal clicked()

  implicitHeight: 38
  radius: 12
  color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
       : tap.containsMouse ? Theme.surfaceRaised : "transparent"
  Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }

  Icon {
    id: ic
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    name: row.icon
    filled: row.active
    color: row.active ? Theme.accent : Theme.textDim
  }
  Text {
    anchors.left: ic.right
    anchors.leftMargin: 10
    anchors.right: st.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    text: row.title
    elide: Text.ElideRight
    color: row.active ? Theme.text : Theme.text
    font.family: Theme.fontText
    font.pixelSize: 12
    font.weight: row.active ? Font.DemiBold : Font.Normal
  }
  Text {
    id: st
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    text: row.status
    color: row.active ? Theme.accent : Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 10
  }

  MouseArea {
    id: tap
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: row.clicked()
  }
}
