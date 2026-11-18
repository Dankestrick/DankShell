import QtQuick
import "../../"

// Pandora — OmaPandora's player as a dashboard page. Everything comes from
// OmaPandora's own service (PluginHost runs it); this file is only the look.
Column {
  id: page
  spacing: 10
  signal closeRequested()

  readonly property var service: PluginHost.service("pandora")
  readonly property bool running: service !== null
  readonly property bool connected: !!(service && service.connected)
  readonly property bool hasMedia: !!(service && service.hasMedia)
  readonly property bool playing: !!(service && service.playing)

  // While the page is showing, the service updates faster. (Starting Pithos
  // is only the power button's job, so opening the page never starts music.)
  property bool showing: false
  onShowingChanged: if (service) service.uiVisible = showing
  onServiceChanged: if (service) service.uiVisible = showing

  function clock(s) {
    s = Math.max(0, Math.floor(Number(s) || 0))
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
  }

  // ── Not handed over yet ───────────────────────
  Text {
    visible: !page.running
    width: parent.width
    wrapMode: Text.WordWrap
    text: "Pandora is still running on Omarchy's side. Run `dankshell on` to hand it to DankShell."
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 12
  }

  // ── Now playing ───────────────────────────────
  Rectangle {
    visible: page.running
    width: parent.width
    height: nowCol.implicitHeight + 28
    radius: Sizes.cardRadius
    color: Theme.surfaceRaised

    Column {
      id: nowCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 14
      spacing: 12

      Row {
        width: parent.width
        spacing: 14

        Rectangle {
          id: artBox
          width: 84; height: 84; radius: 16
          color: Theme.surface
          clip: true
          Image {
            id: art
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            // Only Pithos's own cached file, never fetched from the internet.
            readonly property string url: page.service ? String(page.service.artUrl || "") : ""
            source: /^file:\/\//i.test(url) ? url : ""
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
          }
          Icon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            name: "radio"
            color: Theme.textDim
          }
        }

        Column {
          width: parent.width - artBox.width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          spacing: 3
          Text {
            width: parent.width
            text: !page.connected ? "Pandora is off" : page.hasMedia ? page.service.title : "Nothing playing"
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.fontText
            font.pixelSize: 15
            font.weight: Font.DemiBold
          }
          Text {
            width: parent.width
            visible: text !== ""
            text: !page.connected ? "Tap the power button to start it"
              : page.hasMedia ? [page.service.artist, page.service.album].filter(s => s).join(" · ") : ""
            elide: Text.ElideRight
            color: Theme.textDim
            font.family: Theme.fontText
            font.pixelSize: 12
          }
          Row {
            visible: page.connected && page.service.stationName !== ""
            spacing: 5
            Icon { name: "cell_tower"; color: Theme.accent; font.pixelSize: 14 }
            Text {
              text: page.service ? page.service.stationName : ""
              color: Theme.accent
              font.family: Theme.fontText
              font.pixelSize: 11
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }

      // Where the song is (Pandora can't skip around in a song).
      Column {
        width: parent.width
        visible: page.hasMedia && page.service.lengthSeconds > 0
        spacing: 3
        Rectangle {
          width: parent.width
          height: 4
          radius: 2
          color: Theme.surface
          Rectangle {
            height: parent.height
            radius: 2
            color: Theme.accent
            width: page.service && page.service.lengthSeconds > 0
              ? parent.width * Math.min(1, page.service.positionSeconds / page.service.lengthSeconds) : 0
            Behavior on width { NumberAnimation { duration: 1000 } }
          }
        }
        Item {
          width: parent.width
          height: posText.implicitHeight
          Text { id: posText; text: page.clock(page.service ? page.service.positionSeconds : 0); color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
          Text { anchors.right: parent.right; text: page.clock(page.service ? page.service.lengthSeconds : 0); color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
        }
      }

      // Thumbs down · love · play · next · tired of it
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: page.connected
        spacing: 10
        RoundButton { icon: "thumb_down"; enabled: page.hasMedia; onClicked: page.service.ban() }
        RoundButton { icon: "favorite"; on: !!(page.service && page.service.loved); enabled: page.hasMedia; onClicked: page.service.toggleLove() }
        RoundButton { icon: page.playing ? "pause" : "play_arrow"; big: true; onClicked: page.service.togglePlayback() }
        RoundButton { icon: "skip_next"; enabled: !!(page.service && page.service.canGoNext); onClicked: page.service.next() }
        RoundButton { icon: "bedtime"; enabled: page.hasMedia; onClicked: page.service.tired() }
      }

      // Off: start Pithos and play (what OmaPandora's mini player does).
      RoundButton {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !page.connected
        icon: "power_settings_new"
        big: true
        onClicked: page.service.setUiVisible("dankshell", true)
      }
    }
  }

  // ── Pandora's own volume ──────────────────────
  Slider {
    visible: page.connected
    width: parent.width
    icon: page.service && page.service.volume <= 0 ? "volume_off" : "volume_up"
    value: page.service ? page.service.volume : 0
    onMoved: (v) => page.service.setVolume(v)
  }

  // ── Pinned stations ───────────────────────────
  Flow {
    width: parent.width
    visible: page.connected && stations.count > 0
    spacing: 6
    Repeater {
      id: stations
      model: page.service ? page.service.pinnedStations : []
      Rectangle {
        required property var modelData
        readonly property bool current: page.service && String(page.service.stationPath) === String(modelData.path)
        width: chipText.implicitWidth + 24
        height: 28
        radius: 14
        color: current ? Theme.accent : Theme.surfaceRaised
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
        Text {
          id: chipText
          anchors.centerIn: parent
          text: modelData.name
          color: parent.current ? Theme.surface : Theme.text
          font.family: Theme.fontText
          font.pixelSize: 11
          font.weight: parent.current ? Font.DemiBold : Font.Normal
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: page.service.activateStation(modelData.path)
        }
      }
    }
  }

  // ── Open the full player ──────────────────────
  Text {
    visible: page.connected && !!PluginHost.hosted("pandora") && !!PluginHost.hosted("pandora").panel
    anchors.right: parent.right
    text: "Full player  ↗"
    color: Theme.accent
    font.family: Theme.fontText
    font.pixelSize: 11
    font.weight: Font.DemiBold
    MouseArea {
      anchors.fill: parent
      anchors.margins: -6
      cursorShape: Qt.PointingHandCursor
      onClicked: { page.closeRequested(); page.service.openFullPlayer() }
    }
  }
}
