pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// DualSense — talks to your controller for the DualSense page, through the
// DualSense plugin's own helper (atoslins.dualsense, MIT: bin/dualsense-ctl)
// and its saved profile (~/.config/dualsense/profile.json), so a change here
// is the same change the plugin would make. The plugin itself keeps running
// out of sight for battery alerts and re-applying the profile on connect.
Singleton {
  id: ds

  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/atoslins.dualsense/"
  readonly property string helper: pluginDir + "bin/dualsense-ctl"
  readonly property string profileFile: Quickshell.env("HOME") + "/.config/dualsense/profile.json"
  readonly property string accentHex: String(Color.accent).substring(0, 7)

  property bool watching: false       // the page is open: poll every 2 s
  property var controllers: []
  property var profile: ({})
  property bool busy: false

  readonly property var device: controllers.length ? controllers[0] : null
  readonly property bool connected: device !== null
  readonly property bool canControl: connected && !!device.access && device.access.hidraw === true
  readonly property bool bluetooth: connected && device.bus === "bluetooth"
  readonly property int capacity: connected && device.battery && device.battery.capacity !== null ? device.battery.capacity : -1
  readonly property string batteryStatus: connected && device.battery ? String(device.battery.status) : "unknown"
  readonly property bool charging: batteryStatus === "charging"
  readonly property bool full: batteryStatus === "full"

  readonly property var lightbar: profile.lightbar || ({ enabled: true, color: "#1e64ff", brightness: 70, followTheme: false })
  readonly property var player: profile.player || ({ leds: 1, fade: false, brightness: "high" })
  readonly property var triggers: profile.triggers || ({ left: { effect: "off", strength: 5 }, right: { effect: "off", strength: 5 } })
  readonly property var audio: profile.audio || ({ micMuted: false, micLed: "auto", speaker: null, volume: null, micVolume: null })
  readonly property var motors: profile.motors || ({ rumble: 0, trigger: 0 })
  readonly property string lightbarHex: lightbar.followTheme ? accentHex : String(lightbar.color || "#1e64ff")
  readonly property int ledPattern: [0, 4, 10, 21, 27, 31, 17, 14][Math.max(0, Math.min(7, Number(player.leds)))]

  // ── Reading ───────────────────────────────────
  function refresh() { if (!poll.running) poll.running = true }
  Process {
    id: poll
    command: ["python3", ds.helper, "--profile", ds.profileFile, "status", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const d = JSON.parse(text)
          ds.controllers = (d.controllers || []).filter(c => !!c)
          if (d.profile) ds.profile = d.profile
        } catch (e) { }
      }
    }
  }
  Timer { interval: ds.watching ? 2000 : 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: ds.refresh() }
  onWatchingChanged: if (watching) refresh()

  // ── Changing (one helper call at a time, in order) ──
  property var queue: []
  function ctl(args, after) { queue = queue.concat([{ args: args, after: after || null }]); pump() }
  function pump() {
    if (act.running || !queue.length) return
    const job = queue[0]; queue = queue.slice(1)
    act.job = job
    act.command = ["python3", helper, "--profile", profileFile].concat(job.args)
    busy = true
    act.running = true
  }
  Process {
    id: act
    property var job: null
    onExited: (code) => { ds.busy = false; if (job && job.after) job.after(code); ds.pump() }
  }

  // Save one profile value, then apply it to the controller (as the plugin does).
  function set(key, value) {
    const copy = JSON.parse(JSON.stringify(profile || {}))
    const parts = key.split(".")
    let node = copy
    for (let i = 0; i < parts.length - 1; i++) { if (typeof node[parts[i]] !== "object" || node[parts[i]] === null) node[parts[i]] = {}; node = node[parts[i]] }
    node[parts[parts.length - 1]] = value
    profile = copy
    ctl(["--all", "profile", "set", key, JSON.stringify(value), "--accent", accentHex, "--no-apply"], (code) => {
      if (code === 0 && ds.canControl) ds.ctl(["--all", "apply", "--accent", ds.accentHex])
    })
  }
  function setColor(hex) {
    const copy = JSON.parse(JSON.stringify(profile || {}))
    copy.lightbar = Object.assign({}, copy.lightbar || {}, { color: hex, followTheme: false, enabled: true })
    profile = copy
    ctl(["--all", "profile", "set", "lightbar.followTheme", "false", "--no-apply"])
    ctl(["--all", "profile", "set", "lightbar.enabled", "true", "--no-apply"])
    ctl(["--all", "profile", "set", "lightbar.color", JSON.stringify(hex), "--accent", accentHex])
  }
  function setTriggers(effect) { set("triggers.left.effect", effect); set("triggers.right.effect", effect) }
  function setStrength(v) { set("triggers.left.strength", v); set("triggers.right.strength", v) }
  function deviceArgs() { return connected && device.mac ? ["--device", device.mac] : [] }
  function rumble() { if (connected) ctl(deviceArgs().concat(["rumble", "--strong", "90", "--weak", "50", "--ms", "500"])) }
  function powerOff() { if (bluetooth) ctl(deviceArgs().concat(["poweroff"]), () => ds.refresh()) }
  function reconnect() { ctl(["reconnect"], () => ds.refresh()) }
  function reapply() { if (connected) ctl(["--all", "apply", "--accent", accentHex]) }
  function reset() { ctl(["--all", "profile", "reset", "--accent", accentHex], () => ds.refresh()) }

  // Lightbar preview while dragging the hue or brightness: one report every
  // ~90 ms at most (more floods Bluetooth and drops the link).
  property string pendingHex: ""
  property real pendingBright: 100
  function preview(hex, bright) {
    if (!canControl) return
    pendingHex = hex; pendingBright = bright
    if (!throttle.running) { flush(); throttle.start() }
  }
  function flush() {
    if (pendingHex === "" || prev.running) return
    prev.command = ["python3", helper].concat(deviceArgs()).concat(["--no-release", "lightbar", pendingHex, "--brightness", String(Math.round(pendingBright))])
    prev.running = true
    pendingHex = ""
  }
  Process { id: prev }
  Timer { id: throttle; interval: 90; onTriggered: ds.flush() }

  // Live input for the Test tab.
  property bool testing: false
  property var live: null
  Process {
    id: monitor
    running: ds.testing && ds.watching && ds.connected
    command: ["python3", ds.helper].concat(ds.deviceArgs()).concat(["monitor", "--rate", "30"])
    stdout: SplitParser { onRead: (line) => { try { ds.live = JSON.parse(line) } catch (e) { } } }
    onRunningChanged: if (!running) ds.live = null
  }
}
