.pragma library

// Plugins — your Omarchy plugins that get a page on the dashboard.
// DankShell runs each one's own service itself (Omarchy won't let a custom
// bar reach another plugin's service), so while DankShell is on, Omarchy's
// copy is switched off with `scripts/dankshell on` and back with `off`.
//
// id:    the plugin's manifest id
// key:   short name; the page file is modules/pages/<Key>.qml
// name:  the tab label
// icon:  Material Symbols name for the tab
// model: for a plugin with no service, one of its own files run as one (optional)
// off:   true = leave it on Omarchy and skip its page (optional)

var LIST = [
  { id: "io.github.dankestrick.omapandora",  key: "pandora",   name: "Pandora",   icon: "radio" },
  { id: "io.github.dankestrick.omakraken",   key: "kraken",    name: "Kraken",    icon: "headphones" },
  { id: "io.github.dankestrick.omagravastar", key: "gravastar", name: "Gravastar", icon: "mouse" },
  { id: "io.github.dankestrick.omaiphone",   key: "iphone",    name: "iPhone",    icon: "smartphone" },
  { id: "io.github.dankestrick.omajournal",  key: "journal",   name: "Journal",   icon: "edit_note" },
  { id: "io.github.dankestrick.omagrokbots", key: "grokbots",  name: "Grok Bots", icon: "smart_toy", model: "Inbox.qml", off: true }
]

function active() { return LIST.filter(function(p) { return !p.off }) }
function byKey(key) { for (var i = 0; i < LIST.length; i++) if (LIST[i].key === key) return LIST[i]; return null }
function byId(id) { for (var i = 0; i < LIST.length; i++) if (LIST[i].id === id) return LIST[i]; return null }
