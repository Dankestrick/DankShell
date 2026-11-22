import QtQuick
import Quickshell
import "../../"

// Dashboard — what the island opens into when you click it.
// The clock isn't in here: it's the same clock from the pill, sliding into
// the top-left corner (see Island.qml). This file leaves room for it.
//
// Top left:  the date under the clock (click it for the Journal).
// Top right: your pinned plugins, then themes, wallpapers, device (Games,
// Camera, Notifications), plugins, settings, power (System info, Lock,
// Screensaver, Restart, Power off).
//   A pinned page plugin (Pandora, Kraken...) opens right here, sliding in
//   like a tab; click it again to go back Home.
//   A pinned widget (network, mail...) is the real widget with its dropdown.
// Every plugin, pinned or not, is in the Center window's Plugins tab.
// Pin them there, or in Settings › Top row.
Item {
  id: dash

  readonly property int headerHeight: 68
  property bool hosting: false   // a widget's dropdown is showing in our place (Island.qml)
  property string page: "home"

  signal closeRequested()
  signal themesRequested()
  signal wallsRequested()
  signal pageRequested(string key)   // open this in the Center window

  function reset() { page = "home"; powerOpen = false }

  // ── Power menu (the power button, far right) ──
  property bool powerOpen: false
  property string armed: ""   // Restart / Power off wait for a second click
  onPowerOpenChanged: armed = ""
  function power(what) {
    if ((what === "reboot" || what === "shutdown") && armed !== what) { armed = what; disarm.restart(); return }
    powerOpen = false
    if (what === "system") { pageRequested("monitor"); return }
    closeRequested()
    const cmd = what === "lock" ? ["omarchy", "system", "lock"]
              : what === "screensaver" ? ["omarchy-launch-screensaver", "force"]
              : ["omarchy", "system", what]
    Quickshell.execDetached(cmd)
  }
  Timer { id: disarm; interval: 3000; onTriggered: dash.armed = "" }

  // Pinned plugins, in the order they were pinned.
  readonly property var pins: Settings.v.pinned.map(k => WidgetHost.item(k)).filter(c => !!c)
  // Pages the dashboard can show: Home + pinned page plugins.
  readonly property var pages: [{ key: "home", file: "Home.qml" }]
    .concat(pins.filter(p => p.kind === "page").map(p => ({ key: p.key, file: p.key.charAt(0).toUpperCase() + p.key.slice(1) + ".qml" })))
  // Widgets that aren't pinned still run here, out of sight, so the Plugins
  // tab can open their dropdown.
  readonly property var stashed: WidgetHost.entries.filter(e => !!WidgetHost.componentFor(e.id) && Settings.v.pinned.indexOf(e.id) < 0).map(e => ({ entry: e }))

  function openPage(key) {
    if (pages.some(p => p.key === key)) page = (page === key ? "home" : key)
    else pageRequested(key)
  }

  // Wide enough for the date and every button in the top row.
  readonly property int neededWidth: dateChip.width + topRow.width + Sizes.dashPadding * 2 + 16

  component HeaderButton: Rectangle {
    id: hb
    property string icon: ""
    property bool lit: false
    signal clicked()
    width: 30; height: 30; radius: 15
    color: lit ? Theme.accent : tap.containsMouse ? Theme.surfaceRaised : "transparent"
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Icon { anchors.centerIn: parent; name: hb.icon; filled: hb.lit; color: hb.lit ? Theme.surface : tap.containsMouse ? Theme.text : Theme.textDim }
    MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hb.clicked() }
  }

  // ── Date under the clock: click it for the Journal ──
  Rectangle {
    id: dateChip
    x: Sizes.dashPadding
    y: 46
    width: dateText.implicitWidth + 12
    height: 20
    radius: 10
    color: dateTap.containsMouse ? Theme.surfaceRaised : "transparent"
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Text {
      id: dateText
      anchors.centerIn: parent
      text: Time.dateLong
      color: dateTap.containsMouse || dash.page === "journal" ? Theme.accent : Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 11
    }
    MouseArea { id: dateTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dash.openPage("journal") }
  }

  // ── Top row ───────────────────────────────────
  Row {
    id: topRow
    anchors.right: parent.right
    anchors.rightMargin: Sizes.dashPadding - 4
    y: 17
    spacing: 2

    Repeater {
      model: dash.pins
      Item {
        required property var modelData
        width: modelData.kind === "widget" ? live.implicitWidth : 30
        height: 30
        HeaderButton {
          visible: modelData.kind === "page"
          icon: modelData.icon
          lit: dash.page === modelData.key
          onClicked: dash.openPage(modelData.key)
        }
        HostedWidget {
          id: live
          visible: modelData.kind === "widget"
          anchors.verticalCenter: parent.verticalCenter
          entry: modelData.kind === "widget" ? modelData.entry : ({ id: "" })
        }
      }
    }
    Rectangle { visible: dash.pins.length > 0; width: 1; height: 16; anchors.verticalCenter: parent.verticalCenter; color: Theme.edge }
    HeaderButton { icon: "palette"; onClicked: dash.themesRequested() }
    HeaderButton { icon: "wallpaper"; onClicked: dash.wallsRequested() }
    HeaderButton { icon: "devices"; onClicked: dash.pageRequested(Popouts.lastDevice) }
    HeaderButton { icon: "extension"; onClicked: dash.pageRequested("@plugins") }
    HeaderButton { icon: "settings"; onClicked: dash.pageRequested("@settings") }
    HeaderButton { id: powerBtn; icon: "power_settings_new"; lit: dash.powerOpen; onClicked: dash.powerOpen = !dash.powerOpen }
  }

  // Unpinned widgets: running, invisible, under the top row (their dropdowns
  // still open in the right spot when the Plugins tab asks).
  Row {
    anchors.right: topRow.right
    y: topRow.y
    opacity: 0
    enabled: false
    Repeater {
      model: dash.stashed
      HostedWidget { required property var modelData; entry: modelData.entry }
    }
  }

  // ── Pages ─────────────────────────────────────
  // Each page slides and fades in; the dashboard height follows the page.
  Item {
    id: pageArea
    opacity: dash.hosting ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Sizes.dashPadding
    y: dash.headerHeight + 6
    height: current ? current.implicitHeight : 0
    property var current: null

    Repeater {
      model: dash.pages
      Loader {
        required property var modelData
        required property int index
        readonly property bool here: dash.page === modelData.key
        width: pageArea.width
        source: Qt.resolvedUrl("../pages/" + modelData.file)
        opacity: here ? 1 : 0
        x: here ? 0 : (index < dash.pages.findIndex(p => p.key === dash.page) ? -24 : 24)
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
        Behavior on x { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
        onHereChanged: if (here) pageArea.current = item
        onLoaded: {
          item.width = Qt.binding(() => pageArea.width)
          if ("showing" in item) item.showing = Qt.binding(() => here && dash.visible)
          if (item.closeRequested) item.closeRequested.connect(dash.closeRequested)
          if (here) pageArea.current = item
        }
      }
    }
  }
  // ── Power menu ────────────────────────────────
  // A click anywhere else closes it.
  MouseArea {
    anchors.fill: parent
    z: 9
    visible: dash.powerOpen
    onClicked: dash.powerOpen = false
  }
  Rectangle {
    id: powerMenu
    z: 10
    readonly property var items: [
      { key: "system", icon: "monitoring", label: "System info" },
      { key: "lock", icon: "lock", label: "Lock" },
      { key: "screensaver", icon: "auto_awesome", label: "Screensaver" },
      { key: "reboot", icon: "restart_alt", label: "Restart", sure: "Click again to restart" },
      { key: "shutdown", icon: "power_settings_new", label: "Power off", sure: "Click again to power off" }
    ]
    width: 210
    height: menuCol.implicitHeight + 12
    x: topRow.x + topRow.width - width + 4
    y: topRow.y + 36
    radius: Sizes.cardRadius
    color: Theme.surface   // solid, so the tiles don't show through
    border.width: 1
    border.color: Theme.edge
    opacity: dash.powerOpen ? 1 : 0
    Rectangle { anchors.fill: parent; anchors.margins: 1; radius: parent.radius - 1; color: Theme.surfaceRaised }
    scale: dash.powerOpen ? 1 : 0.94
    transformOrigin: Item.TopRight
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
    Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
    Column {
      id: menuCol
      x: 6; y: 6
      width: parent.width - 12
      spacing: 2
      Repeater {
        model: powerMenu.items
        Rectangle {
          id: pi
          required property var modelData
          required property int index
          readonly property bool armed: dash.armed === modelData.key
          width: menuCol.width
          height: 34
          radius: 12
          color: armed ? Theme.urgent : piTap.containsMouse ? Theme.surface : "transparent"
          Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
          // a line between System info and the rest
          Rectangle { visible: pi.index === 1; width: parent.width - 16; x: 8; y: -1; height: 1; color: Theme.edge }
          Icon { id: pic; x: 10; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; font.pixelSize: 17
                 color: pi.armed ? Theme.surface : piTap.containsMouse ? Theme.text : Theme.textDim }
          Text {
            anchors.left: pic.right; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: pi.armed ? modelData.sure : modelData.label
            color: pi.armed ? Theme.surface : Theme.text
            font.family: Theme.fontText; font.pixelSize: 12
            font.weight: pi.armed ? Font.DemiBold : Font.Normal
          }
          MouseArea { id: piTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dash.power(modelData.key) }
        }
      }
    }
  }

  // A pinned page you unpin while it's showing: back to Home.
  onPagesChanged: if (!pages.some(p => p.key === page)) page = "home"

  // The dashboard's real height, so the island can size itself to fit.
  // (tall enough for the power menu while it's open)
  readonly property int contentHeight: Math.max(pageArea.y + pageArea.height + Sizes.dashPadding,
                                                powerOpen ? powerMenu.y + powerMenu.height + Sizes.dashPadding : 0)
}
