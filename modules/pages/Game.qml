import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

// Game — Game Mode, your DualSense, and your installed Steam games (most
// recently played first; scripts/games.py reads Steam's own files).
// Play starts the game through Steam and, if you like, turns Game Mode on.
Column {
  id: page
  property bool showing: false
  spacing: 10

  property var games: []
  readonly property var pad: Status.of("atoslins.dualsense")

  onShowingChanged: if (showing && !lister.running) lister.running = true
  Process {
    id: lister
    command: ["python3", "-I", Qt.resolvedUrl("../../scripts/games.py").toString().replace("file://", "")]
    stdout: StdioCollector { onStreamFinished: { try { page.games = JSON.parse(text) || [] } catch (e) { } } }
  }

  function play(g) {
    if (Settings.v.gameModeOnPlay && !Toggles.gameMode) Toggles.toggleGameMode()
    Quickshell.execDetached(["steam", "steam://rungameid/" + g.appid])
    Popouts.closeCenter()
  }
  function ago(ts) {
    if (!ts) return "Never played"
    const d = Math.floor((Date.now() / 1000 - ts) / 86400)
    return d <= 0 ? "Played today" : d === 1 ? "Played yesterday" : "Played " + d + " days ago"
  }

  // ── Game Mode + controller ────────────────────
  Card {
    width: parent.width
    SwitchRow {
      icon: "sports_esports"; label: "Game Mode"
      sub: Toggles.gameMode ? "On: awake, quiet, no animations, performance" : "Awake, quiet, no animations, performance"
      checked: Toggles.gameMode
      disabled: Toggles.gameBusy
      onToggled: Toggles.toggleGameMode()
    }
    SwitchRow {
      icon: "play_circle"; label: "Turn it on when I hit Play"
      checked: Settings.v.gameModeOnPlay
      onToggled: (v) => Settings.set("gameModeOnPlay", v)
    }
    Rectangle { width: parent.width; height: 1; color: Theme.edge }
    Item {
      width: parent.width
      height: 36
      Icon { id: padIcon; anchors.verticalCenter: parent.verticalCenter; name: "gamepad"; color: page.pad.text !== "" ? Theme.accent : Theme.textDim }
      Text {
        anchors.left: padIcon.right; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
        text: "DualSense" + (page.pad.text !== "" ? "  ·  " + page.pad.text : "  ·  not connected")
        color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold
      }
      Rectangle {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: padText.implicitWidth + 24; height: 28; radius: 14
        color: padTap.containsMouse ? Theme.surface : "transparent"
        border.width: 1; border.color: Theme.edge
        Text { id: padText; anchors.centerIn: parent; text: "Controller settings"; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11 }
        MouseArea { id: padTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Popouts.center = "atoslins.dualsense" }
      }
    }
  }

  // ── Games ─────────────────────────────────────
  Text {
    text: page.games.length ? "Your games" : "Looking for your Steam games…"
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase
  }
  Flow {
    width: parent.width
    spacing: 10
    Repeater {
      model: page.games
      Rectangle {
        id: g
        required property var modelData
        width: (page.width - 10) / 2
        height: width * 0.47 + 46
        radius: Sizes.cardRadius
        color: gTap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surfaceRaised
        clip: true
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
        scale: gTap.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.hover) } }
        Image {
          id: art
          width: parent.width
          height: parent.width * 0.47
          source: g.modelData.art ? "file://" + g.modelData.art : ""
          sourceSize.width: 460
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }
        // play button over the art
        Rectangle {
          anchors.right: parent.right; anchors.rightMargin: 10
          y: art.height - height / 2
          width: 38; height: 38; radius: 19
          color: Theme.accent
          scale: gTap.containsMouse ? 1.1 : 1
          Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.hover); easing.type: Easing.OutBack } }
          Icon { anchors.centerIn: parent; name: "play_arrow"; filled: true; color: Theme.surface; font.pixelSize: 22 }
        }
        Column {
          x: 12
          y: art.height + 8
          width: parent.width - 64
          Text { width: parent.width; text: g.modelData.name; elide: Text.ElideRight; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
          Text { text: page.ago(g.modelData.lastPlayed); color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
        }
        MouseArea { id: gTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.play(g.modelData) }
      }
    }
  }
}
