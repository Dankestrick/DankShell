import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../"
import "../../config/Plugins.js" as Plugins
import "../../config/SettingsList.js" as SettingsList

// Center — the window that pops up in the middle of the screen, like
// saneAspect's Settings app. Search box and sidebar on the left, the page on
// the right. Holds every plugin page, Sound & Bluetooth, and Settings, so
// the island itself stays clean.
//
// Open it from the dashboard's buttons, or:
//   qs ipc -p /usr/share/omarchy/shell call dankshell center <page>
// Esc or a click outside closes it.
PanelWindow {
  id: win

  required property var modelData   // the monitor
  screen: modelData

  readonly property bool wanted: Popouts.center !== "" && Popouts.screen === modelData.name
  visible: wanted || card.opacity > 0

  // No anchors = Hyprland puts it in the middle of the screen.
  implicitWidth: Sizes.centerWidth
  implicitHeight: Sizes.centerHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "dankshell-center"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: wanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  HyprlandFocusGrab {
    windows: [win]
    active: win.wanted
    onCleared: Popouts.closeCenter()
  }

  // ── Every page, in sidebar order ──────────────
  readonly property var pages: {
    const out = []
    // Every plugin: full pages first, then your bar widgets.
    for (const p of WidgetHost.catalog)
      out.push({ key: p.key, group: "Plugins", name: p.name, icon: p.icon, sub: p.sub, words: p.kind, plugin: p,
                 url: p.kind === "page" ? Qt.resolvedUrl("../pages/" + p.key.charAt(0).toUpperCase() + p.key.slice(1) + ".qml")
                                        : Qt.resolvedUrl("WidgetPage.qml") })
    out.push({ key: "sound", group: "Device", name: "Sound & Bluetooth", icon: "tune",
               sub: "Where sound goes and which Bluetooth devices are on.",
               url: Qt.resolvedUrl("../pages/System.qml"), words: "audio output speaker headset bluetooth" })
    for (const s of SettingsList.SECTIONS)
      out.push({ key: s.key, group: "Settings", name: s.name, icon: s.icon, sub: s.sub,
                 url: Qt.resolvedUrl("../settings/SettingsPage.qml"), words: s.words, section: s })
    return out
  }
  readonly property var shown: {
    const q = search.text.trim().toLowerCase()
    return q === "" ? pages : pages.filter(p => (p.name + " " + p.words + " " + p.group).toLowerCase().includes(q))
  }
  readonly property var current: pages.find(p => p.key === Popouts.center) || null

  function go(d) {
    const i = shown.findIndex(p => p.key === Popouts.center)
    if (shown.length) Popouts.center = shown[(i + d + shown.length) % shown.length].key
  }

  onWantedChanged: if (wanted) { search.text = ""; search.forceActiveFocus() }

  // ── The card ──────────────────────────────────
  Rectangle {
    id: card
    anchors.fill: parent
    radius: Sizes.radiusExpanded
    color: Theme.surface
    border.width: 1
    border.color: Theme.edge
    clip: true

    opacity: win.wanted ? 1 : 0
    scale: win.wanted ? 1 : 0.94
    Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
    Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Motion.moveEasing; easing.overshoot: Motion.overshoot } }

    Keys.onEscapePressed: Popouts.closeCenter()

    // ── Sidebar ───────────────────────────────
    Item {
      id: side
      width: 224
      height: parent.height

      Rectangle {
        id: searchBox
        x: 14; y: 14
        width: parent.width - 28
        height: 36
        radius: 18
        color: Theme.surfaceRaised
        Icon { id: mag; x: 12; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: Theme.textDim }
        TextInput {
          id: search
          anchors.left: mag.right
          anchors.leftMargin: 8
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          color: Theme.text
          font.family: Theme.fontText
          font.pixelSize: 12
          clip: true
          onTextChanged: if (win.shown.length && !win.shown.some(p => p.key === Popouts.center)) Popouts.center = win.shown[0].key
          Keys.onUpPressed: win.go(-1)
          Keys.onDownPressed: win.go(1)
          Keys.onTabPressed: win.go(1)
          Keys.onEscapePressed: Popouts.closeCenter()
          Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: search.text === ""
            text: "Search"
            color: Theme.textDim
            font: search.font
          }
        }
      }

      Flickable {
        id: sideFlick
        anchors.top: searchBox.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: parent.width
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: list
          x: 10
          width: parent.width - 20
          spacing: 2
          Repeater {
            model: win.shown
            Column {
              required property var modelData
              required property int index
              width: list.width
              // Group name above the first page of each group.
              Text {
                visible: index === 0 || win.shown[index - 1].group !== modelData.group
                height: visible ? 28 : 0
                leftPadding: 10
                verticalAlignment: Text.AlignBottom
                bottomPadding: 6
                text: modelData.group
                color: Theme.textDim
                font.family: Theme.fontText
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
              }
              Rectangle {
                id: sideItem
                readonly property bool here: Popouts.center === modelData.key
                // Keep the picked page in view in a long list.
                onHereChanged: if (here) Qt.callLater(() => {
                  const y = sideItem.mapToItem(list, 0, 0).y
                  if (y < sideFlick.contentY) sideFlick.contentY = Math.max(0, y - 30)
                  else if (y + height > sideFlick.contentY + sideFlick.height)
                    sideFlick.contentY = Math.min(sideFlick.contentHeight - sideFlick.height, y + height - sideFlick.height + 10)
                })
                Component.onCompleted: if (here) hereChanged()
                width: parent.width
                height: 38
                radius: 19
                color: here ? Theme.surfaceRaised : tap.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
                Rectangle {
                  id: dot
                  x: 6
                  anchors.verticalCenter: parent.verticalCenter
                  width: 28; height: 28; radius: 14
                  color: parent.here ? Theme.accent : Theme.surfaceRaised
                  Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
                  Icon { anchors.centerIn: parent; name: modelData.icon; filled: parent.parent.here; color: parent.parent.here ? Theme.surface : Theme.textDim; font.pixelSize: 15 }
                }
                Text {
                  anchors.left: dot.right
                  anchors.leftMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.name
                  color: parent.here ? Theme.text : Theme.textDim
                  font.family: Theme.fontText
                  font.pixelSize: 12
                  font.weight: parent.here ? Font.DemiBold : Font.Normal
                }
                MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Popouts.center = modelData.key }
              }
            }
          }
        }
      }
    }
    Rectangle { x: side.width; y: 14; width: 1; height: parent.height - 28; color: Theme.edge }

    // ── The page ──────────────────────────────
    Flickable {
      id: pane
      x: side.width + 1
      width: parent.width - x
      height: parent.height
      contentHeight: body.implicitHeight + 32
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: body
        x: 18; y: 16
        width: pane.width - 36
        spacing: 14

        // Header card: big round icon, the name, one line about it.
        Rectangle {
          width: parent.width
          height: 132
          radius: Sizes.cardRadius + 4
          color: Theme.surfaceRaised
          // Pin to the island's top row (plugins only).
          Rectangle {
            visible: !!(win.current && win.current.plugin)
            readonly property bool on: { void(Settings.v.pinned); return !!win.current && Settings.isPinned(win.current.key) }
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            width: pinRow.implicitWidth + 20
            height: 28
            radius: 14
            color: on ? Theme.accent : pinTap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surface
            Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
            Row {
              id: pinRow
              anchors.centerIn: parent
              spacing: 4
              Icon { name: "push_pin"; filled: parent.parent.on; color: parent.parent.on ? Theme.surface : Theme.textDim; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
              Text { text: parent.parent.on ? "In top row" : "Pin to top row"; color: parent.parent.on ? Theme.surface : Theme.text; font.family: Theme.fontText; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: pinTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.setPinned(win.current.key, !parent.on) }
          }
          Rectangle {
            id: bigIcon
            anchors.horizontalCenter: parent.horizontalCenter
            y: 18
            width: 46; height: 46; radius: 23
            color: Theme.surface
            Icon { anchors.centerIn: parent; name: win.current ? win.current.icon : ""; color: Theme.accent; font.pixelSize: 22 }
          }
          Text {
            id: title
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: bigIcon.bottom
            anchors.topMargin: 10
            text: win.current ? win.current.name : ""
            color: Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: 17
            font.weight: Font.DemiBold
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: title.bottom
            anchors.topMargin: 4
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: win.current ? win.current.sub : ""
            visible: text !== ""
            color: Theme.textDim
            font.family: Theme.fontText
            font.pixelSize: 11
          }
        }

        Loader {
          id: pageLoader
          width: parent.width
          property string key: ""
          // Only load a page while the window is up; switching pages swaps it.
          active: win.visible && !!win.current
          onActiveChanged: load()
          Connections { target: win; function onCurrentChanged() { pageLoader.load(); pane.contentY = 0 } }
          function load() {
            if (!active || !win.current) return
            key = win.current.key
            const props = win.current.section ? { section: win.current.section }
                        : win.current.plugin && win.current.plugin.kind === "widget" ? { plugin: win.current.plugin } : {}
            setSource(win.current.url, props)
          }
          onLoaded: {
            item.width = Qt.binding(() => pageLoader.width)
            if ("showing" in item) item.showing = Qt.binding(() => win.wanted)
            if (item.closeRequested) item.closeRequested.connect(Popouts.closeCenter)
          }
        }
      }
    }
  }
}
