import QtQuick
import "../"

// MusicCard — album art, song, artist and the three buttons.
// Shows "Nothing playing" when no music app has a song loaded.
Rectangle {
  id: card

  implicitHeight: 92
  radius: Sizes.cardRadius
  color: Theme.surfaceRaised

  // album art
  Rectangle {
    id: art
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    width: 68; height: 68; radius: 14
    color: Theme.surface
    clip: true
    Image {
      anchors.fill: parent
      source: Media.artUrl
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      visible: status === Image.Ready
    }
    Icon {
      anchors.centerIn: parent
      name: "music_note"
      color: Theme.textDim
      visible: !Media.hasSong || Media.artUrl === ""
    }
  }

  // song + artist
  Column {
    anchors.left: art.right
    anchors.leftMargin: 14
    anchors.right: buttons.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2
    Text {
      width: parent.width
      text: Media.hasSong ? Media.title : "Nothing playing"
      elide: Text.ElideRight
      color: Media.hasSong ? Theme.text : Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 14
      font.weight: Font.DemiBold
    }
    Text {
      width: parent.width
      text: Media.artist
      visible: text !== ""
      elide: Text.ElideRight
      color: Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 12
    }
  }

  // previous / play-pause / next
  Row {
    id: buttons
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4
    opacity: Media.hasSong ? 1 : 0.35

    Repeater {
      model: [
        { icon: "skip_previous", act: () => Media.previous(), big: false },
        { icon: Media.playing ? "pause" : "play_arrow", act: () => Media.toggle(), big: true },
        { icon: "skip_next", act: () => Media.next(), big: false }
      ]
      Rectangle {
        required property var modelData
        width: modelData.big ? 40 : 32
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: modelData.big ? Theme.accent : (tap.containsMouse ? Theme.surface : "transparent")
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
        Icon {
          anchors.centerIn: parent
          name: modelData.icon
          filled: true
          color: modelData.big ? Theme.surface : Theme.text
        }
        MouseArea {
          id: tap
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: modelData.act()
        }
      }
    }
  }
}
