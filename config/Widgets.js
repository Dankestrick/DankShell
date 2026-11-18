.pragma library

// Widgets — your Omarchy bar widgets that DankShell shows as their real
// selves (icon + their own dropdown) in a strip in the dashboard. Every
// widget in shell.json's bar layout shows up, in bar order, except these.
// Add an id here to hide it; take one out to bring it back.
var SKIP = [
  "omarchy.workspaces",                // the island has its own workspace dots
  "omarchy.audio",                     // Home's volume + Sound & Bluetooth page
  "omarchy.bluetooth",                 // Home's Bluetooth tile + Sound & Bluetooth page
  "io.github.dankestrick.omajournal"   // the island's clock + Journal page
]
// Sections of the stock bar layout to take widgets from, in order.
var SECTIONS = ["left", "centerBegin", "center", "centerEnd", "right", "tray"]

// How each widget shows in the Plugins tab: name, Material Symbols icon,
// one line about it. A widget not listed uses its own name and a puzzle icon.
var NAMES = {
  "omarchy.menu": "Omarchy Menu", "omarchy.indicators": "Indicators", "omarchy.tray": "Tray",
  "omarchy.keyboard-layout": "Keyboard Layout", "amagdy46.dslr-webcam": "Webcam", "omamail": "Mail",
  "omarchy.dropbox": "Dropbox", "omarchy.agents": "Agents", "io.github.qempexe.plume": "Plume",
  "omarchy.network": "Network", "omarchy.monitor": "Monitor", "atoslins.dualsense": "DualSense",
  "io.github.grichard99.omaproton-vpn": "ProtonVPN", "omarchy.weather": "Weather", "omaplug": "Omaplug",
  "crmne.hyprmoncfg": "Displays", "omarchy.system-update": "Updates", "superwhisper.panel": "Superwhisper"
}
var ICONS = {
  "omarchy.menu": "apps", "omarchy.indicators": "notifications_active", "omarchy.tray": "chevron_left",
  "omarchy.keyboard-layout": "keyboard", "amagdy46.dslr-webcam": "videocam", "omamail": "mail",
  "omarchy.dropbox": "cloud_sync", "omarchy.agents": "smart_toy", "io.github.qempexe.plume": "edit",
  "omarchy.network": "lan", "omarchy.monitor": "monitoring", "atoslins.dualsense": "sports_esports",
  "io.github.grichard99.omaproton-vpn": "vpn_lock", "omarchy.weather": "partly_cloudy_day", "omaplug": "extension",
  "crmne.hyprmoncfg": "desktop_windows", "omarchy.system-update": "system_update", "superwhisper.panel": "mic"
}
var ABOUT = {
  "omarchy.menu": "Omarchy's main menu.", "omarchy.indicators": "Recording, reminders, stay awake and other status lights.",
  "omarchy.tray": "App icons from the system tray.", "omarchy.keyboard-layout": "Switch keyboard layouts.",
  "amagdy46.dslr-webcam": "Use your camera as a webcam.", "omamail": "Your mail.",
  "omarchy.dropbox": "Dropbox sync status.", "omarchy.agents": "Your AI agents and their usage.",
  "io.github.qempexe.plume": "Plume.", "omarchy.network": "Network speed, ping and DNS.",
  "omarchy.monitor": "CPU, memory and GPU.", "atoslins.dualsense": "DualSense controller battery and lights.",
  "io.github.grichard99.omaproton-vpn": "ProtonVPN servers.", "omarchy.weather": "Weather where you are.",
  "omaplug": "Omaplug.", "crmne.hyprmoncfg": "Monitor layouts.", "omarchy.system-update": "Updates waiting.",
  "superwhisper.panel": "Superwhisper dictation."
}
