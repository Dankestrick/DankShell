import QtQuick
import Quickshell
import "../../"

// Epic — the Games window's Epic tab (it shows up once an Epic launcher is
// installed: the official one, Heroic or Legendary; scripts/epic.py finds it).
// Open the launcher, or play an installed Epic game (Game Mode first, like
// the Steam tab, if "Turn it on when I hit Play" is on).
Column {
  id: page
  property bool showing: false
  property var info: ({ launcher: null, games: [] })
  spacing: 10

  function play(g) {
    if (Settings.v.gameModeOnPlay && !Toggles.gameMode) Toggles.toggleGameMode()
    Quickshell.execDetached(g.via === "heroic"
      ? ["xdg-open", "heroic://launch/legendary/" + g.app]
      : ["legendary", "launch", g.app])
    Popouts.closeCenter()
  }
  function openLauncher() {
    if (info.launcher) Quickshell.execDetached(["gtk-launch", info.launcher.desktop])
    Popouts.closeCenter()
  }

  Card {
    width: parent.width
    Item {
      width: parent.width; height: 44
      DeviceHeader {
        width: parent.width - openBtn.width - 12
        icon: "storefront"
        active: !!page.info.launcher
        title: page.info.launcher ? page.info.launcher.name : "Epic Games"
        subtitle: page.info.games.length ? page.info.games.length + " installed" : "No Epic games installed yet"
      }
      Rectangle {
        id: openBtn
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: openRow.implicitWidth + 24; height: 32; radius: 16
        color: openTap.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
        Row {
          id: openRow; anchors.centerIn: parent; spacing: 6
          Icon { width: 16; height: 16; name: "open_in_new"; font.pixelSize: 16; color: Theme.surface; anchors.verticalCenter: parent.verticalCenter }
          Text { text: "Open launcher"; color: Theme.surface; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: openTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.openLauncher() }
      }
    }
  }

  Card {
    width: parent.width
    visible: page.info.games.length > 0
    spacing: 4
    Repeater {
      model: page.info.games
      Rectangle {
        required property var modelData
        width: parent ? parent.width : 300
        height: 40; radius: 12
        color: rowTap.containsMouse ? Theme.surface : "transparent"
        Icon { id: gi; x: 10; anchors.verticalCenter: parent.verticalCenter; name: "sports_esports"; color: Theme.textDim }
        Text {
          anchors.left: gi.right; anchors.leftMargin: 10; anchors.right: playIcon.left; anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
          text: modelData.name; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12
        }
        Icon { id: playIcon; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; name: "play_arrow"; filled: true; color: Theme.accent }
        MouseArea { id: rowTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.play(modelData) }
      }
    }
  }
}
