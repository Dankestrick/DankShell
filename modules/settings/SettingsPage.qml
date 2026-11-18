import QtQuick
import "../../"

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
    // Pinned first, in top-row order (arrows move them), then the rest.
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
