import QtQuick
import "../"

// HostedWidget — one of your Omarchy bar widgets, the real thing, dropped
// in place. `entry` is its shell.json bar entry (id + its settings).
Item {
  id: slot
  required property var entry
  readonly property string moduleName: entry.id
  property Item widget: null

  readonly property var component: WidgetHost.componentFor(moduleName)
  // Hidden while the widget has nothing to show (an idle indicator).
  readonly property bool hasContent: !!widget && widget.implicitWidth > 0.5 && widget.implicitHeight > 0.5

  implicitWidth: hasContent ? widget.implicitWidth : 0
  implicitHeight: hasContent ? widget.implicitHeight : 0

  function create() {
    if (widget) { WidgetHost.removeLive(widget); widget.destroy(); widget = null }
    const comp = component
    if (!comp || comp.status !== Component.Ready) return
    try {
      widget = comp.createObject(slot, { bar: WidgetHost.apiFor(moduleName), moduleName: moduleName, settings: entry })
    } catch (e) { console.warn("dankshell: widget " + moduleName + " didn't start: " + e) }
    if (widget) WidgetHost.addLive(widget)
  }
  onComponentChanged: create()
  onEntryChanged: if (widget && "settings" in widget) widget.settings = entry
  Component.onCompleted: create()
  Component.onDestruction: if (widget) WidgetHost.removeLive(widget)
}
