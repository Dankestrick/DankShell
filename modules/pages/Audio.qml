import QtQuick
import Quickshell
import "../../"

// Audio — Omarchy's audio panel (omarchy.audio) rebuilt as a DankShell page,
// plus a global EQ. Everything from Omarchy's dropdown: the everything on/off
// switch with its volume name ("Concert hall"), output volume + devices, input
// volume + live mic level + devices, per-app volumes. Then the EQ: on/off,
// presets, 10 bands at ±15 dB, your own presets, and a headphone fix from
// AutoEq for the output that's playing. Logic: services/Sound.qml, Eq.qml.
Column {
  id: page
  property bool showing: false
  signal closeRequested()
  spacing: 10

  onShowingChanged: { Sound.watching = showing; if (showing) Eq.refresh() }
  Component.onCompleted: if (showing) { Sound.watching = true; Eq.refresh() }
  Component.onDestruction: if (showing) Sound.watching = false

  component Head: Text { color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }
  // A device you can pick; the one in use is lit.
  component DeviceRow: Rectangle {
    id: dr
    property string icon: ""
    property string text: ""
    property bool on: false
    signal picked()
    width: parent ? parent.width : 300; height: 34; radius: 10
    color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : drTap.containsMouse ? Theme.surface : "transparent"
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Icon { id: dri; x: 10; anchors.verticalCenter: parent.verticalCenter; name: dr.icon; filled: dr.on; color: dr.on ? Theme.accent : Theme.textDim; font.pixelSize: 18 }
    Text { anchors.left: dri.right; anchors.leftMargin: 10; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: dr.text; color: dr.on ? Theme.text : Theme.text; font.family: Theme.fontText; font.pixelSize: 12; font.weight: dr.on ? Font.DemiBold : Font.Normal }
    MouseArea { id: drTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dr.picked() }
  }
  component Pill: Rectangle {
    id: pb
    property string label: ""
    property string icon: ""
    property bool primary: false
    signal clicked()
    width: pr.implicitWidth + 20; height: 28; radius: 14
    opacity: enabled ? 1 : 0.4
    color: primary ? Theme.accent : tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surface
    Row { id: pr; anchors.centerIn: parent; spacing: 5
      Icon { visible: pb.icon !== ""; name: pb.icon; font.pixelSize: 15; color: pb.primary ? Theme.surface : Theme.text; anchors.verticalCenter: parent.verticalCenter }
      Text { text: pb.label; color: pb.primary ? Theme.surface : Theme.text; font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; enabled: pb.enabled; cursorShape: Qt.PointingHandCursor; onClicked: pb.clicked() }
  }

  // ── Everything on/off ─────────────────────────
  Card {
    width: parent.width
    Item {
      width: parent.width; height: 44
      DeviceHeader {
        width: parent.width - 56
        icon: Sound.outputMuted ? "volume_off" : "volume_up"
        title: "Audio"
        subtitle: Sound.volumeName(Sound.outputVolume, Sound.outputMuted) + (Eq.running ? "  ·  EQ on" : "")
        active: Sound.anyAudible
      }
      // Omarchy's hero switch: mutes (or unmutes) output and mic together.
      Rectangle {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: 44; height: 24; radius: 12
        color: Sound.anyAudible ? Theme.accent : Theme.surface
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
        Rectangle { width: 18; height: 18; radius: 9; anchors.verticalCenter: parent.verticalCenter
          x: Sound.anyAudible ? parent.width - width - 3 : 3; color: Sound.anyAudible ? Theme.surface : Theme.textDim
          Behavior on x { NumberAnimation { duration: Motion.ms(Motion.hover * 1.5); easing.type: Easing.OutCubic } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Sound.toggleAll() }
      }
    }
  }

  // ── Output ────────────────────────────────────
  Card {
    width: parent.width
    Head { text: "Output" }
    SliderRow {
      icon: Sound.outputMuted ? "volume_off" : "volume_up"
      iconClick: true
      live: true
      value: Math.min(1, Sound.outputVolume)
      text: Math.round(Sound.outputVolume * 100) + "%"
      onMoved: (v) => Sound.setOutputVolume(v)
      onIconClicked: Sound.toggleOutputMute()
    }
    Repeater {
      model: Sound.outputs
      DeviceRow { required property var modelData; icon: modelData.icon; text: modelData.label; on: modelData.on; onPicked: Sound.useOutput(modelData) }
    }
  }

  // ── Input ─────────────────────────────────────
  Card {
    width: parent.width
    Head { text: "Input" }
    SliderRow {
      icon: Sound.inputMuted ? "mic_off" : "mic"
      iconClick: true
      live: true
      enabled: Sound.hasInput
      value: Math.min(1, Sound.inputVolume)
      text: Math.round(Sound.inputVolume * 100) + "%"
      onMoved: (v) => Sound.setInputVolume(v)
      onIconClicked: Sound.toggleInputMute()
    }
    // Live mic level
    Rectangle {
      visible: Sound.micLevelKnown
      width: parent.width; height: 6; radius: 3; color: Theme.surface
      Rectangle {
        height: parent.height; radius: 3
        width: parent.width * Math.min(1, Sound.inputMuted ? 0 : Sound.micLevel)
        color: Sound.micLevel > 0.85 ? Theme.urgent : Theme.accent
        Behavior on width { NumberAnimation { duration: 80 } }
      }
    }
    Repeater {
      model: Sound.inputs
      DeviceRow { required property var modelData; icon: "mic"; text: modelData.label; on: modelData.on; onPicked: Sound.useInput(modelData) }
    }
  }

  // ── Apps ──────────────────────────────────────
  Card {
    width: parent.width
    visible: Sound.streams.length > 0
    Head { text: "Apps playing" }
    Repeater {
      model: Sound.streams
      Item {
        required property var modelData
        width: parent.width; height: 30
        Text { id: an; width: 96; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: modelData.label; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11 }
        SliderRow {
          anchors.left: an.right; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          icon: modelData.muted ? "volume_off" : "volume_up"; iconClick: true; live: true
          value: Math.min(1, modelData.volume)
          text: Math.round(modelData.volume * 100) + "%"
          onMoved: (v) => Sound.setStreamVolume(modelData, v)
          onIconClicked: Sound.toggleStreamMute(modelData)
        }
      }
    }
  }

  // ── Equalizer ─────────────────────────────────
  Card {
    id: eqCard
    width: parent.width
    SwitchRow {
      icon: "equalizer"; label: "Equalizer"
      sub: Eq.busy ? "Working…" : Eq.message !== "" ? Eq.message
         : Eq.running ? "On for everything you hear · follows your output" : "Off · turn on to shape the sound of every output"
      checked: Eq.enabled
      disabled: Eq.busy
      onToggled: (v) => Eq.setEnabled(v)
    }
    Head { text: "Presets" }
    Chips {
      model: Eq.presetNames
      current: Eq.presetNames.indexOf(Eq.preset)
      onPicked: (i) => Eq.applyPreset(Eq.presetNames[i])
    }

    // 10 bands, ±15 dB: drag up to boost, down to cut. Double-click puts one back to 0.
    Item {
      id: bands
      width: parent.width
      height: 190
      readonly property real colW: width / 10
      // the 0 dB line
      Rectangle { x: 0; width: parent.width; y: 14 + (bands.height - 44) / 2; height: 1; color: Theme.edge }
      Repeater {
        model: 10
        Item {
          id: band
          required property int index
          readonly property real g: Eq.gains[index]
          x: index * bands.colW
          width: bands.colW; height: bands.height
          Text { anchors.horizontalCenter: parent.horizontalCenter; y: 0; text: (band.g > 0 ? "+" : "") + band.g; color: band.g !== 0 ? Theme.accent : Theme.textDim; font.family: Theme.fontText; font.pixelSize: 9 }
          Item {
            id: track
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14; width: 22; height: bands.height - 44
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 6; height: parent.height; radius: 3; color: Theme.surface }
            // fill from the 0 line to the value
            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter; width: 6; radius: 3
              color: Theme.accent
              readonly property real mid: track.height / 2
              readonly property real pos: mid - band.g / Eq.range * mid
              y: Math.min(mid, pos); height: Math.abs(pos - mid)
            }
            Rectangle {
              width: 16; height: 16; radius: 8; color: Theme.text
              anchors.horizontalCenter: parent.horizontalCenter
              y: track.height / 2 - band.g / Eq.range * track.height / 2 - 8
            }
            MouseArea {
              anchors.fill: parent; anchors.margins: -6
              cursorShape: Qt.PointingHandCursor
              function at(y) { return Math.max(-Eq.range, Math.min(Eq.range, (track.height / 2 - (y - 6)) / (track.height / 2) * Eq.range)) }
              onPressed: (m) => Eq.setGain(band.index, at(m.y), false)
              onPositionChanged: (m) => { if (pressed) Eq.setGain(band.index, at(m.y), false) }
              onReleased: (m) => Eq.setGain(band.index, at(m.y), true)
              onDoubleClicked: Eq.setGain(band.index, 0, true)
              onWheel: (w) => w.accepted = false
            }
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
            readonly property int f: Eq.freqs[band.index]
            text: f >= 1000 ? (f / 1000) + "k" : f
            color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
          }
        }
      }
    }
    Text {
      width: parent.width; wrapMode: Text.WordWrap
      text: "Hearing boost lifts the range where voices and small sounds live. Drag a band up to boost it, down to cut it; double-click puts it back to 0. Boosts are taken off the top first so loud parts don't crackle — turn the volume up after."
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
    }
    Row {
      spacing: 8
      Field { width: 220; placeholderText: "Save as a preset (name, Enter)"; onSubmitted: (t) => Eq.savePreset(t) }
      Pill { visible: Eq.preset in Eq.userPresets; icon: "delete"; label: "Delete " + Eq.preset; onClicked: Eq.deletePreset(Eq.preset) }
    }

    // ── Headphone fix ──
    Rectangle { width: parent.width; height: 1; color: Theme.edge }
    Head { text: "Headphone fix (AutoEq)" }
    Item {
      id: hp
      width: parent.width
      height: hpCol.implicitHeight
      readonly property string out: Sound.realSinkName
      readonly property var outRow: Sound.outputs.find(o => o.name === out) || null
      readonly property var current: Eq.headphonesFor(out)
      property string query: ""
      Column {
        id: hpCol
        width: parent.width
        spacing: 8
        Text {
          width: parent.width; wrapMode: Text.WordWrap
          text: "For " + (hp.outRow ? hp.outRow.label : "this output") + ": "
              + (hp.current ? hp.current.name : "none. Search your headphones to straighten out their sound; your EQ goes on top.")
          color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11
        }
        Row {
          spacing: 8
          Field {
            width: 260
            placeholderText: Eq.indexLoading ? "Loading 8,850 headphones…" : "Search headphones (e.g. Kraken V3 Pro)"
            onSubmitted: (t) => hp.query = t
            Component.onCompleted: Eq.loadIndex()
          }
          Pill { visible: !!hp.current; icon: "close"; label: "Remove fix"; onClicked: Eq.clearHeadphones(hp.out) }
        }
        Repeater {
          model: Eq.search(hp.query)
          DeviceRow {
            required property var modelData
            icon: "headphones"
            text: modelData.name + "  ·  " + modelData.by
            on: !!hp.current && hp.current.name.indexOf(modelData.name) === 0
            onPicked: { Eq.pickHeadphones(modelData, hp.out); hp.query = "" }
          }
        }
      }
    }
  }
}
