import QtQuick
import Quickshell.Widgets
import "../../"

// WallpaperSwitcher — saneAspect's wallpaper strip. The island stretches
// wide; the picked wallpaper sits big in the middle, its neighbors smaller
// and dimmer on each side, a dot marks the one on screen.
//
// Type to filter · ← → to move · Tab flips This theme / All ·
// Enter or click the big one to set it · Esc to close.
Item {
  id: sw

  signal closeRequested()

  property bool all: false
  readonly property int bigW: 300
  readonly property int bigH: 170
  readonly property int smallW: 200
  readonly property int smallH: 124

  readonly property var shown: {
    const q = search.text.trim().toLowerCase()
    return Wallpapers.items.filter(w => (all || w.mine) && (q === "" || w.name.toLowerCase().includes(q)))
  }
  readonly property var picked: shown.length ? shown[Math.max(0, Math.min(strip.currentIndex, shown.length - 1))] : null

  readonly property int contentHeight: 62 + bigH + 16 + 32

  function reset() {
    search.text = ""
    all = false
    Wallpapers.reload()
    jumpToCurrent()
    search.forceActiveFocus()
  }
  function jumpToCurrent() {
    const i = shown.findIndex(w => w.path === Wallpapers.current)
    strip.currentIndex = Math.max(0, i)
    strip.positionViewAtIndex(strip.currentIndex, ListView.Center)
  }
  function move(d) { if (shown.length) strip.currentIndex = (strip.currentIndex + d + shown.length) % shown.length }
  function applyPicked() { if (picked) Wallpapers.apply(picked.path) }

  Connections { target: Wallpapers; function onItemsChanged() { if (search.text === "") sw.jumpToCurrent() } }
  onAllChanged: Qt.callLater(jumpToCurrent)

  // ── Search + filter ───────────────────────────
  Item {
    id: bar
    width: parent.width
    height: 52
    Icon { id: mag; x: 22; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: Theme.textDim }
    TextInput {
      id: search
      anchors.left: mag.right
      anchors.leftMargin: 10
      anchors.right: filter.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      color: Theme.text
      font.family: Theme.fontText
      font.pixelSize: 13
      clip: true
      onTextChanged: strip.currentIndex = 0
      Keys.onLeftPressed: sw.move(-1)
      Keys.onRightPressed: sw.move(1)
      Keys.onTabPressed: sw.all = !sw.all
      Keys.onReturnPressed: sw.applyPicked()
      Keys.onEnterPressed: sw.applyPicked()
      Keys.onEscapePressed: sw.closeRequested()
      Text {
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        visible: search.text === ""
        text: "Search wallpapers..."
        color: Theme.textDim
        font: search.font
      }
    }
    // This theme | All
    Row {
      id: filter
      anchors.right: count.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4
      Repeater {
        model: ["This theme", "All"]
        Rectangle {
          required property string modelData
          required property int index
          readonly property bool here: (index === 1) === sw.all
          width: t.implicitWidth + 20
          height: 26
          radius: 13
          color: here ? Theme.surfaceRaised : "transparent"
          Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
          Text { id: t; anchors.centerIn: parent; text: modelData; color: parent.here ? Theme.text : Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11; font.weight: parent.here ? Font.DemiBold : Font.Normal }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.all = index === 1 }
        }
      }
    }
    Text {
      id: count
      anchors.right: parent.right
      anchors.rightMargin: 22
      anchors.verticalCenter: parent.verticalCenter
      text: Wallpapers.applying !== "" ? "Setting…" : (sw.shown.length ? (strip.currentIndex + 1) + "/" + sw.shown.length : "0")
      color: Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 10
    }
    Rectangle { anchors.bottom: parent.bottom; x: 14; width: parent.width - 28; height: 1; color: Theme.edge }
  }

  // ── The strip ─────────────────────────────────
  ListView {
    id: strip
    anchors.top: bar.bottom
    anchors.topMargin: 10
    width: parent.width
    height: sw.bigH + 16
    orientation: ListView.Horizontal
    spacing: 14
    clip: true
    model: sw.shown
    cacheBuffer: 600
    // The picked one stays in the middle.
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: (width - sw.bigW) / 2
    preferredHighlightEnd: (width + sw.bigW) / 2
    highlightMoveDuration: Motion.ms(Motion.move)
    boundsBehavior: Flickable.StopAtBounds
    WheelHandler { onWheel: (e) => sw.move(e.angleDelta.y > 0 || e.angleDelta.x > 0 ? -1 : 1) }

    delegate: Item {
      id: cell
      required property var modelData
      required property int index
      readonly property bool here: ListView.isCurrentItem
      readonly property int far: Math.abs(index - strip.currentIndex)
      width: here ? sw.bigW : sw.smallW
      height: strip.height
      Behavior on width { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }

      ClippingRectangle {
        id: frame
        anchors.centerIn: parent
        width: parent.width
        height: cell.here ? sw.bigH : sw.smallH
        radius: cell.here ? 22 : 16
        color: Theme.surfaceRaised
        clip: true
        opacity: cell.here ? 1 : cell.far === 1 ? 0.75 : 0.45
        Behavior on height { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }

        Image {
          anchors.fill: parent
          source: "file://" + cell.modelData.path
          sourceSize.width: 420
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
        }
        // The one on screen.
        Rectangle {
          visible: cell.modelData.path === Wallpapers.current
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.margins: 10
          width: 12; height: 12; radius: 6
          color: Theme.accent
          border.width: 2
          border.color: Theme.surface
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { if (cell.here) sw.applyPicked(); else strip.currentIndex = cell.index }
        }
      }
    }
  }

  // Name of the picked one.
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: strip.bottom
    anchors.topMargin: 2
    text: sw.picked ? sw.picked.name + (sw.picked.path === Wallpapers.current ? "  ·  on screen" : "") : (Wallpapers.items.length ? "Nothing matches" : "Loading…")
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 11
  }
}
