import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "."

// DankShell — entry point. Omarchy loads this as the bar and hands it the
// properties below. All the real work lives in the folders:
//   config/      sizes, motion, colors   (tweak these)
//   services/    where data comes from
//   components/  small reusable pieces
//   modules/     the island and its pages
Item {
  id: root

  // ── Set by Omarchy (same as the stock bar) ────
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var barWidgetRegistry: null
  property var pluginRegistry: null
  property var barConfig: ({})
  property var shell: null
  property var manifest: null

  // ── What Omarchy reads back ───────────────────
  property bool barHidden: false
  readonly property string position: "top"
  readonly property int barSize: barHidden ? 0 : Sizes.reserved
  readonly property string fontFamily: Theme.fontText
  readonly property var screenBarSizes: ({})

  // Bar widgets (your plugins) get hosted in a later phase. Until then these
  // answer "nothing open" so the rest of the shell stays happy.
  function summonBarWidget(id) { return false }
  function hideBarWidget(id) { return false }
  function isBarWidgetOpen(id) { return false }
  function panelWidgetIdAt(section, index) { return "" }
  function debugBarGeometry() { return ({}) }
  function cycleBackground() { }

  // Omarchy's "toggle bar" writes this flag file; follow it like the stock bar.
  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/toggles/bar-off"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.barHidden = true
    onLoadFailed: root.barHidden = false
  }

  // One island per monitor.
  Variants {
    model: Quickshell.screens
    Island { hidden: root.barHidden }
  }
}
