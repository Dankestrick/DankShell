import QtQuick
import QtMultimedia as MM
import Quickshell
import "../../"

// Camera — your webcam (see services/Webcam.qml). Live picture while this page is
// showing (it lets go of the camera when you leave, so calls can use it),
// every control as a slider or switch, saved looks, and Open big (mpv).
// Talks to the camera through services/Webcam.qml. The DSLR webcam plugin
// (Canon) is separate and never touched here.
Column {
  id: page
  property bool showing: false
  spacing: 10

  onShowingChanged: if (showing) Webcam.refresh()
  Component.onCompleted: { if (showing) Webcam.refresh(); if (live) startDelay.restart() }

  // ── Live preview (QtMultimedia) ───────────────
  MM.MediaDevices { id: devs }
  readonly property var dev: {
    const list = devs.videoInputs
    for (let i = 0; i < list.length; i++)
      if (Webcam.name !== "" && String(list[i].description).indexOf(Webcam.name) === 0) return list[i]
    return null
  }
  // 1280×720 is plenty for the page; pick the fastest one.
  function previewFormat(d) {
    let best = null
    const fs = d ? d.videoFormats : []
    for (let i = 0; i < fs.length; i++) {
      const f = fs[i]
      if (f.resolution.width === 1280 && f.resolution.height === 720 && (!best || f.maxFrameRate > best.maxFrameRate)) best = f
    }
    return best
  }
  readonly property bool live: showing && Webcam.present && dev !== null && !Webcam.bigOpen
  // Start a moment after the page shows, once the device and format are set,
  // so the camera opens once (switching device while open reads as "in use").
  property bool started: false
  onLiveChanged: { if (live) startDelay.restart(); else { startDelay.stop(); started = false } }
  Timer { id: startDelay; interval: 250; onTriggered: page.started = page.live }
  // The camera only exists while the preview runs: a stopped Camera still
  // holds /dev/video, so Open big's mpv couldn't open it (2026-11-20).
  readonly property bool camError: !!camLoader.item && camLoader.item.error !== MM.Camera.NoError
  Loader {
    id: camLoader
    visible: false        // takes no room in the page
    active: page.started
    sourceComponent: MM.CaptureSession {
      readonly property int error: cam.error
      camera: MM.Camera {
        id: cam
        cameraDevice: page.dev !== null ? page.dev : devs.defaultVideoInput
        cameraFormat: page.previewFormat(page.dev)
        active: true
        onErrorOccurred: (err, msg) => console.warn("DankShell camera:", err, msg)
      }
      videoOutput: out
    }
  }

  // ── Small pieces ──────────────────────────────
  component SectionTitle: Text {
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
    font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase
  }
  component Btn: Rectangle {
    id: b
    property string label: ""
    property string icon: ""
    property bool primary: false
    signal clicked()
    width: row.implicitWidth + 24; height: 30; radius: 15
    opacity: enabled ? 1 : 0.4
    color: primary ? Theme.accent : tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.8) : Theme.surface
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Row {
      id: row
      anchors.centerIn: parent
      spacing: 6
      Icon { visible: b.icon !== ""; name: b.icon; font.pixelSize: 16; color: b.primary ? Theme.surface : Theme.text; anchors.verticalCenter: parent.verticalCenter }
      Text { text: b.label; color: b.primary ? Theme.surface : Theme.text; font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; enabled: b.enabled; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
  }
  // A label, then a slider for one camera control.
  component Ctl: Item {
    id: k
    property string ctrl: ""
    property string label: ""
    property string icon: "tune"
    property var fmt: (v) => String(v)
    readonly property var info: Webcam.ctrls[ctrl] || null
    visible: info !== null
    width: parent ? parent.width : 300
    height: visible ? 30 : 0
    Text {
      id: lab
      width: 84
      anchors.verticalCenter: parent.verticalCenter
      text: k.label; elide: Text.ElideRight
      color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11
    }
    SliderRow {
      anchors.left: lab.right
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      icon: k.icon
      live: true
      enabled: !!k.info && !k.info.inactive
      readonly property real span: k.info ? Math.max(1, k.info.max - k.info.min) : 1
      value: k.info ? (k.info.value - k.info.min) / span : 0
      text: k.info ? k.fmt(k.info.value) : ""
      onMoved: (f) => {
        const st = Math.max(1, k.info.step || 1)
        const v = k.info.min + Math.round(f * span / st) * st
        if (v !== k.info.value) Webcam.set(k.ctrl, v)
      }
    }
  }

  // ── Header + preview ──────────────────────────
  Card {
    width: parent.width
    DeviceHeader {
      icon: "videocam"
      title: Webcam.name || "Camera"
      subtitle: !Webcam.present ? "Not plugged in"
              : (Webcam.bigOpen ? "Open in the big window" : Webcam.device)
                + (Webcam.activeLook ? "  ·  look: " + Webcam.activeLook : "")
      active: Webcam.present
    }
    Rectangle {
      width: parent.width
      height: width * 9 / 16
      radius: 10
      color: "black"
      clip: true
      MM.VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: MM.VideoOutput.PreserveAspectCrop
        visible: page.started
      }
      Text {
        anchors.centerIn: parent
        visible: !page.started || page.camError
        text: !Webcam.present ? "Plug in the camera"
            : Webcam.bigOpen ? "Showing in the big window"
            : page.camError ? "Camera busy (a call or another app has it)"
            : ""
        color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12
      }
    }
    Row {
      spacing: 8
      Btn {
        icon: Webcam.bigOpen ? "close_fullscreen" : "open_in_full"
        label: Webcam.bigOpen ? "Close big" : "Open big"
        primary: true
        enabled: Webcam.present
        onClicked: Webcam.bigOpen ? Webcam.closeBig() : Webcam.openBig()
      }
      Btn { icon: "restart_alt"; label: "Reset to defaults"; enabled: Webcam.present; onClicked: Webcam.resetDefaults() }
    }
    SectionTitle { text: "Big window size" }
    Chips {
      readonly property var sizes: ["2560x1440", "1920x1080", "1280x720"]
      model: ["2K", "1080p", "720p"]
      current: sizes.indexOf(Webcam.bigSize)
      onPicked: (i) => Webcam.setBigSize(sizes[i])
    }
  }

  // ── Looks ─────────────────────────────────────
  Card {
    width: parent.width
    visible: Webcam.present
    SectionTitle { text: "Looks" }
    Text {
      visible: Webcam.lookNames.length === 0
      width: parent.width; wrapMode: Text.WordWrap
      text: "Set it up how you like, then save it as a look. The picked look goes back on whenever the camera is plugged in."
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
    }
    Chips {
      visible: Webcam.lookNames.length > 0
      model: Webcam.lookNames
      current: Webcam.lookNames.indexOf(Webcam.activeLook)
      onPicked: (i) => Webcam.applyLook(Webcam.lookNames[i])
    }
    Row {
      spacing: 8
      visible: Webcam.activeLook !== ""
      Btn { icon: "save"; label: "Save to " + Webcam.activeLook; onClicked: Webcam.saveLook(Webcam.activeLook) }
      Btn { icon: "delete"; label: "Delete " + Webcam.activeLook; onClicked: Webcam.deleteLook(Webcam.activeLook) }
    }
    Field { placeholderText: "Save as a new look (type a name, Enter)"; onSubmitted: (t) => Webcam.saveLook(t) }
  }

  // ── Picture ───────────────────────────────────
  Card {
    width: parent.width
    visible: Webcam.present
    SectionTitle { text: "Picture" }
    Ctl { ctrl: "brightness"; label: "Brightness"; icon: "light_mode" }
    Ctl { ctrl: "contrast"; label: "Contrast"; icon: "contrast" }
    Ctl { ctrl: "saturation"; label: "Color"; icon: "palette" }
    Ctl { ctrl: "sharpness"; label: "Sharpness"; icon: "deblur" }
    Ctl { ctrl: "gamma"; label: "Gamma"; icon: "exposure" }
    Ctl { ctrl: "hue"; label: "Hue"; icon: "colorize" }
  }

  // ── Light ─────────────────────────────────────
  Card {
    width: parent.width
    visible: Webcam.present
    SectionTitle { text: "Light" }
    SwitchRow {
      icon: "wb_auto"; label: "Auto white balance"
      sub: Webcam.autoWhite ? "Turn off to set the color temperature yourself" : ""
      checked: Webcam.autoWhite
      onToggled: (v) => Webcam.set("white_balance_automatic", v ? 1 : 0)
    }
    Ctl { ctrl: "white_balance_temperature"; label: "Temperature"; icon: "thermostat"; fmt: (v) => v + "K" }
    SwitchRow {
      icon: "brightness_auto"; label: "Auto exposure"
      sub: Webcam.exposureStuck ? "This camera only turns auto back on when you replug it"
         : Webcam.autoExposure ? "Turn off to set it yourself (auto comes back on a replug)" : ""
      checked: Webcam.autoExposure
      onToggled: (v) => Webcam.setAutoExposure(v)
    }
    Ctl { ctrl: "exposure_time_absolute"; label: "Exposure"; icon: "shutter_speed"; fmt: (v) => (v / 10).toFixed(v < 100 ? 1 : 0) + " ms" }
    SectionTitle { text: "Anti-flicker" }
    Chips {
      model: ["Off", "50 Hz", "60 Hz"]
      current: Webcam.val("power_line_frequency")
      onPicked: (i) => Webcam.set("power_line_frequency", i)
    }
  }

  // ── Focus and framing ─────────────────────────
  Card {
    width: parent.width
    visible: Webcam.present
    SectionTitle { text: "Focus and framing" }
    SwitchRow {
      icon: "center_focus_strong"; label: "Autofocus"
      checked: Webcam.autoFocus
      onToggled: (v) => Webcam.set("focus_automatic_continuous", v ? 1 : 0)
    }
    Ctl { ctrl: "focus_absolute"; label: "Focus"; icon: "filter_center_focus" }
    Ctl { ctrl: "zoom_absolute"; label: "Zoom"; icon: "zoom_in"; fmt: (v) => (v / 100).toFixed(1) + "×" }
    Ctl { ctrl: "pan_absolute"; label: "Pan"; icon: "swap_horiz"; fmt: (v) => Math.round(v / 3600) + "°" }
    Ctl { ctrl: "tilt_absolute"; label: "Tilt"; icon: "swap_vert"; fmt: (v) => Math.round(v / 3600) + "°" }
  }
}
