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
