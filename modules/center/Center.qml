import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../"
import "../../config/Plugins.js" as Plugins
import "../../config/SettingsList.js" as SettingsList

// Center — the window that pops up in the middle of the screen, like
// saneAspect's Settings app. Search box and sidebar on the left, the page on
// the right. Opens as Plugins, Settings, or Notifications/Sound, so
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
    // Off while a plugin's dropdown is open in the window.
    active: win.wanted && !WidgetHost.popoutOpen
    onCleared: if (!WidgetHost.popoutOpen) Popouts.closeCenter()
  }

  // ── Every page, in sidebar order ──────────────
  // Three kinds of window, each with only its own things in the sidebar:
  //   plugins:  your installed plugins (Running, Not running, Omarchy)
  //   settings: the Settings sections
  //   device:   Notifications, Sound & Bluetooth
  readonly property var allPages: {
    const out = [{ key: "allplugins", mode: "plugins", group: "Plugins", name: "All plugins", icon: "apps",
                   sub: "Everything you have installed. Click one to use it.", words: "all grid overview",
                   url: Qt.resolvedUrl("PluginGrid.qml") },
                 { key: "getplugins", mode: "plugins", group: "Plugins", name: "Updates", icon: "system_update",
                   sub: "Plugins and git installs with updates. Tick what you want, then update.",
                   words: "update updates upgrade download git pull plugins installs refresh",
                   url: Qt.resolvedUrl("GetPlugins.qml") }]
    for (const p of Installed.items)
      out.push({ key: p.key, mode: "plugins", group: p.group, name: p.name, icon: p.icon, sub: p.sub,
                 words: p.id + " " + p.description, plugin: p, pinnable: !!WidgetHost.item(p.key),
                 url: p.use === "page" ? Qt.resolvedUrl("../pages/" + p.key.charAt(0).toUpperCase() + p.key.slice(1) + ".qml")
                                       : Qt.resolvedUrl("PluginPage.qml") })
    out.push({ key: "notifications", mode: "device", group: "Device", name: "Notifications", icon: "notifications",
               sub: "Click to read it all, click again to clear it. × clears it right away.",
               url: Qt.resolvedUrl("../pages/Notifications.qml"), words: "notification alerts messages clear" })
    out.push({ key: "monitor", mode: "device", group: "Device", name: "System", icon: "monitoring",
               sub: "CPU, memory and GPU, live.",
               url: Qt.resolvedUrl("../pages/Monitor.qml"), words: "cpu gpu ram memory vram temp temperature monitor load" })
    out.push({ key: "game", mode: "device", group: "Device", name: "Games", icon: "sports_esports",
               sub: "Game Mode, your controller, and your Steam games.",
               url: Qt.resolvedUrl("../pages/Game.qml"), words: "game mode steam play controller dualsense" })
    out.push({ key: "camera", mode: "device", group: "Device", name: "Camera", icon: "videocam",
               sub: "Your webcam: live picture, every setting, saved looks.",
               url: Qt.resolvedUrl("../pages/Camera.qml"), words: "camera webcam anker video brightness exposure focus zoom look" })
    out.push({ key: "sound", mode: "device", group: "Device", name: "Audio", icon: "volume_up",
               sub: "Outputs, mics, app volumes and the EQ.",
               url: Qt.resolvedUrl("../pages/Audio.qml"), words: "audio sound output speaker headset mic microphone volume eq equalizer autoeq hearing" })
    out.push({ key: "bluetooth", mode: "device", group: "Device", name: "Bluetooth", icon: "bluetooth",
               sub: "Which Bluetooth devices are on.",
               url: Qt.resolvedUrl("../pages/System.qml"), words: "bluetooth pair devices controller headphones" })
    for (const sec of SettingsList.SECTIONS)
      out.push({ key: sec.key, mode: "settings", group: "Settings", name: sec.name, icon: sec.icon, sub: sec.sub,
                 url: Qt.resolvedUrl("../settings/SettingsPage.qml"), section: sec,
                 // search finds single settings too
                 words: sec.words + " " + sec.items.map(i => i.label || "").join(" ") })
    out.push({ key: "keys", mode: "settings", group: "Settings", name: "Keys", icon: "keyboard",
               sub: "Every keyboard shortcut you have. Type in the search box to find one.",
               url: Qt.resolvedUrl("../settings/Keys.qml"), words: "keys keyboard shortcuts keybindings bindings hotkeys super" })
    return out
  }
  // "@plugins" / "@settings" open a window on its first page.
  function resolveStart() {
    if (Popouts.center.charAt(0) !== "@") return
    const first = allPages.find(p => p.mode === Popouts.center.slice(1))
    if (first) Popouts.center = first.key
  }
  Connections { target: Popouts; function onCenterChanged() { win.resolveStart() } }
  onAllPagesChanged: resolveStart()   // the plugin list can arrive a moment later
  readonly property var current: allPages.find(p => p.key === Popouts.center) || null
  property string mode: "plugins"
  onCurrentChanged: {
    if (current) { mode = current.mode; if (wanted) Popouts.mode = mode; if (mode === "device") Popouts.lastDevice = current.key }
    else if (wanted) lostPage.restart()
  }
  readonly property var pages: allPages.filter(p => p.mode === mode)
  readonly property var shown: {
    const q = search.text.trim().toLowerCase()
    // the page you're on stays in the list while you type (Updates filters with the same box)
    return q === "" ? pages : pages.filter(p => p.key === Popouts.center || (p.name + " " + p.words + " " + p.group).toLowerCase().includes(q))
  }

  function go(d) {
    const i = shown.findIndex(p => p.key === Popouts.center)
    if (shown.length) Popouts.center = shown[(i + d + shown.length) % shown.length].key
  }

  onWantedChanged: if (wanted) { search.text = ""; search.forceActiveFocus(); Installed.reload(); PluginManager.checkUpdates(false) }
  // The page you were on went away (its plugin was removed): go to Updates.
  Timer {
    id: lostPage
    interval: 1200
    onTriggered: if (win.wanted && Popouts.center !== "" && Popouts.center.charAt(0) !== "@" && !win.current) Popouts.center = "getplugins"
  }
  Connections {
    target: PluginManager
    function onJobChanged() {
      const j = PluginManager.job
      if (j.action === "remove" && j.state === "done" && win.current && win.current.plugin && win.current.plugin.id === j.target)
        Popouts.center = "getplugins"
    }
  }

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

    // Right-click anywhere = back to the dashboard (or just close if a key opened it).
    // Only takes the right button, so left clicks and the wheel go through.
    MouseArea {
      anchors.fill: parent
      z: 100
      acceptedButtons: Qt.RightButton
      onPressed: (m) => m.accepted = !Popouts.rightClickHere   // let a button's own right-click have it
      onClicked: Popouts.back()
    }

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
          // Page Up / Page Down / Home / End scroll the page on the right.
          Keys.onPressed: (e) => {
            const step = pane.height * 0.85, maxY = Math.max(0, pane.contentHeight - pane.height)
            if (e.key === Qt.Key_PageDown) { pane.contentY = Math.min(maxY, pane.contentY + step); e.accepted = true }
            else if (e.key === Qt.Key_PageUp) { pane.contentY = Math.max(0, pane.contentY - step); e.accepted = true }
            else if (e.key === Qt.Key_End && search.text === "") { pane.contentY = maxY; e.accepted = true }
            else if (e.key === Qt.Key_Home && search.text === "") { pane.contentY = 0; e.accepted = true }
          }
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
                  width: parent.width - 100
                  elide: Text.ElideRight
                  text: modelData.name
                  color: parent.here ? Theme.text : Theme.textDim
                  font.family: Theme.fontText
                  font.pixelSize: 12
                  font.weight: parent.here ? Font.DemiBold : Font.Normal
                }
                // Live status (battery, playing, unread...) on the right.
                Text {
                  readonly property var st: modelData.plugin ? Status.of(modelData.key) : ({ text: "", alert: false })
                  anchors.right: parent.right
                  anchors.rightMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  visible: text !== ""
                  text: st.text
                  color: st.alert ? Theme.accent : Theme.textDim
                  font.family: Theme.fontText
                  font.pixelSize: 10
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
        // Fades while a plugin's dropdown has the right side.
        Rectangle {
          width: parent.width
          opacity: WidgetHost.popoutOpen && win.current && win.current.plugin && win.current.plugin.use === "widget" ? 0 : 1
          Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
          height: 132
          radius: Sizes.cardRadius + 4
          color: Theme.surfaceRaised
          // Update / Remove (your plugins only; Omarchy's built-ins can't be removed).
          // Remove asks first, right here.
          Row {
            id: manage
            readonly property var plug: win.current && win.current.plugin ? win.current.plugin : null
            property bool confirming: false
            visible: !!plug && PluginManager.canRemove(plug)
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 6
            Connections { target: win; function onCurrentChanged() { manage.confirming = false } }
            component MBtn: Rectangle {
              id: mb
              property string label: ""
              property string icon: ""
              property color fill: Theme.surface
              property color ink: Theme.text
              signal clicked()
              width: mbr.implicitWidth + 20; height: 28; radius: 14
              opacity: enabled ? 1 : 0.4
              color: mbTap.containsMouse && fill === Theme.surface ? Qt.lighter(Theme.surfaceRaised, 1.6) : fill
              Row { id: mbr; anchors.centerIn: parent; spacing: 4
                Icon { visible: mb.icon !== ""; name: mb.icon; color: mb.ink; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                Text { text: mb.label; color: mb.ink; font.family: Theme.fontText; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
              }
              MouseArea { id: mbTap; anchors.fill: parent; hoverEnabled: true; enabled: mb.enabled; cursorShape: Qt.PointingHandCursor; onClicked: mb.clicked() }
            }
            MBtn {
              visible: !manage.confirming && !!manage.plug && PluginManager.hasUpdate(manage.plug.id)
              icon: "download"; label: "Update"; fill: Theme.accent; ink: Theme.surface
              enabled: !PluginManager.busy
              onClicked: PluginManager.update(manage.plug.id)
            }
            MBtn {
              visible: !manage.confirming
              icon: "delete"; label: "Remove"
              enabled: !PluginManager.busy
              onClicked: manage.confirming = true
            }
            Text { visible: manage.confirming; anchors.verticalCenter: parent.verticalCenter; text: "Remove it for good?"; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11 }
            MBtn {
              visible: manage.confirming
              icon: "delete"; label: "Remove"; fill: Theme.urgent; ink: Theme.surface
              onClicked: { PluginManager.remove(manage.plug.id); manage.confirming = false }
            }
            MBtn { visible: manage.confirming; label: "Cancel"; onClicked: manage.confirming = false }
          }
          // What the last install/update/remove did.
          Text {
            visible: PluginManager.jobText !== "" && !!manage.plug && (PluginManager.job.target === manage.plug.id || PluginManager.busy)
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 12
            width: parent.width / 2 - 40; elide: Text.ElideRight
            text: PluginManager.jobText
            color: PluginManager.job.state === "failed" ? Theme.urgent : Theme.textDim
            font.family: Theme.fontText; font.pixelSize: 10
          }

          // Pin to the island's top row (plugins only).
          Rectangle {
            visible: !!(win.current && win.current.pinnable)
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
            MouseArea {
              id: pinTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                const k = win.current.key
                if (!parent.on && Glance.has(k)) pinAsk.key = k   // in the Glance row too: ask first
                else Settings.setPinned(k, !parent.on)
              }
            }
          }
          // "Already in the Glance row" question, under the Pin button.
          AskDouble {
            id: pinAsk
            property string key: ""
            visible: key !== "" && !!win.current && win.current.key === key
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 46
            anchors.rightMargin: 12
            width: 300
            z: 5
            otherRow: "Glance row"
            onMove: { Glance.remove(key); Settings.setPinned(key, true); key = "" }
            onBoth: { Settings.setPinned(key, true); key = "" }
            onCancel: key = ""
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
            const props = win.current.section ? { section: win.current.section, filter: search.text }
                        : win.current.plugin && win.current.plugin.use !== "page" ? { plugin: win.current.plugin } : {}
            setSource(win.current.url, props)
          }
          onLoaded: {
            if ("filter" in item) item.filter = Qt.binding(() => search.text)
            item.width = Qt.binding(() => pageLoader.width)
            if ("showing" in item) item.showing = Qt.binding(() => win.wanted)
            if (item.closeRequested) item.closeRequested.connect(Popouts.closeCenter)
          }
        }
      }
    }
  }
}
