import QtQuick
import "../../"

// Dashboard — what the island opens into when you click it.
// The clock isn't in here: it's the same clock from the pill, sliding into
// the top-left corner (see Island.qml). This file leaves room for it.
//
// Top left:  the date under the clock (click it for the Journal).
// Top right: your pinned plugins, then themes, wallpapers, device (Games,
// Camera, System...), plugins, settings.
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

  function reset() { page = "home" }

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
  // A pinned page you unpin while it's showing: back to Home.
  onPagesChanged: if (!pages.some(p => p.key === page)) page = "home"

  // The dashboard's real height, so the island can size itself to fit.
  readonly property int contentHeight: pageArea.y + pageArea.height + Sizes.dashPadding
}
