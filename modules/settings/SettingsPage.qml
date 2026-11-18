import QtQuick
import "../../"
import "../../config/Plugins.js" as Plugins

// SettingsPage — draws one section from config/SettingsList.js.
// Every row writes straight to Settings, so the island changes as you drag.
Column {
  id: page
  property var section: null
  property bool showing: false
  spacing: 10

  Card {
    width: parent.width
    spacing: 2
    Repeater {
      model: page.section ? page.section.items : []
      Loader {
        required property var modelData
        width: parent.width
        sourceComponent: modelData.kind === "switch" ? switchRow : modelData.kind === "apps" ? appsRows : slider
        property var item_: modelData
      }
    }
  }

  // Put this section back to the starting values.
  Rectangle {
    readonly property var keys: page.section ? page.section.items.filter(i => i.key).map(i => i.key) : []
    readonly property bool anyChanged: { void(Settings.v.barHeight); return keys.some(k => { void(Settings.v[k]); return !Settings.isDefault(k) }) }
    anchors.right: parent.right
    visible: keys.length > 0
    opacity: anyChanged ? 1 : 0.4
    width: resetText.implicitWidth + 28
    height: 30
    radius: 15
    color: resetTap.containsMouse && anyChanged ? Theme.surfaceRaised : "transparent"
    border.width: 1
    border.color: Theme.edge
    Text { id: resetText; anchors.centerIn: parent; text: "Reset to defaults"; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11 }
    MouseArea { id: resetTap; anchors.fill: parent; hoverEnabled: true; enabled: parent.anyChanged; cursorShape: Qt.PointingHandCursor; onClicked: Settings.reset(parent.keys) }
  }

  Component {
    id: slider
    SettingSlider {
      readonly property var d: parent.item_
      label: d.label; min: d.min; max: d.max; step: d.step; unit: d.unit
      value: Settings.v[d.key]
      changed: { void(Settings.v[d.key]); return !Settings.isDefault(d.key) }
      onMoved: (v) => Settings.set(d.key, d.step >= 1 ? Math.round(v) : v)
    }
  }
  Component {
    id: switchRow
    SwitchRow {
      readonly property var d: parent.item_
      icon: d.icon || ""; label: d.label; sub: d.sub || ""
      implicitHeight: 48
      checked: !!Settings.v[d.key]
      onToggled: (v) => Settings.set(d.key, v)
    }
  }
  Component {
    id: appsRows
    Column {
      width: parent.width
      Repeater {
        model: Plugins.active()
        SwitchRow {
          required property var modelData
          icon: modelData.icon; label: modelData.name
          sub: checked ? "Button in the dashboard" : "Hidden (still in Settings window)"
          implicitHeight: 46
          checked: Settings.v.hiddenApps.indexOf(modelData.key) < 0
          onToggled: (v) => {
            const list = Settings.v.hiddenApps.filter(k => k !== modelData.key)
            if (!v) list.push(modelData.key)
            Settings.set("hiddenApps", list)
          }
        }
      }
    }
  }
}
