pragma Singleton
import QtQuick
import Quickshell

// Status — one short live line per plugin, for the Plugins window's sidebar
// and grid: "70%", "Playing", "3 new"... `alert` = worth a look (low battery,
// unread). Plugins with a page read their service; bar widgets show what
// their own bar button says (DualSense "100%", weather "12°").
Singleton {
  function of(key) {
    const s = PluginHost.service(key)
    if (key === "kraken" || key === "gravastar") {
      if (!s || !s.connected) return { text: "Off", alert: false }
      const b = Number(s.battery)
      if (!(b >= 0)) return { text: "On", alert: false }
      return { text: b + "%" + (s.charging ? " ⚡" : ""), alert: b <= 20 && !s.charging }
    }
    if (key === "iphone") {
      if (!s || !s.phone) return { text: "", alert: false }
      if (s.unread > 0) return { text: s.unread + " new", alert: true }
      return { text: s.battery !== null && s.battery !== undefined ? s.battery + "%" : "", alert: false }
    }
    if (key === "pandora") return { text: s && s.playing ? "Playing" : "", alert: false }
    if (key === "grokbots") return { text: s && s.unreadCount > 0 ? s.unreadCount + " new" : "", alert: !!s && s.unreadCount > 0 }
    // A bar widget: what its own button reads, if it's words or numbers.
    const w = WidgetHost.live.find(x => x.moduleName === key)
    const btn = w ? WidgetHost.findButton(w) : null
    const t = btn && btn.text ? String(btn.text).trim() : ""
    if (t.length >= 2 && t.length <= 12 && /[0-9A-Za-z]/.test(t)) return { text: t, alert: false }
    return { text: "", alert: false }
  }
}
