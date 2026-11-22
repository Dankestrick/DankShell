import QtQuick
import "../../"

// ThemePage — one theme's tab in the Themes window (palette button on the
// dashboard). Use the theme, see its colors, and pick one of its wallpapers.
// Picking a wallpaper of a theme you're not on puts the theme on first, then
// that wallpaper. The search box finds wallpapers from every theme and
// DankWallpapers.
Column {
  id: page
  property bool showing: false
  property string slug: ""
  spacing: 10

  readonly property var t: Themes.list.find(x => x.slug === slug) || null
  readonly property bool inUse: Themes.current === slug
  readonly property bool busy: Themes.applying !== "" || Wallpapers.applying !== ""
  property string query: ""

  onShowingChanged: if (showing) Wallpapers.reload()

  readonly property var walls: {
    const q = query.trim().toLowerCase()
    if (q === "") return Wallpapers.items.filter(w => w.theme === slug)
    return Wallpapers.items.filter(w => (w.name + " " + w.theme).toLowerCase().includes(q))
  }
  function themeName(s) { const x = Themes.list.find(y => y.slug === s); return x ? x.name : s === "" ? "DankWallpapers" : s }
  function pick(w) {
    if (busy) return
    // A wallpaper of another theme (or ours while it's off): theme first, then the picture.
    const theme = w.theme !== "" ? w.theme : (inUse ? "" : slug)
    if (theme !== "" && theme !== Themes.current) Themes.apply(theme, w.path)
    else Wallpapers.apply(w.path)
  }

  component Head: Text { color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase; leftPadding: 4 }

  // ── Use it ────────────────────────────────────
  Card {
    width: parent.width
    Item {
      width: parent.width; height: 44
      DeviceHeader {
        width: parent.width - useBtn.width - 12
        icon: "palette"
        active: page.inUse
        title: page.t ? page.t.name : page.slug
        subtitle: Themes.applying === page.slug ? "Putting it on…"
                : page.inUse ? "In use" : (page.t && page.t.colors.mode === "light" ? "Light theme" : "Dark theme")
      }
      Rectangle {
        id: useBtn
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: useRow.implicitWidth + 24; height: 32; radius: 16
        color: page.inUse ? Theme.surface : useTap.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
        opacity: page.busy && !page.inUse ? 0.5 : 1
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
        Row {
          id: useRow; anchors.centerIn: parent; spacing: 6
          Icon { name: page.inUse ? "check" : "palette"; font.pixelSize: 16; color: page.inUse ? Theme.accent : Theme.surface; anchors.verticalCenter: parent.verticalCenter }
          Text { text: page.inUse ? "In use" : "Use this theme"; color: page.inUse ? Theme.text : Theme.surface; font.family: Theme.fontText; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: useTap; anchors.fill: parent; hoverEnabled: true; enabled: !page.inUse && !page.busy; cursorShape: Qt.PointingHandCursor; onClicked: Themes.apply(page.slug) }
      }
    }
  }

  // ── Colors ────────────────────────────────────
  Card {
    width: parent.width
    visible: !!page.t
    Head { text: "Colors" }
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Math.max(0, (parent.width - 9 * 50) / 8)
      Repeater {
        model: ["background", "foreground", "accent", "red", "yellow", "green", "cyan", "blue", "magenta"]
        Column {
          required property var modelData
          spacing: 4
          width: 50
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 30; height: 30; radius: 15
            color: Themes.color(page.t, modelData)
            border.width: 1; border.color: Theme.edge
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData === "background" ? "back" : modelData === "foreground" ? "text" : modelData
            color: Theme.textDim
            font.family: Theme.fontText; font.pixelSize: 9
          }
        }
      }
    }
  }

  // ── Wallpapers ────────────────────────────────
  Card {
    width: parent.width
    Head { text: page.query === "" ? "Wallpapers · click one to put it up" : "Every wallpaper matching “" + page.query + "”" }
    Rectangle {
      width: parent.width; height: 34; radius: 17
      color: Theme.surface
      Icon { id: mag; x: 12; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: Theme.textDim; font.pixelSize: 16 }
      TextInput {
        id: q
        anchors.left: mag.right; anchors.leftMargin: 8; anchors.right: parent.right; anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text; font.family: Theme.fontText; font.pixelSize: 12; clip: true
        onTextChanged: page.query = text
        Keys.onEscapePressed: text = ""
        Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; visible: q.text === ""; text: "Search all wallpapers"; color: Theme.textDim; font: q.font }
      }
    }
    Text {
      visible: page.walls.length === 0
      leftPadding: 4
      text: page.query === "" ? "This theme has no wallpapers" : "Nothing matches"
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
    }
    Grid {
      id: grid
      width: parent.width
      columns: 3
      spacing: 8
      readonly property real cellW: (width - spacing * (columns - 1)) / columns
      Repeater {
        model: page.walls
        Rectangle {
          id: cell
          required property var modelData
          readonly property bool on: Wallpapers.current === modelData.path
          readonly property bool going: Wallpapers.applying === modelData.path || (Themes.applying !== "" && Themes.thenWallpaper === modelData.path)
          width: grid.cellW; height: Math.round(width * 9 / 16) + 22
          radius: 12
          color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : cellTap.containsMouse ? Theme.surface : "transparent"
          Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
          Rectangle {
            id: pic
            x: 4; y: 4
            width: parent.width - 8; height: Math.round(parent.width * 9 / 16) - 4
            radius: 9
            clip: true
            color: Theme.surface
            border.width: cell.on ? 2 : 0
            border.color: Theme.accent
            Image {
              anchors.fill: parent; anchors.margins: cell.on ? 2 : 0
              source: "file://" + cell.modelData.path
              sourceSize.width: 360
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
            }
            Rectangle {
              visible: cell.going
              anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.5)
              Text { anchors.centerIn: parent; text: "Putting it up…"; color: "white"; font.family: Theme.fontText; font.pixelSize: 11 }
            }
          }
          Text {
            anchors.left: parent.left; anchors.leftMargin: 6; anchors.right: parent.right; anchors.rightMargin: 6
            anchors.bottom: parent.bottom; anchors.bottomMargin: 4
            elide: Text.ElideRight
            text: (cell.on ? "✓ " : "") + cell.modelData.name + (page.query !== "" && cell.modelData.theme !== page.slug ? "  ·  " + page.themeName(cell.modelData.theme) : "")
            color: cell.on ? Theme.accent : Theme.textDim
            font.family: Theme.fontText; font.pixelSize: 10
          }
          MouseArea { id: cellTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.pick(cell.modelData) }
        }
      }
    }
  }
}
