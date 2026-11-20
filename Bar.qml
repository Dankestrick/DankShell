import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
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

  // Starts the webcam service at login, so a saved camera look goes back on
  // when the camera is plugged in, even before the Camera page is opened.
  readonly property bool webcamPresent: Webcam.present

  // Omarchy asks the bar about its widgets' dropdowns through these.
  // Open a widget's dropdown (Omarchy's `shell summon <id>`, keybinds):
  // opens the dashboard on this monitor, then presses the widget.
  function summonBarWidget(id) {
    const isl = focusedIsland()
    if (!isl) return false
    const w = WidgetHost.live.find(x => x.moduleName === id && x.QsWindow.window === isl)
    if (!WidgetHost.canOpen(w)) return false
    isl.open()
    pressLater.target = w
    pressLater.restart()
    return true
  }
  Connections { target: Popouts; function onSummon(id) { root.summonBarWidget(id) } function onOpenPage(key) { const i = root.focusedIsland(); if (i) i.showPage(key) } }
  Timer {
    id: pressLater
    property var target: null
    interval: 250
    onTriggered: {
      if (target) WidgetHost.openWidget(target)
    }
  }
  function hideBarWidget(id) { if (WidgetHost.active && WidgetHost.activeOwnerId === id) { WidgetHost.closeAll(); return true } return false }
  function isBarWidgetOpen(id) { return WidgetHost.active !== null && WidgetHost.activeOwnerId === id }
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

  // Start the plugin host right away so plugins run even before the
  // dashboard is first opened.
  readonly property var pluginHost: PluginHost

  // Your other bar widgets (webcam, mail, network...) run through WidgetHost.
  Binding { target: WidgetHost; property: "registry"; value: root.barWidgetRegistry }
  Binding { target: WidgetHost; property: "shell"; value: root.shell }

  // One island per monitor.
  Variants {
    id: islands
    model: Quickshell.screens
    Island { hidden: root.barHidden }
  }

  // The Center window (plugins + settings), one per monitor; only the one
  // on the monitor you opened it from shows.
  Variants {
    model: Quickshell.screens
    Center { }
  }

  // The island on the monitor you're using.
  function focusedIsland() {
    const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    for (const i of islands.instances) if (i.modelData.name === name) return i
    return islands.instances.length ? islands.instances[0] : null
  }

  // Commands for keybinds and scripts:
  //   qs ipc -p /usr/share/omarchy/shell call dankshell toggle
  IpcHandler {
    target: "dankshell"
    function toggle(): void { const i = root.focusedIsland(); if (i) { if (i.isOpen) i.state = "closed"; else i.open() } }
    function open(): void { const i = root.focusedIsland(); if (i) i.open() }
    function page(name: string): void { const i = root.focusedIsland(); if (i) i.showPage(name) }
    function themes(): void { const i = root.focusedIsland(); if (i) { if (i.isThemes) i.state = "closed"; else i.showThemes() } }
    function walls(): void { const i = root.focusedIsland(); if (i) { if (i.isWalls) i.state = "closed"; else i.showWalls() } }
    function center(name: string): void {
      // The same key again closes it.
      if (Popouts.center !== "" && (name === "" || Popouts.center === name || name === "@" + Popouts.mode)) { Popouts.closeCenter(); return }
      const i = root.focusedIsland(); if (i) { i.state = "closed"; Popouts.openCenter(name || "@settings", i.modelData.name) }
    }
    function settings(): void { center("@settings") }
    function plugins(): void { center("@plugins") }
    function gamemode(): void { Toggles.toggleGameMode() }
    // The Camera page's Open big / Close big.
    function cameraBig(): void { if (Webcam.bigOpen) Webcam.closeBig(); else Webcam.openBig() }
    // A look inside one widget (for fixing ones that show nothing).
    function widgetInfo(id: string): string {
      return JSON.stringify(WidgetHost.live.filter(w => w.moduleName === id).map(w => {
        const b = WidgetHost.findButton(w)
        let panel = null
        for (const c of (w.data || [])) { try { if (c && c.item && "label" in c.item) panel = c.item } catch (e) { } }
        return { visible: w.visible, w: w.implicitWidth, button: b ? String(b.text) : null, hasBar: !!w.bar,
                 label: panel ? panel.label : null, location: panel ? String(panel.locationQuery) : null,
                 detecting: panel ? panel.detectingLocation : null, report: panel ? !!panel.report : null,
                 slotW: w.parent ? w.parent.implicitWidth : -1, slotHas: w.parent ? w.parent.hasContent : null, holderW: w.parent && w.parent.parent ? w.parent.parent.width : -1,
                 slotVisible: w.parent ? w.parent.visible : null, wVisibleSelf: w.visible }
      }))
    }
    // What the widget strip sees: each widget id and whether it started.
    function widgets(): string {
      const reg = WidgetHost.registry
      return JSON.stringify({ registry: !!reg, registered: reg && reg.widgets ? Object.keys(reg.widgets).length : 0,
        shell: !!WidgetHost.shell, entries: WidgetHost.entries.map(e => e.id + (WidgetHost.componentFor(e.id) ? "" : " (no component)")),
        live: WidgetHost.live.map(w => w.moduleName + " " + Math.round(w.implicitWidth) + "x" + Math.round(w.implicitHeight) + (w.visible ? "" : " hidden")) })
    }
    function close(): void { for (const i of islands.instances) i.state = "closed"; Popouts.closeCenter() }
  }
}
