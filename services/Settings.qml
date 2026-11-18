pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Settings — the numbers you change in the Settings window, saved to
// ~/.config/dankshell/settings.json. config/Sizes.qml, Motion.qml and
// Theme.qml read from here, so a slider moves the island while you drag it.
// The starting values below are the defaults; "Reset" puts them back.
Singleton {
  id: s

  readonly property string dir: Quickshell.env("HOME") + "/.config/dankshell"
  readonly property string path: dir + "/settings.json"
  property bool loaded: false

  // Read a setting: Settings.v.barHeight
  readonly property alias v: adapter

  readonly property var defaults: ({
    // Island
    barHeight: 33, collapsedWidth: 96, gapFromEdge: 11, hoverLift: 14,
    hoverWidth: 440, hoverHeight: 100, dashWidth: 460, radiusExpanded: 31,
    // Motion
    reduceMotion: false, move: 420, fade: 180, bounce: 0.7, openDelay: 350, closeDelay: 300,
    // Look
    pureBlack: true, outline: true, clockSize: 14, iconWeight: 700, iconFilled: false,
    // Dashboard
    hiddenApps: []
  })

  function set(key, value) {
    if (adapter[key] === value) return
    adapter[key] = value
    saveTimer.restart()
  }
  function isDefault(key) { return JSON.stringify(adapter[key]) === JSON.stringify(defaults[key]) }
  function reset(keys) { for (const k of keys) set(k, defaults[k]) }

  // Many slider moves in a row become one write.
  Timer { id: saveTimer; interval: 300; onTriggered: mkdir.running = true }
  Process { id: mkdir; command: ["mkdir", "-p", s.dir]; onExited: file.writeAdapter() }
  // Make the folder at start so the file can be watched before it exists.
  Process { running: true; command: ["mkdir", "-p", s.dir] }

  FileView {
    id: file
    path: s.path
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: s.loaded = true
    onLoadFailed: s.loaded = true

    JsonAdapter {
      id: adapter
      property int barHeight: 33
      property int collapsedWidth: 96
      property int gapFromEdge: 11
      property int hoverLift: 14
      property int hoverWidth: 440
      property int hoverHeight: 100
      property int dashWidth: 460
      property int radiusExpanded: 31

      property bool reduceMotion: false
      property int move: 420
      property int fade: 180
      property real bounce: 0.7
      property int openDelay: 350
      property int closeDelay: 300

      property bool pureBlack: true
      property bool outline: true
      property int clockSize: 14
      property int iconWeight: 700
      property bool iconFilled: false

      property var hiddenApps: []
    }
  }
}
