import QtQuick
import Quickshell.Wayland
import "../../"

// Hover — the medium card the pill grows into when you rest the mouse on it.
// Left: big clock (the shared clock from Island.qml slides here) + date.
// Right: what's playing. Bottom: one pill per monitor (MonitorPills); hover
// one and the card grows down to show that monitor's window live.
// (saneAspect: hover shows a little, the big dashboard waits for a click.)
Item {
  id: hoverCard

  property string screenName: ""
  property bool showing: false
  // Extra height the card grows by while peeking at a window.
  readonly property int extra: peek.open ? peek.height + 12 : 0

  // ── Left: date under the clock ────────────────
  Text {
    x: 20
    y: 50
    text: Time.dateLong
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 11
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

  // ── Bottom: one pill per monitor ──────────────
  // Fixed spot (the card grows below it), so the pills never move out from
  // under the mouse when the peek opens.
  MonitorPills {
    id: pills
    active: hoverCard.showing
    anchors.horizontalCenter: parent.horizontalCenter
    y: Sizes.hoverHeight - height - 10
    z: 2
  }

  // ── Peek: the window on the hovered pill's monitor, live ──
  Item {
    id: peek
    readonly property string mon: hoverCard.showing ? pills.peekMonitor : ""
    readonly property var win: mon ? pills.windowOn(mon) : null
    readonly property bool open: mon !== ""
    x: 16
    y: Sizes.hoverHeight + 2
    width: parent.width - 32
    height: 168
    opacity: open ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }

    Rectangle {
      id: frame
      width: parent.width
      height: 140
      radius: 12
      color: Theme.surfaceRaised
      clip: true
      ScreencopyView {
        id: shot
        anchors.centerIn: parent
        captureSource: peek.open && peek.win && peek.win.wayland ? peek.win.wayland : null
        live: true
        // keep the window's shape inside the frame
        readonly property real aspect: sourceSize.height > 0 ? sourceSize.width / sourceSize.height : 16 / 9
        width: Math.min(frame.width, frame.height * aspect)
        height: width / aspect
      }
      Text {
        anchors.centerIn: parent
        visible: !peek.win
        text: "Nothing open here"
        color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
      }
    }
    Text {
      anchors.top: frame.bottom
      anchors.topMargin: 6
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      readonly property var ipc: peek.win ? (peek.win.lastIpcObject || {}) : {}
      text: !peek.win ? peek.mon
          : (ipc.class ? ipc.class + "  ·  " : "") + (peek.win.title || "") + "   (" + peek.mon + ")"
      color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11
    }
  }
}
