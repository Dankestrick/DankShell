import QtQuick
import "../../"

// ThemeSwitcher — saneAspect's theme switcher, on your Omarchy themes.
// A search box and a list. Each row: a little color chip, the name, and the
// theme's colors as dots. The row you're on grows: it takes the theme's own
// background color, the name goes big, the dots slide under it, and the
// wallpaper Omarchy remembers for that theme fades in on the right.
//
// Type to filter · ↑ ↓ to move · Enter or click to apply · Esc to close.
Item {
  id: sw

  signal closeRequested()

  property int index: 0
  readonly property int rowHeight: 44
  readonly property int bigHeight: 92
  readonly property int maxRows: 7

  readonly property var shown: {
    const q = search.text.trim().toLowerCase()
    return Themes.list.filter(t => q === "" || t.name.toLowerCase().includes(q))
  }
  readonly property var picked: shown.length ? shown[Math.min(index, shown.length - 1)] : null

  // Height the island should be: search bar + rows (one of them big).
  readonly property int contentHeight: 56 + Math.min(shown.length, maxRows) * (rowHeight + 4) + (shown.length ? bigHeight - rowHeight : 0) + 12

  function reset() {
    search.text = ""
    Themes.reload()
    const i = Themes.list.findIndex(t => t.slug === Themes.current)
    index = Math.max(0, i)
    search.forceActiveFocus()
  }
  function move(d) {
    if (!shown.length) return
    index = (index + d + shown.length) % shown.length
    list.positionViewAtIndex(index, ListView.Contain)
  }
  function applyPicked() { if (picked) Themes.apply(picked.slug) }

  Connections {
    target: Themes
    function onListChanged() {
      if (sw.index === 0 && search.text === "") {
        const i = Themes.list.findIndex(t => t.slug === Themes.current)
        if (i > 0) { sw.index = i; list.positionViewAtIndex(i, ListView.Center) }
      }
    }
  }

  // ── Search ────────────────────────────────────
  Item {
    id: bar
    width: parent.width
    height: 52
    Icon { id: mag; x: 20; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: Theme.textDim }
    TextInput {
      id: search
      anchors.left: mag.right
      anchors.leftMargin: 10
      anchors.right: count.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      color: Theme.text
      font.family: Theme.fontText
      font.pixelSize: 13
      clip: true
      onTextChanged: { sw.index = 0; list.positionViewAtBeginning() }
      Keys.onUpPressed: sw.move(-1)
      Keys.onDownPressed: sw.move(1)
      Keys.onTabPressed: sw.move(1)
      Keys.onReturnPressed: sw.applyPicked()
      Keys.onEnterPressed: sw.applyPicked()
      Keys.onEscapePressed: sw.closeRequested()
      Text {
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        visible: search.text === ""
        text: "Search themes..."
        color: Theme.textDim
        font: search.font
      }
    }
    Text {
      id: count
      anchors.right: parent.right
      anchors.rightMargin: 20
      anchors.verticalCenter: parent.verticalCenter
      text: Themes.applying !== "" ? "Applying…" : sw.shown.length + "/" + Themes.list.length
      color: Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 10
    }
    Rectangle { anchors.bottom: parent.bottom; x: 12; width: parent.width - 24; height: 1; color: Theme.edge }
  }

  // ── The list ──────────────────────────────────
  ListView {
    id: list
    anchors.top: bar.bottom
    anchors.topMargin: 6
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 8
    clip: true
    spacing: 4
    model: sw.shown
    boundsBehavior: Flickable.StopAtBounds
    highlightMoveDuration: Motion.ms(Motion.move)

    delegate: Rectangle {
      id: row
      required property var modelData
      required property int index
      readonly property bool here: index === sw.index
      readonly property bool inUse: modelData.slug === Themes.current
      readonly property color themeBg: Themes.color(modelData, "background")
      readonly property color themeFg: Themes.color(modelData, "foreground")
      readonly property color themeAccent: Themes.color(modelData, "accent")
      readonly property var dots: ["red", "green", "yellow", "cyan", "magenta", "blue"].map(k => Themes.color(modelData, k))

      width: ListView.view.width
      height: here ? sw.bigHeight : sw.rowHeight
      radius: here ? 18 : 12
      color: here ? themeBg : hover.containsMouse ? Theme.surfaceRaised : "transparent"
      clip: true
      Behavior on height { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }

      // The theme's wallpaper, fading in from the right (only on the big row).
      Image {
        id: wall
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.62
        source: row.here && row.modelData.wallpaper ? "file://" + row.modelData.wallpaper : ""
        sourceSize.width: 420
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: row.here && status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.move) } }
      }
      // Blend the wallpaper's left edge into the row color.
      Rectangle {
        anchors.right: wall.left
        anchors.rightMargin: -wall.width * 0.55
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: wall.width * 0.6
        visible: wall.opacity > 0
        opacity: wall.opacity
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: row.themeBg }
          GradientStop { position: 0.45; color: row.themeBg }
          GradientStop { position: 1.0; color: Qt.rgba(row.themeBg.r, row.themeBg.g, row.themeBg.b, 0) }
        }
      }

      // Small color chip (hidden on the big row, like his dot disappearing).
      Rectangle {
        id: chip
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30; radius: 9
        color: row.themeBg
        opacity: row.here ? 0 : 1
        scale: row.here ? 0.6 : 1
        Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
        Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
        Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 6; color: row.themeAccent }
      }

      // Name: small on a normal row, big in the theme's own color on the big row.
      Text {
        id: name
        x: row.here ? 18 : chip.width + 18
        y: row.here ? 16 : (row.height - height) / 2
        text: row.modelData.name + (row.inUse && !row.here ? "  ·  in use" : "")
        color: row.here ? row.themeFg : Theme.text
        font.family: row.here ? Theme.fontDisplay : Theme.fontText
        font.pixelSize: row.here ? 20 : 13
        font.weight: row.here ? Font.Bold : Font.DemiBold
        Behavior on x { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
        Behavior on font.pixelSize { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
      }

      // Color dots: on the right of a normal row, under the name on the big one.
      Row {
        spacing: row.here ? 6 : 4
        x: row.here ? 18 : row.width - width - 14
        y: row.here ? name.y + name.height + 10 : (row.height - height) / 2
        Behavior on x { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
        Repeater {
          model: row.dots
          Rectangle {
            required property var modelData
            width: row.here ? 12 : 7
            height: width
            radius: width / 2
            color: modelData
            Behavior on width { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
          }
        }
      }

      // "In use" tag on the big row.
      Text {
        visible: row.here && row.inUse
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        text: "In use"
        color: row.themeAccent
        font.family: Theme.fontText
        font.pixelSize: 10
        font.weight: Font.DemiBold
      }

      MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { if (row.here) sw.applyPicked(); else sw.index = row.index }
      }
    }
  }
}
