import QtQuick
import Quickshell
import "../../"

// PluginPage — the Plugins window page for one plugin that has no page of
// its own. How you use it depends on the plugin:
//   widget: its real dropdown opens right here, inside the window
//   open:   its own window (OmaCanon, CircuitLab, Emojis...) opens on "Open"
//   info:   what it is; a plugin that's off can be turned on
Column {
  id: page
  property var plugin: null
  property bool showing: false
  signal closeRequested()
  spacing: 10

  readonly property bool isWidget: !!plugin && plugin.use === "widget"
  // Has a dropdown (open()); otherwise its icon is shown here to click.
  readonly property bool hasDropdown: isWidget && WidgetHost.canOpen(live.widget)

  // ── About ─────────────────────────────────────
  Card {
    width: parent.width
    Row {
      spacing: 8
      Rectangle {
        width: stateText.implicitWidth + 18; height: 22; radius: 11
        color: page.plugin && page.plugin.enabled ? Theme.accent : Theme.surface
        Text { id: stateText; anchors.centerIn: parent; text: page.plugin && page.plugin.enabled ? "Running" : "Not running"; color: page.plugin && page.plugin.enabled ? Theme.surface : Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: page.plugin ? (page.plugin.version ? "v" + page.plugin.version + "  ·  " : "") + page.plugin.kinds.join(", ") + (page.plugin.firstParty ? "  ·  Omarchy" : "") : ""
        color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
      }
    }
    Text {
      width: parent.width
      visible: text !== ""
      wrapMode: Text.WordWrap
      text: page.plugin ? page.plugin.description : ""
      color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12
    }
    Row {
      spacing: 8
      // Open its own window.
      PillButton {
        visible: !!page.plugin && page.plugin.use === "open"
        icon: "open_in_new"; label: "Open"
        onClicked: { const id = page.plugin.id; Popouts.closeCenter(); Quickshell.execDetached(["omarchy-shell", "shell", "summon", id, "{}"]) }
      }
      // Reopen the dropdown after clicking away from it.
      PillButton {
        visible: page.hasDropdown && !WidgetHost.popoutOpen
        icon: "expand_more"; label: "Show it"
        onClicked: page.openDropdown()
      }
      // Turn on a plugin that's off (Omarchy's `plugin enable`).
      PillButton {
        visible: !!page.plugin && !page.plugin.enabled && !page.plugin.firstParty
        icon: "power_settings_new"; label: "Turn on"
        onClicked: Installed.setEnabled(page.plugin.id, true)
      }
    }
  }

  // ── The widget, live, with its dropdown placed in this window ──
  Item {
    id: dropSpot
    width: parent.width
    height: !page.isWidget ? 0 : page.hasDropdown ? 360 : 120
    visible: page.isWidget

    // The real widget. Hidden when its dropdown does the talking; shown big
    // when it has no dropdown, so you click it like on the bar.
    HostedWidget {
      id: live
      anchors.horizontalCenter: parent.horizontalCenter
      y: 24
      scale: page.hasDropdown ? 1 : 1.6
      opacity: page.hasDropdown ? 0 : 1
      enabled: !page.hasDropdown
      entry: page.isWidget ? (WidgetHost.entries.find(e => e.id === page.plugin.id) || { id: page.plugin.id }) : ({ id: "" })
    }
    Text {
      anchors.centerIn: parent
      visible: !WidgetHost.popoutOpen
      anchors.verticalCenterOffset: page.hasDropdown ? 0 : 30
      width: parent.width - 40
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      text: page.hasDropdown ? "Its dropdown shows here." : "No dropdown: click it like on the bar (left, right and middle click can do different things)."
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
    }
  }

  function openDropdown() {
    if (WidgetHost.openWidget(live.widget)) placeTimer.restart()
  }
  // Open it as soon as the page shows.
  Timer { id: openTimer; interval: 350; onTriggered: page.openDropdown() }
  onShowingChanged: if (showing && isWidget) openTimer.restart(); else if (!showing && WidgetHost.popoutOpen) WidgetHost.closeAll()
  Component.onCompleted: if (showing && isWidget) openTimer.restart()
  Component.onDestruction: if (WidgetHost.popoutOpen && WidgetHost.activeOwnerId === (plugin ? plugin.id : "")) WidgetHost.closeAll()

  // ── Put the dropdown's card over dropSpot ─────
  // Omarchy's dropdown is its own full-screen window; we find its card and
  // place it where dropSpot is on screen (the window sits centered).
  property var card: null
  Timer { id: placeTimer; interval: 60; onTriggered: page.card = WidgetHost.cardOf(live.widget) }
  readonly property point spot: {
    void(page.card)
    const win = page.QsWindow.window
    if (!win || !win.screen) return Qt.point(0, 0)
    const p = dropSpot.mapToItem(null, 0, 0)
    return Qt.point((win.screen.width - win.width) / 2 + p.x, (win.screen.height - win.height) / 2 + p.y)
  }
  Binding { target: page.card; property: "x"; value: Math.round(page.spot.x + (dropSpot.width - (page.card ? page.card.width : 0)) / 2); when: !!page.card && WidgetHost.popoutOpen; restoreMode: Binding.RestoreNone }
  // A tall dropdown slides up so it stays inside the window.
  readonly property real winBottom: {
    const win = page.QsWindow.window
    return win && win.screen ? (win.screen.height + win.height) / 2 - 14 : 99999
  }
  readonly property real winTop: {
    const win = page.QsWindow.window
    return win && win.screen ? (win.screen.height - win.height) / 2 + 14 : 0
  }
  Binding {
    target: page.card; property: "y"; when: !!page.card && WidgetHost.popoutOpen; restoreMode: Binding.RestoreNone
    value: Math.round(Math.max(page.winTop, Math.min(page.spot.y, page.winBottom - (page.card ? page.card.height : 0))))
  }

  component PillButton: Rectangle {
    id: pb
    property string icon: ""
    property string label: ""
    signal clicked()
    width: pbRow.implicitWidth + 28
    height: 34
    radius: 17
    color: pbTap.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
    Row {
      id: pbRow
      anchors.centerIn: parent
      spacing: 6
      Icon { name: pb.icon; color: Theme.surface; anchors.verticalCenter: parent.verticalCenter }
      Text { text: pb.label; color: Theme.surface; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: pbTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pb.clicked() }
  }
}
