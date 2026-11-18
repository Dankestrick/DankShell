import QtQuick
import "../../"

// Dashboard — what the island opens into when you click it.
// The clock isn't in here: it's the same clock from the pill, sliding into
// the top-left corner (see Island.qml). This file leaves room for it.
//
// Home page, top to bottom: toggles, music, volume, notifications.
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
    id: home
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Sizes.dashPadding
    y: dash.headerHeight + 8
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
        icon: "nightlight"
        title: "Night Light"
        on: Toggles.nightLight
        status: Toggles.nightLight ? "On" : "Off"
        onClicked: Toggles.toggleNightLight()
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

    MusicCard { width: parent.width }

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
        name: Toggles.notifCount > 0 ? "notifications_unread" : "notifications"
        color: Toggles.notifCount > 0 ? Theme.accent : Theme.textDim
      }
      Text {
        anchors.left: bell.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: Toggles.notifCount > 0 ? Toggles.notifCount + (Toggles.notifCount === 1 ? " notification" : " notifications") : "All caught up"
        color: Toggles.notifCount > 0 ? Theme.text : Theme.textDim
        font.family: Theme.fontText
        font.pixelSize: 12
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Toggles.showNotifications()
      }
      Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        visible: Toggles.notifCount > 0
        text: "Clear all"
        color: Theme.accent
        font.family: Theme.fontText
        font.pixelSize: 11
        font.weight: Font.DemiBold
        MouseArea {
          anchors.fill: parent
          anchors.margins: -6
          cursorShape: Qt.PointingHandCursor
          onClicked: Toggles.clearNotifications()
        }
      }
    }
  }

  // The dashboard's real height, so the island can size itself to fit.
  readonly property int contentHeight: home.y + home.implicitHeight + Sizes.dashPadding
}
