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

  // Games with an r2modman profile play modded (the same launch r2modman's
  // "Start modded" does); GTA plays with mods (scripts/gta-modded: VPN on,
  // GTA, then mods once Rockstar shows up); `vanilla` skips the mods.
  function play(g, vanilla) {
    if (Settings.v.gameModeOnPlay && !Toggles.gameMode) Toggles.toggleGameMode()
    const mods = g.mods || []
    if (!vanilla && g.launcher) Quickshell.execDetached([g.launcher.script])
    else if (!vanilla && mods.length) Quickshell.execDetached(["steam", "-applaunch", g.appid].concat(mods[0].args))
    else Quickshell.execDetached(["steam", "steam://rungameid/" + g.appid])
    Popouts.closeCenter()
  }
  // What the big Play button does for a game: modded unless you picked Vanilla.
  function isModded(g) { return (g.mods || []).length > 0 || !!g.launcher }
  function modeOf(g) {
    const m = (Settings.v.gameDefaults || {})[g.appid]
    return m === "vanilla" || !isModded(g) ? "vanilla" : "mod"
  }
  function setDefault(g, mode) {
    const d = Object.assign({}, Settings.v.gameDefaults || {}); d[g.appid] = mode
    Settings.set("gameDefaults", d)
  }
  readonly property bool anyModded: games.some(g => isModded(g))
  function openModManager() { Quickshell.execDetached(["r2modman"]); Popouts.closeCenter() }

  // A small outlined button on a game card.
  component CardButton: Rectangle {
    id: cb
    property string label: ""
    property string icon: ""
    property bool lit: false        // this is what the big Play button does
    property bool canDefault: true  // right-click makes it the default
    signal clicked()
    signal makeDefault()
    width: cbRow.implicitWidth + 18; height: 24; radius: 12
    color: lit ? Theme.accent : cbTap.containsMouse ? Theme.surface : "transparent"
    border.width: lit ? 0 : 1; border.color: Theme.edge
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Row {
      id: cbRow
      anchors.centerIn: parent
      spacing: 4
      Icon { visible: cb.icon !== ""; name: cb.icon; filled: cb.lit; font.pixelSize: 14; color: cb.lit ? Theme.surface : Theme.text; anchors.verticalCenter: parent.verticalCenter }
      Text { text: cb.label; color: cb.lit ? Theme.surface : Theme.text; font.family: Theme.fontText; font.pixelSize: 10; font.weight: cb.lit ? Font.DemiBold : Font.Normal; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea {
      id: cbTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onContainsMouseChanged: Popouts.rightClickHere = containsMouse && cb.canDefault
      Component.onDestruction: if (containsMouse) Popouts.rightClickHere = false
      onClicked: (m) => { if (m.button === Qt.RightButton) { if (cb.canDefault) cb.makeDefault() } else cb.clicked() }
    }
  }
  function ago(ts) {
    if (!ts) return "Never played"
    const d = Math.floor((Date.now() / 1000 - ts) / 86400)
    return d <= 0 ? "Played today" : d === 1 ? "Played yesterday" : "Played " + d + " days ago"
  }

  // ── Steam itself (same card as the other launcher tabs) ──
  Card {
    width: parent.width
    Item {
      width: parent.width; height: 44
      DeviceHeader {
        width: parent.width - steamBtn.width - 12
        icon: "joystick"
        title: "Steam"
        subtitle: page.games.length ? page.games.length + (page.games.length === 1 ? " game" : " games") + " installed" : "Looking for your games…"
      }
      Rectangle {
        id: steamBtn
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: steamRow.implicitWidth + 24; height: 32; radius: 16
        color: steamTap.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
        Row {
          id: steamRow; anchors.centerIn: parent; spacing: 6
          Icon { width: 16; height: 16; name: "open_in_new"; font.pixelSize: 16; color: Theme.surface; anchors.verticalCenter: parent.verticalCenter }
          Text { text: "Open Steam"; color: Theme.surface; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: steamTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["steam", "steam://open/games"]); Popouts.closeCenter() } }
      }
    }
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
        MouseArea { id: padTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Popouts.center = "dualsense" }
      }
    }
  }

  // ── Games ─────────────────────────────────────
  Text {
    text: page.games.length ? "Your games  ·  the lit button is what Play does, right-click a button to change it" : "Looking for your Steam games…"
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
        readonly property bool modded: page.isModded(modelData)
        readonly property string mode: page.modeOf(modelData)
        height: width * 0.47 + (page.anyModded ? 80 : 46)
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
          Text {
            text: page.ago(g.modelData.lastPlayed)
            color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
          }
        }
        MouseArea { id: gTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.play(g.modelData, g.mode === "vanilla") }
        // Launch buttons, the same on every card; the lit one is what Play does.
        Row {
          visible: page.anyModded
          x: 12
          anchors.bottom: parent.bottom; anchors.bottomMargin: 10
          spacing: 6
          CardButton {
            visible: g.modded
            icon: "rocket_launch"
            label: g.modelData.launcher ? g.modelData.launcher.name : "Modded"
            lit: g.mode === "mod"
            onClicked: page.play(g.modelData, false)
            onMakeDefault: page.setDefault(g.modelData, "mod")
          }
          CardButton {
            icon: "play_arrow"; label: "Vanilla"
            lit: g.mode === "vanilla"
            canDefault: g.modded
            onClicked: page.play(g.modelData, true)
            onMakeDefault: page.setDefault(g.modelData, "vanilla")
          }
          CardButton { visible: (g.modelData.mods || []).length > 0; icon: "extension"; label: "Mods"; canDefault: false; onClicked: page.openModManager() }
        }
      }
    }
  }
}
