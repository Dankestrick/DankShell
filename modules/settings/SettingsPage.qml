import QtQuick
import Quickshell
import "../../"

// SettingsPage — draws one section from config/SettingsList.js.
// Every row changes right away. A row you changed shows its value in the
// accent color and a ↺ to put it back (idea borrowed from OmaSettings).
// While you search, only matching rows show.
Column {
  id: page
  property var section: null
  property string filter: ""     // the Settings window's search text
  property bool showing: false
  spacing: 10

  readonly property var items: {
    const all = section ? section.items : []
    const q = filter.trim().toLowerCase()
    if (q === "" || (section.name + " " + section.words).toLowerCase().includes(q)) return all
    return all.filter(i => String(i.label || "").toLowerCase().includes(q))
  }

  onShowingChanged: if (showing && section && section.key === "windows") { Hypr.keys = section.items.map(i => i.hypr); Hypr.reload() }
  Component.onCompleted: if (section && section.key === "windows") { Hypr.keys = section.items.map(i => i.hypr); Hypr.reload() }

  // ── One row per item ──────────────────────────
  Card {
    width: parent.width
    spacing: 2
    Repeater {
      model: page.items
      Loader {
        required property var modelData
        width: parent.width
        property var item_: modelData
        sourceComponent: modelData.kind === "apps" ? appsRows
                       : modelData.kind === "choice" ? choiceRow
                       : modelData.kind === "switch" ? switchRow : slider
      }
    }
  }

  // Put this whole section back.
  Rectangle {
    readonly property var keys: page.section ? page.section.items.filter(i => i.key).map(i => i.key) : []
    readonly property var hyprKeys: page.section ? page.section.items.filter(i => i.hypr).map(i => i.hypr) : []
    readonly property bool anyChanged: { void(Settings.v.hypr); void(Settings.v.barHeight); return keys.some(k => { void(Settings.v[k]); return !Settings.isDefault(k) }) || hyprKeys.some(k => Hypr.changed(k)) }
    anchors.right: parent.right
    visible: keys.length + hyprKeys.length > 0
    opacity: anyChanged ? 1 : 0.4
    width: resetText.implicitWidth + 28
    height: 30
    radius: 15
    color: resetTap.containsMouse && anyChanged ? Theme.surfaceRaised : "transparent"
    border.width: 1
    border.color: Theme.edge
    Text { id: resetText; anchors.centerIn: parent; text: "Undo everything here"; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11 }
    MouseArea {
      id: resetTap; anchors.fill: parent; hoverEnabled: true; enabled: parent.anyChanged; cursorShape: Qt.PointingHandCursor
      onClicked: { Settings.reset(parent.keys); for (const k of parent.hyprKeys) if (Hypr.changed(k)) Hypr.reset(k) }
    }
  }

  // ↺ — put one row back.
  component UndoButton: Rectangle {
    id: ub
    signal clicked()
    width: 24; height: 24; radius: 12
    color: ubTap.containsMouse ? Theme.surface : "transparent"
    Icon { anchors.centerIn: parent; name: "undo"; color: Theme.accent; font.pixelSize: 15 }
    MouseArea { id: ubTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ub.clicked() }
  }

  Component {
    id: slider
    Item {
      readonly property var d: parent.item_
      readonly property bool isHypr: !!d.hypr
      readonly property bool changed: { void(Settings.v.hypr); void(Settings.v[d.key]); return isHypr ? Hypr.changed(d.hypr) : !Settings.isDefault(d.key) }
      width: parent.width
      implicitHeight: s.implicitHeight
      SettingSlider {
        id: s
        width: parent.width - (parent.changed ? 30 : 0)
        label: parent.d.label; min: parent.d.min; max: parent.d.max; step: parent.d.step; unit: parent.d.unit
        value: { void(Settings.v.hypr); void(Hypr.current); const v = parent.isHypr ? Hypr.value(parent.d.hypr) : Settings.v[parent.d.key]; return v === undefined ? parent.d.min : Number(v) }
        changed: parent.changed
        onMoved: (v) => { const val = parent.d.step >= 1 ? Math.round(v) : v; if (parent.isHypr) Hypr.set(parent.d.hypr, val); else Settings.set(parent.d.key, val) }
      }
      UndoButton {
        visible: parent.changed
        anchors.right: parent.right; y: 4
        onClicked: if (parent.isHypr) Hypr.reset(parent.d.hypr); else Settings.reset([parent.d.key])
      }
    }
  }
  Component {
    id: switchRow
    Item {
      readonly property var d: parent.item_
      readonly property bool isHypr: !!d.hypr
      readonly property bool changed: { void(Settings.v.hypr); void(Settings.v[d.key]); return isHypr ? Hypr.changed(d.hypr) : !Settings.isDefault(d.key) }
      width: parent.width
      implicitHeight: 48
      SwitchRow {
        width: parent.width - (parent.changed ? 30 : 0)
        anchors.verticalCenter: parent.verticalCenter
        icon: parent.d.icon || ""; label: parent.d.label; sub: parent.d.sub || ""
        checked: { void(Settings.v.hypr); void(Hypr.current); return !!(parent.isHypr ? Hypr.value(parent.d.hypr) : Settings.v[parent.d.key]) }
        onToggled: (v) => { if (parent.isHypr) Hypr.set(parent.d.hypr, v); else Settings.set(parent.d.key, v) }
      }
      UndoButton {
        visible: parent.changed
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        onClicked: if (parent.isHypr) Hypr.reset(parent.d.hypr); else Settings.reset([parent.d.key])
      }
    }
  }
  // Timeouts: pick one; Apply restarts the shell (its idle timer only takes
  // a new time after a restart).
  Component {
    id: choiceRow
    Column {
      readonly property var d: parent.item_
      readonly property var idleCfg: PluginHost.shellConfig && PluginHost.shellConfig.idle ? PluginHost.shellConfig.idle : ({})
      readonly property int now: Number(idleCfg[d.idle]) || 0
      width: parent.width
      spacing: 8
      topPadding: 6
      bottomPadding: 10
      Text { text: parent.d.label; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12 }
      Chips {
        model: parent.d.choices.map(c => c[1])
        current: parent.d.choices.findIndex(c => c[0] === parent.now)
        onPicked: (i) => { Quickshell.execDetached(["bash", Qt.resolvedUrl("../../scripts/idle-set").toString().replace("file://", ""), parent.d.idle, String(parent.d.choices[i][0])]); page.needsRestart = true }
      }
    }
  }
  property bool needsRestart: false
  Rectangle {
    visible: page.needsRestart
    width: parent.width
    height: 44
    radius: Sizes.cardRadius
    color: Theme.surfaceRaised
    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "Saved. The shell restarts to use it."; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11 }
    Rectangle {
      anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
      width: applyText.implicitWidth + 28; height: 30; radius: 15
      color: applyTap.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
      Text { id: applyText; anchors.centerIn: parent; text: "Restart now"; color: Theme.surface; font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold }
      MouseArea { id: applyTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["omarchy", "restart", "shell"]) }
    }
  }

  // Top row: pinned in order (arrows move them), then the rest.
  Component {
    id: appsRows
    Column {
      id: apps
      width: parent.width
      readonly property var pinned: Settings.v.pinned.map(k => WidgetHost.item(k)).filter(c => !!c)
      readonly property var others: WidgetHost.catalog.filter(c => Settings.v.pinned.indexOf(c.key) < 0)

      Text { text: "In the top row (left to right)"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase; bottomPadding: 4 }
      Text { visible: apps.pinned.length === 0; text: "Nothing pinned yet."; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12; bottomPadding: 6 }
      Repeater {
        model: apps.pinned
        Item {
          required property var modelData
          required property int index
          width: apps.width
          height: 46
          Row {
            id: arrows
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
              model: [{ icon: "keyboard_arrow_up", d: -1 }, { icon: "keyboard_arrow_down", d: 1 }]
              Rectangle {
                required property var modelData
                readonly property bool can: modelData.d < 0 ? index > 0 : index < apps.pinned.length - 1
                width: 24; height: 24; radius: 12
                opacity: can ? 1 : 0.25
                color: mv.containsMouse && can ? Theme.surface : "transparent"
                Icon { anchors.centerIn: parent; name: modelData.icon; color: Theme.text }
                MouseArea { id: mv; anchors.fill: parent; hoverEnabled: true; enabled: parent.can; cursorShape: Qt.PointingHandCursor; onClicked: Settings.movePinned(apps.pinned[index].key, modelData.d) }
              }
            }
          }
          SwitchRow {
            anchors.left: arrows.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: modelData.icon; label: (index + 1) + ".  " + modelData.name
            checked: true
            onToggled: (v) => Settings.setPinned(modelData.key, v)
          }
        }
      }
      Rectangle { width: parent.width; height: 1; color: Theme.edge }
      Text { text: "Plugins tab only"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase; topPadding: 10; bottomPadding: 4 }
      Repeater {
        model: apps.others
        SwitchRow {
          required property var modelData
          icon: modelData.icon; label: modelData.name
          sub: "Turn on to pin it at the end of the top row"
          implicitHeight: 46
          checked: false
          onToggled: (v) => Settings.setPinned(modelData.key, v)
        }
      }
    }
  }
}
