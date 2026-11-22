import QtQuick
import Quickshell
import "../../"

// Home — the first dashboard page: toggles, music, volume, notifications.
Column {
  id: home
  spacing: 10

  function open(key) { Popouts.openCenter(key, home.QsWindow.window ? home.QsWindow.window.screen.name : "") }

  // 2 × 2 toggles
  Grid {
    width: parent.width
    columns: 2
    spacing: 10
    readonly property real tileWidth: (width - spacing) / 2

    ToggleTile {
      width: parent.tileWidth
      icon: "vpn_lock"
      title: "VPN"
      on: Toggles.vpn
      busy: Toggles.vpnBusy
      status: Toggles.vpn ? Toggles.vpnName.replace("ProtonVPN ", "") : "Off"
      onClicked: Toggles.toggleVpn()
    }
    ToggleTile {
      width: parent.tileWidth
      icon: "bluetooth"
      title: "Bluetooth"
      on: Toggles.bluetooth
      status: !Toggles.bluetooth ? "Off" : Toggles.btConnected > 0 ? Toggles.btConnected + " connected" : "On"
      onClicked: Toggles.toggleBluetooth()
      hasRightClick: true
      onRightClicked: home.open("bluetooth")   // find + pair new devices
    }
    ToggleTile {
      width: parent.tileWidth
      icon: "sports_esports"
      title: "Game Mode"
      on: Toggles.gameMode
      busy: Toggles.gameBusy
      status: Toggles.gameMode ? "Awake · quiet · fast" : "Off"
      onClicked: Toggles.toggleGameMode()
      hasMore: true
      onMore: home.open("game")
    }
    ToggleTile {
      width: parent.tileWidth
      icon: "do_not_disturb_on"
      title: "Do Not Disturb"
      on: Toggles.dnd
      status: Toggles.dnd ? "Silenced" : "Off"
      onClicked: Toggles.toggleDnd()
    }
  }

  MusicCard { width: parent.width; visible: Media.showing }

  // Volume, with the Audio window button on its left (Volume, EQ, Defaults).
  Item {
    width: parent.width
    height: 30
    Rectangle {
      id: audioBtn
      width: 30; height: 30; radius: 15
      color: audioTap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surfaceRaised
      Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
      Icon { anchors.centerIn: parent; name: "tune"; color: audioTap.containsMouse ? Theme.text : Theme.textDim; font.pixelSize: 17 }
      MouseArea { id: audioTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: home.open("sound") }
    }
    Slider {
      anchors.left: audioBtn.right
      anchors.leftMargin: 8
      anchors.right: parent.right
      height: 30
      icon: Audio.muted || Audio.volume === 0 ? "volume_off" : Audio.volume < 0.5 ? "volume_down" : "volume_up"
      value: Audio.muted ? 0 : Audio.volume
      onMoved: (v) => Audio.setVolume(v)
      onIconClicked: Audio.toggleMute()
    }
  }

  // Notifications row: count, open the list, clear.
  Rectangle {
    width: parent.width
    height: 40
    radius: Sizes.cardRadius
    color: Theme.surfaceRaised

    Icon {
      id: bell
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      name: Notifications.count > 0 ? "notifications_unread" : "notifications"
      color: Notifications.count > 0 ? Theme.accent : Theme.textDim
    }
    Text {
      anchors.left: bell.right
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: Notifications.count > 0 ? Notifications.count + (Notifications.count === 1 ? " notification" : " notifications") : "All caught up"
      color: Notifications.count > 0 ? Theme.text : Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 12
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: home.open("notifications")
    }
    Text {
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      visible: Notifications.count > 0
      text: "Clear all"
      color: Theme.accent
      font.family: Theme.fontText
      font.pixelSize: 11
      font.weight: Font.DemiBold
      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.clearAll()
      }
    }
  }
}
