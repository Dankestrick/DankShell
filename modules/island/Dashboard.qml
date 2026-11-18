import QtQuick
import "../../"

// Dashboard — what the island opens into when you click it.
// The clock isn't in here: it's the same clock from the pill, sliding into
// the top-left corner (see Island.qml). This file leaves room for it.
Item {
  id: dash

  readonly property int headerHeight: 52

  // ── Header: date on the right (clock slides in on the left) ──
  Text {
    anchors.right: parent.right
    anchors.rightMargin: Sizes.dashPadding + 6
    y: 22
    text: Time.dateLong
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 12
  }

  // ── Home page ─────────────────────────────────
  Column {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Sizes.dashPadding
    y: dash.headerHeight + 8
    spacing: 12

    MusicCard { width: parent.width }

    Slider {
      width: parent.width
      icon: Audio.muted || Audio.volume === 0 ? "volume_off" : Audio.volume < 0.5 ? "volume_down" : "volume_up"
      value: Audio.muted ? 0 : Audio.volume
      onMoved: (v) => Audio.setVolume(v)
      onIconClicked: Audio.toggleMute()
    }
  }
}
