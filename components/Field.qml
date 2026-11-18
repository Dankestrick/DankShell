import QtQuick
import "../"

// Field — a one-line text box. Press Enter to send what you typed.
Rectangle {
  id: field
  property string placeholderText: ""
  signal submitted(string text)

  width: parent ? parent.width : 300
  implicitHeight: 34
  radius: 12
  color: Theme.surface
  border.width: 1
  border.color: input.activeFocus ? Theme.accent : Theme.edge
  opacity: enabled ? 1 : 0.5

  TextInput {
    id: input
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.text
    font.family: Theme.fontText
    font.pixelSize: 12
    clip: true
    enabled: field.enabled
    selectByMouse: true
    onAccepted: { const t = text.trim(); if (t !== "") { field.submitted(t); text = "" } }
    Keys.onEscapePressed: (e) => { if (text !== "") { text = ""; e.accepted = true } else e.accepted = false }
  }
  Text {
    anchors.fill: input
    verticalAlignment: Text.AlignVCenter
    visible: input.text === "" && !input.activeFocus
    text: field.placeholderText
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 12
  }
}
