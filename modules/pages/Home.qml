import QtQuick
import Quickshell
import "../../"

// Home — the first dashboard page: toggles, music, volume, notifications.
Column {
  id: home
  spacing: 10

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
      onMore: Popouts.openCenter("game", home.QsWindow.window ? home.QsWindow.window.screen.name : "")
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

  Slider {
    width: parent.width
    icon: Audio.muted || Audio.volume === 0 ? "volume_off" : Audio.volume < 0.5 ? "volume_down" : "volume_up"
    value: Audio.muted ? 0 : Audio.volume
    onMoved: (v) => Audio.setVolume(v)
    onIconClicked: Audio.toggleMute()
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
      onClicked: Popouts.openCenter("notifications", home.QsWindow.window ? home.QsWindow.window.screen.name : "")
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
