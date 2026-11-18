pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// Toggles — the on/off switches on the dashboard's Home page.
// Each one reads its state from the same command Omarchy uses, and flips it
// the same way, so the bar, the menus and DankShell always agree.
// States refresh when the dashboard opens and every few seconds while it's open.
Singleton {
  id: toggles

  property bool watching: false       // Island sets this while a dashboard is open

  // ── VPN (ProtonVPN) ───────────────────────────
  property bool vpn: false
  property string vpnName: ""
  property bool vpnBusy: false
  function toggleVpn() {
    vpnBusy = true
    run(vpn ? ["protonvpn", "disconnect"] : ["protonvpn", "connect"], () => { vpnBusy = false; refresh() })
  }

  // ── Bluetooth ─────────────────────────────────
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool bluetooth: adapter ? adapter.enabled : false
  readonly property int btConnected: {
    if (!adapter) return 0
    let n = 0
    for (const d of adapter.devices.values) if (d.connected) n++
    return n
  }
  function toggleBluetooth() { if (adapter) adapter.enabled = !adapter.enabled }

  // ── Night Light ───────────────────────────────
  property bool nightLight: false
  function toggleNightLight() { nightLight = !nightLight; run(["omarchy", "toggle", "nightlight"], refresh) }

  // ── Do Not Disturb ────────────────────────────
  property bool dnd: false
  function toggleDnd() { dnd = !dnd; run(["omarchy", "toggle", "notification", "silencing"], refresh) }

  // ── Notifications ─────────────────────────────
  property int notifCount: 0
  function clearNotifications() { notifCount = 0; run(["omarchy-shell", "notifications", "dismissAll"], refresh) }
  function showNotifications() { run(["omarchy-shell", "notifications", "showHistory"], null) }

  // ── Reading the states ────────────────────────
  function refresh() { statusProc.running = true }

  Process {
    id: statusProc
    command: ["bash", "-c",
      "echo vpn=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -i '^proton' | grep -i wireguard | head -1 | cut -d: -f1);" +
      "echo night=$(omarchy toggle nightlight --status 2>/dev/null | jq -r .enabled);" +
      "echo dnd=$(omarchy-shell notifications isDnd 2>/dev/null);" +
      "echo count=$(omarchy-shell notifications count 2>/dev/null)"]
    stdout: StdioCollector {
      onStreamFinished: {
        for (const line of text.split("\n")) {
          const i = line.indexOf("=")
          if (i < 0) continue
          const key = line.slice(0, i), val = line.slice(i + 1).trim()
          if (key === "vpn") { toggles.vpnName = val; toggles.vpn = val !== "" }
          else if (key === "night") toggles.nightLight = val === "true"
          else if (key === "dnd") toggles.dnd = val === "true" || val === "on" || val === "1"
          else if (key === "count") toggles.notifCount = parseInt(val) || 0
        }
      }
    }
  }

  Timer { interval: 3000; repeat: true; running: toggles.watching; triggeredOnStart: true; onTriggered: toggles.refresh() }

  // ── Running a command, then calling back ──────
  function run(cmd, done) {
    const p = runner.createObject(toggles, { command: cmd })
    p.exited.connect(() => { if (done) done(); p.destroy() })
    p.running = true
  }
  Component { id: runner; Process { } }
}
