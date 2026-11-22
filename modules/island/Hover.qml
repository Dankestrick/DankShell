import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"

// Hover — the medium card the pill grows into when you rest the mouse on it.
// Left: big clock (the shared clock from Island.qml slides here) + date.
// Right: what's playing. Bottom: one pill per monitor (MonitorPills); hover
// one and the card grows down to show that monitor's window live.
// (saneAspect: hover shows a little, the big dashboard waits for a click.)
Item {
  id: hoverCard

  property string screenName: ""
  property bool showing: false
  // The card grows: a row for tray apps + containers when there are any,
  // then the window peek or an app's menu below the pills.
  readonly property int baseExtra: tray.count > 0 ? 28 : 0
  readonly property int extra: baseExtra + (menuBox.open ? menuBox.height + 12 : peek.open ? peek.height + 12 : 0)
  onShowingChanged: { Docker.watching = showing; if (!showing) menuBox.close() }

  // ── Left: date under the clock ────────────────
  Text {
    x: 20
    y: 50
    text: Time.dateLong
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 11
  }

  // ── Right: now playing ────────────────────────
  Row {
    id: nowPlaying
    visible: Media.showing
    anchors.right: parent.right
    anchors.rightMargin: 16
    anchors.top: parent.top
    anchors.topMargin: 14
    spacing: 10
    layoutDirection: Qt.RightToLeft

    // album art, tap to play/pause
    Rectangle {
      width: 38; height: 38; radius: 10
      color: Theme.surfaceRaised
      clip: true
      Image {
        anchors.fill: parent
        source: Media.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
      }
      Icon {
        anchors.centerIn: parent
        name: Media.playing ? "pause" : "play_arrow"
        filled: true
        color: "white"
        opacity: artTap.containsMouse || !Media.playing ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
      }
      MouseArea {
        id: artTap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Media.toggle()
      }
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(180, Math.max(titleText.implicitWidth, artistText.implicitWidth))
      Text {
        id: titleText
        width: parent.width
        horizontalAlignment: Text.AlignRight
        text: Media.title
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.fontText
        font.pixelSize: 12
        font.weight: Font.DemiBold
      }
      Text {
        id: artistText
        width: parent.width
        horizontalAlignment: Text.AlignRight
        text: Media.artist
        elide: Text.ElideRight
        color: Theme.textDim
        font.family: Theme.fontText
        font.pixelSize: 11
      }
    }
  }

  // ── Bottom: one pill per monitor ──────────────
  // Fixed spot (the card grows below it), so the pills never move out from
  // under the mouse when the peek opens.
  // ── Tray apps + running containers ────────────
  GlanceRow {
    id: tray
    visible: count > 0
    anchors.horizontalCenter: parent.horizontalCenter
    y: Sizes.hoverHeight - 34
    z: 2
    onMenuRequested: (item) => menuBox.show(item)
  }
  // The name of the icon under the mouse, in the empty space beside the row.
  Text {
    visible: tray.hoverName !== ""
    anchors.left: tray.right; anchors.leftMargin: 8
    anchors.verticalCenter: tray.verticalCenter
    width: parent.width - tray.x - tray.width - 24
    elide: Text.ElideRight
    text: tray.hoverName
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
  }

  MonitorPills {
    id: pills
    active: hoverCard.showing
    anchors.horizontalCenter: parent.horizontalCenter
    y: Sizes.hoverHeight + hoverCard.baseExtra - height - 10
    z: 2
  }

  // ── An app's tray menu (right-click its icon) ──
  // Drawn here, not as a system menu: the shell can't show those (see
  // Omarchy's Tray.qml). A submenu opens in place, with Back on top.
  Item {
    id: menuBox
    property var item: null
    property var stack: []            // submenus opened, deepest last
    readonly property bool open: item !== null
    function show(i) { stack = []; item = i }
    function close() { item = null; stack = [] }
    x: 16
    y: Sizes.hoverHeight + hoverCard.baseExtra + 2
    width: parent.width - 32
    height: Math.min(240, list.implicitHeight + 16)
    visible: open
    z: 3

    QsMenuOpener {
      id: opener
      menu: menuBox.stack.length ? menuBox.stack[menuBox.stack.length - 1] : (menuBox.item ? menuBox.item.menu : null)
    }
    Rectangle { anchors.fill: parent; radius: 12; color: Theme.surfaceRaised }
    Flickable {
      anchors.fill: parent
      anchors.margins: 8
      contentHeight: list.implicitHeight
      clip: true
      Column {
        id: list
        width: parent.width
        // Back, when inside a submenu
        Rectangle {
          visible: menuBox.stack.length > 0
          width: parent.width; height: visible ? 26 : 0; radius: 8
          color: backTap.containsMouse ? Theme.surface : "transparent"
          Row { x: 6; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            Icon { name: "arrow_back"; font.pixelSize: 14; color: Theme.textDim; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Back"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
          }
          MouseArea { id: backTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: menuBox.stack = menuBox.stack.slice(0, -1) }
        }
        Repeater {
          model: opener.children
          Item {
            required property var modelData
            width: list.width
            height: modelData.isSeparator ? 9 : 26
            Rectangle { visible: modelData.isSeparator; width: parent.width; height: 1; color: Theme.edge; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
              visible: !modelData.isSeparator
              anchors.fill: parent; radius: 8
              color: entryTap.containsMouse && modelData.enabled ? Theme.surface : "transparent"
              opacity: modelData.enabled ? 1 : 0.45
              Text {
                x: 8; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 30; elide: Text.ElideRight
                text: (modelData.checkState === Qt.Checked ? "✓  " : "") + String(modelData.text).replace(/&(?!&)/g, "")
                color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11
              }
              Icon { visible: modelData.hasChildren; name: "chevron_right"; font.pixelSize: 14; color: Theme.textDim; anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter }
              MouseArea {
                id: entryTap; anchors.fill: parent; hoverEnabled: true
                enabled: modelData.enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (modelData.hasChildren) menuBox.stack = menuBox.stack.concat([modelData])
                  else { modelData.triggered(); menuBox.close() }
                }
              }
            }
          }
        }
      }
    }
  }

  // ── Peek: every window on the hovered pill's monitor, live ──
  Item {
    id: peek
    readonly property string mon: hoverCard.showing ? pills.peekMonitor : ""
    readonly property var wins: mon ? pills.windowsOn(mon) : []
    readonly property bool open: mon !== "" && !menuBox.open
    x: 16
    y: Sizes.hoverHeight + hoverCard.baseExtra + 2
    width: parent.width - 32
    height: 168
    opacity: open ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }

    // The mouse on the peek keeps it open (so you can look without the pill).
    HoverHandler { id: peekHover; onHoveredChanged: pills.peekHeld = hovered && peek.open }

    function aspectOf(t) { const sz = (t.lastIpcObject || {}).size; return sz && sz[1] > 0 ? sz[0] / sz[1] : 16 / 9 }
    readonly property real totalAspect: wins.reduce((n, t) => n + aspectOf(t), 0)
    readonly property int gap: 8
    // One height for every window, as big as fits the frame.
    readonly property real tileH: wins.length ? Math.min(frame.height - 16, (frame.width - 16 - gap * (wins.length - 1)) / Math.max(0.1, totalAspect)) : 0

    Rectangle {
      id: frame
      width: parent.width
      height: 140
      radius: 12
      color: Theme.surfaceRaised
      clip: true
      Row {
        anchors.centerIn: parent
        spacing: peek.gap
        Repeater {
          model: peek.open ? peek.wins : []
          Rectangle {
            required property var modelData
            width: Math.round(peek.tileH * peek.aspectOf(modelData)); height: Math.round(peek.tileH)
            radius: 6
            color: Theme.surface
            clip: true
            ScreencopyView {
              anchors.fill: parent
              captureSource: modelData.wayland || null
              live: true
              // Drawn through a layer: a see-through window (Ghostty) would
              // otherwise punch a hole in the card and show the desktop.
              layer.enabled: true
            }
          }
        }
      }
      Text {
        anchors.centerIn: parent
        visible: peek.wins.length === 0
        text: "Nothing open here"
        color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
      }
    }
    Text {
      anchors.top: frame.bottom
      anchors.topMargin: 6
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      function nameOf(t) { const o = t.lastIpcObject || {}; return String(o.class || t.title || "").replace(/^.*\./, "") }
      text: peek.wins.length === 0 ? peek.mon
          : peek.wins.length === 1 ? (peek.wins[0].title || nameOf(peek.wins[0])) + "   (" + peek.mon + ")"
          : peek.wins.map(nameOf).join("  ·  ") + "   (" + peek.mon + ")"
      color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11
    }
  }
}
