import QtQuick
import Quickshell
import "../../"

// Launcher — one game launcher's tab in the Games window (Heroic, Lutris,
// Epic, itch.io, Minecraft...; scripts/launchers.py finds the ones you have).
// Open the launcher, or play a game it has installed. Game Mode comes on
// first, like the Steam tab, if "Turn it on when I hit Play" is on.
Column {
  id: page
  property bool showing: false
  property var info: ({ name: "", app: "", desktop: "", icon: "sports_esports", games: [] })
  spacing: 10

  function play(g) {
    if (Settings.v.gameModeOnPlay && !Toggles.gameMode) Toggles.toggleGameMode()
    Quickshell.execDetached(g.cmd)
    Popouts.closeCenter()
  }
  function openLauncher() {
    Quickshell.execDetached(["gtk-launch", info.desktop])
    Popouts.closeCenter()
  }

  Card {
    width: parent.width
    Item {
      width: parent.width; height: 44
      DeviceHeader {
        width: parent.width - openBtn.width - 12
        icon: page.info.icon || "sports_esports"
        title: page.info.app || page.info.name
        subtitle: page.info.games.length ? page.info.games.length + (page.info.games.length === 1 ? " game" : " games") + " installed"
                : "Open it to add or play games"
      }
      Rectangle {
        id: openBtn
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: openRow.implicitWidth + 24; height: 32; radius: 16
        color: openTap.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
        Row {
          id: openRow; anchors.centerIn: parent; spacing: 6
          Icon { width: 16; height: 16; name: "open_in_new"; font.pixelSize: 16; color: Theme.surface; anchors.verticalCenter: parent.verticalCenter }
          Text { text: "Open " + page.info.name; color: Theme.surface; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
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
          anchors.left: gi.right; anchors.leftMargin: 10; anchors.right: store.left; anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
          text: modelData.name; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12
        }
        // where it's from (Epic, GOG, Amazon, the Lutris runner...)
        Text {
          id: store
          anchors.right: playIcon.left; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
          text: modelData.store || ""; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
        }
        Icon { id: playIcon; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; name: "play_arrow"; filled: true; color: Theme.accent }
        MouseArea { id: rowTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.play(modelData) }
      }
    }
  }
}
