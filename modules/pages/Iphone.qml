import QtQuick
import "../../"

// iPhone — OmaiPhone as a dashboard page: the phone at a glance (calls, what
// it's playing, its notifications). Texts open OmaiPhone's own Messages
// window. Every action goes through OmaiPhone's service and its backend;
// nothing new talks to the phone.
Column {
  id: page
  spacing: 10
  signal closeRequested()

  readonly property var service: PluginHost.service("iphone")
  readonly property bool connected: !!(service && service.connected)
  readonly property var phone: service ? service.phone : null
  readonly property var call: service ? service.call : null
  readonly property var caps: service ? service.caps || {} : ({})
  readonly property string callState: service ? service.callState : "idle"
  readonly property bool ringing: !!(service && service.ringing)
  readonly property bool inCall: !!(service && service.inCall)
  readonly property var media: service ? service.media : null
  readonly property var inbox: service ? service.inbox || [] : []
  readonly property int unread: service ? service.unread || 0 : 0

  function run(args, stdin) { if (service) service.run(args, stdin) }
  function elapsed(s) {
    s = Math.max(0, Number(s) || 0)
    const h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60, sec = s % 60
    return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(sec).padStart(2, "0")
  }

  Text {
    visible: !page.service
    width: parent.width
    wrapMode: Text.WordWrap
    text: "iPhone is still running on Omarchy's side. Run `dankshell on` to hand it to DankShell."
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12
  }

  // The phone
  Card {
    visible: !!page.service
    width: parent.width
    DeviceHeader {
      icon: "smartphone"
      title: page.phone && page.phone.name ? page.phone.name : (page.service && page.service.phoneName) || "iPhone"
      subtitle: {
        if (!page.phone) return "Not paired"
        if (!page.connected) return "Out of range or Bluetooth off"
        const b = page.service.battery
        return "Connected" + (b !== null && b !== undefined ? " · " + b + "%" : "")
      }
      active: page.connected
    }
    RoundButton {
      visible: !!page.phone && !page.connected
      anchors.right: parent.right
      icon: "sync"
      onClicked: page.run(["connect"])
    }
  }

  // A call
  Card {
    visible: page.ringing || page.inCall
    width: parent.width
    color: page.ringing ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : Theme.surfaceRaised
    Text {
      width: parent.width
      text: page.call ? (page.call.name || page.call.number || "Unknown caller") : ""
      elide: Text.ElideRight
      color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 17; font.weight: Font.Bold
    }
    Text {
      text: page.ringing ? "Incoming call"
        : page.callState === "active" ? page.elapsed(page.service.elapsed)
        : page.callState === "dialing" || page.callState === "alerting" ? "Calling…" : page.callState
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12
    }
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12
      RoundButton { visible: page.ringing && !!page.caps.canReject; icon: "call_end"; big: true; color: Theme.urgent; onClicked: page.run(["reject"]) }
      RoundButton { visible: page.ringing && !!page.caps.canAnswer; icon: "call"; big: true; onClicked: page.run(["answer"]) }
      RoundButton { visible: !page.ringing && !!page.caps.canMute; icon: page.service && page.service.muted ? "mic_off" : "mic"; on: !!(page.service && page.service.muted); onClicked: page.run(["mute", page.service.muted ? "off" : "on"]) }
      RoundButton { visible: !page.ringing && !!page.caps.canTakeOver; icon: "computer"; onClicked: page.run(["take"]) }
      RoundButton { visible: !page.ringing && !!page.caps.canHangup; icon: "call_end"; big: true; color: Theme.urgent; onClicked: page.run(["hangup"]) }
    }
  }

  // What the phone is playing
  Card {
    visible: !!(page.service && page.service.hasMedia)
    width: parent.width
    Item {
      width: parent.width
      height: 40
      Icon { id: note; anchors.verticalCenter: parent.verticalCenter; name: "music_note"; color: Theme.accent }
      Column {
        anchors.left: note.right; anchors.leftMargin: 10
        anchors.right: ctl.left; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        Text { width: parent.width; text: page.media ? page.media.title || "" : ""; elide: Text.ElideRight; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
        Text { width: parent.width; text: page.media ? [page.media.artist, page.media.player].filter(s => s).join(" · ") : ""; elide: Text.ElideRight; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
      }
      Row {
        id: ctl
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        RoundButton { icon: "skip_previous"; onClicked: page.run(["media", "previous"]) }
        RoundButton { icon: page.media && page.media.playing ? "pause" : "play_arrow"; on: !!(page.media && page.media.playing); onClicked: page.run(["media", "toggle"]) }
        RoundButton { icon: "skip_next"; onClicked: page.run(["media", "next"]) }
      }
    }
  }

  // The phone's notifications
  Card {
    visible: page.connected && page.inbox.length > 0
    width: parent.width
    Item {
      width: parent.width
      height: 24
      Text { anchors.verticalCenter: parent.verticalCenter; text: "Notifications"; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold }
      Text {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        text: "Clear all"; color: Theme.accent; font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold
        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: page.run(["mirror", "dismiss", "all"]) }
      }
    }
    Repeater {
      model: page.inbox.slice(0, 4)
      Item {
        required property var modelData
        width: parent.width
        height: noteCol.implicitHeight
        Column {
          id: noteCol
          anchors.left: parent.left
          anchors.right: x.left
          anchors.rightMargin: 6
          Text {
            width: parent.width
            text: [modelData.app, modelData.title].filter(s => s).join(" · ")
            elide: Text.ElideRight
            color: modelData.important ? Theme.accent : Theme.text
            font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold
          }
          Text {
            width: parent.width
            visible: text !== ""
            text: modelData.message || modelData.subtitle || ""
            wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
            color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
          }
        }
        Icon {
          id: x
          visible: modelData.canDismiss !== false
          anchors.right: parent.right
          anchors.top: parent.top
          name: "close"
          color: Theme.textDim
          MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: page.run(["mirror", "dismiss", String(modelData.uid)]) }
        }
      }
    }
  }

  // Texts and phone audio
  Card {
    visible: !!page.phone
    width: parent.width
    Item {
      width: parent.width
      height: 36
      Icon { id: chat; anchors.verticalCenter: parent.verticalCenter; name: "chat"; filled: page.unread > 0; color: page.unread > 0 ? Theme.accent : Theme.textDim }
      Text {
        anchors.left: chat.right; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
        text: page.unread > 0 ? page.unread + (page.unread === 1 ? " unread text" : " unread texts") : "Texts"
        color: page.unread > 0 ? Theme.accent : Theme.text
        font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold
      }
      RoundButton {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        icon: "open_in_new"
        onClicked: { page.closeRequested(); page.service.openMessages("", "") }
      }
    }
    SwitchRow {
      visible: !!page.caps.canPhoneAudio
      icon: "speaker_phone"; label: "Phone audio on this PC"
      checked: !!(page.service && page.service.phoneAudioOn)
      onToggled: (v) => page.service.setPhoneAudio(v)
    }
  }
}
