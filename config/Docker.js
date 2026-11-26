// Docker containers in the hover card: icon and web page for each one.
// A container not listed here uses the first port it publishes
// (http://localhost:PORT); one with no page just shows its icon.
.pragma library

var URLS = {
  "voicestudio": "http://localhost:3900",
  "open-webui": "http://localhost:8080",
  "searxng": "http://localhost:8888",
  "macos": "http://localhost:8006",
  "windows": "http://localhost:8006"
}

var ICONS = {
  "voicestudio": "record_voice_over",
  "open-webui": "smart_toy",
  "searxng": "search",
  "macos": "laptop_mac",
  "windows": "desktop_windows",
  "kali": "security",
  "zap": "bug_report",
  "juice-shop": "local_drink"
}
