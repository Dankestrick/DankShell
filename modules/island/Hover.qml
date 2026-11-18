import QtQuick
import QtQuick.Layouts
import "../../"

// Hover — the medium card the pill grows into when you rest the mouse on it.
// Left: big clock + date. Right: what's playing. Bottom: workspace dots.
// (saneAspect: hover shows a little, the big dashboard waits for a click.)
Item {
  id: hoverCard

  property string screenName: ""

  // ── Left: clock + date ────────────────────────
  Column {
    anchors.left: parent.left
    anchors.leftMargin: 20
    anchors.top: parent.top
    anchors.topMargin: 14
    spacing: 0

    Text {
      text: Time.hhmm
      color: Theme.text
      font.family: Theme.fontDisplay
      font.pixelSize: 26
      font.weight: Font.Bold
    }
    Text {
      text: Time.dateLong
      color: Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 11
    }
  }

  // ── Right: now playing ────────────────────────
  Row {
    id: nowPlaying
    visible: Media.hasSong
    anchors.right: parent.right
    anchors.rightMargin: 16
    anchors.top: parent.top
    anchors.topMargin: 14
    spacing: 10
    layoutDirection: Qt.RightToLeft

    // album art, tap to play/pause
    Rectangle {
      width: 38; height: 38; radius: 10
      color: Theme.surfaceRaised
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
        name: Media.playing ? "pause" : "play_arrow"
        filled: true
        color: "white"
        opacity: artTap.containsMouse || !Media.playing ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
      }
      MouseArea {
        id: artTap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Media.toggle()
      }
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(180, Math.max(titleText.implicitWidth, artistText.implicitWidth))
      Text {
        id: titleText
        width: parent.width
        horizontalAlignment: Text.AlignRight
        text: Media.title
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.fontText
        font.pixelSize: 12
        font.weight: Font.DemiBold
      }
      Text {
        id: artistText
        width: parent.width
        horizontalAlignment: Text.AlignRight
        text: Media.artist
        elide: Text.ElideRight
        color: Theme.textDim
        font.family: Theme.fontText
        font.pixelSize: 11
      }
    }
  }

  // ── Bottom: workspace dots ────────────────────
  WorkspaceDots {
    screenName: hoverCard.screenName
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
  }
}
