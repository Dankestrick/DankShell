import QtQuick
import qs.Commons
import qs.Ui
import "../"

// DankBarApi — Omarchy's PluginBarApi (what every bar widget gets as `bar`),
// with DankShell's colors and one addition: barSizeFor(), which Omarchy's
// dropdowns ask to know where the bar ends. We answer with the bottom of the
// island, so a dropdown opens right under it.
PluginBarApi {
  id: api
  foreground: Theme.text
  barForeground: Theme.text
  background: Theme.surface
  urgent: Theme.urgent
  fontFamily: Style.font.family
  position: "top"
  vertical: false
  barSize: Style.bar.sizeHorizontal
  transparent: true
  activePopout: WidgetHost.active === null ? null
    : WidgetHost.activeOwnerId === pluginId ? WidgetHost.active : foreignPopoutMarker
  clickTargets: WidgetHost.targets.filter(t => t.id === pluginId).map(t => t.target)
  layoutConfig: PluginHost.shellConfig && PluginHost.shellConfig.bar ? PluginHost.shellConfig.bar.layout || ({}) : ({})

  function barSizeFor(screenName) { return WidgetHost.dropFor(screenName) }
}
