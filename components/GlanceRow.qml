import QtQuick
import Quickshell
import "../"

// GlanceRow — the Glance row in the hover card: what you picked in
// Settings › Glance row (tray apps and bar widgets, in your order), then the
// Docker containers that are running.
// Tray app: click opens/focuses it, right-click asks for its menu.
// Bar widget: shows its live icon/text (weather's temp); click opens its dropdown.
// Docker: click opens the container's page (or focuses it).
Row {
  id: row
  spacing: 6
  signal menuRequested(var item)
  property string hoverName: ""        // name of the icon under the mouse (Hover shows it)

  readonly property int count: Glance.shown.length + Docker.running.length

  component Slot: Rectangle {
    id: s
    property string name: ""
    property bool docker: false
    signal leftClick()
    signal rightClick()
    default property alias content: inner.data
    width: Math.max(24, inner.childrenRect.width + 8); height: 24; radius: 7
    color: tap.containsMouse ? Theme.surfaceRaised : "transparent"
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Item { id: inner; anchors.fill: parent }
    // a small dot marks a container
    Rectangle { visible: s.docker; width: 5; height: 5; radius: 2.5; color: Theme.accent; anchors.right: parent.right; anchors.bottom: parent.bottom }
    MouseArea {
      id: tap
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onContainsMouseChanged: row.hoverName = containsMouse ? s.name : (row.hoverName === s.name ? "" : row.hoverName)
      onClicked: (m) => m.button === Qt.RightButton ? s.rightClick() : s.leftClick()
    }
  }

  Repeater {
    model: Glance.shown
    Slot {
      id: slot
      required property var modelData
      readonly property var btn: modelData.kind === "widget" ? Glance.buttonFor(modelData.key) : null
      readonly property bool hasText: !!btn && String(btn.text).trim() !== ""
      name: modelData.name
      width: modelData.kind === "widget" && hasText ? mirror.implicitWidth + 12 : 24
      // tray app: its own icon
      Image {
        visible: slot.modelData.kind === "tray"
        anchors.centerIn: parent
        width: 16; height: 16
        sourceSize.width: 32; sourceSize.height: 32
        source: slot.modelData.kind === "tray" ? slot.modelData.tray.icon : ""
        smooth: true
      }
      // bar widget: a copy of what its bar button shows, or its icon
      Text {
        id: mirror
        visible: slot.modelData.kind === "widget" && slot.hasText
        anchors.centerIn: parent
        text: slot.btn ? slot.btn.text : ""
        font.family: slot.btn ? slot.btn.fontFamily : Theme.fontText
        font.pixelSize: 13
        color: slot.btn && slot.btn.active ? Theme.urgent : Theme.text
      }
      Icon {
        visible: slot.modelData.kind === "widget" && !slot.hasText
        anchors.centerIn: parent
        name: slot.modelData.icon; font.pixelSize: 16; color: Theme.text
      }
      onLeftClick: {
        if (modelData.kind === "tray") modelData.tray.onlyMenu ? row.menuRequested(modelData.tray) : modelData.tray.activate()
        else Popouts.summon(modelData.key)
      }
      onRightClick: if (modelData.kind === "tray" && modelData.tray.hasMenu) row.menuRequested(modelData.tray)
    }
  }

  // a thin line between your things and the containers
  Rectangle {
    visible: Glance.shown.length > 0 && Docker.running.length > 0
    width: 1; height: 16; color: Theme.edge
    anchors.verticalCenter: parent.verticalCenter
  }

  Repeater {
    model: Docker.running
    Slot {
      required property var modelData
      name: modelData.name + (modelData.url ? "" : "  (no page)")
      docker: true
      Icon { anchors.centerIn: parent; name: modelData.icon; font.pixelSize: 16; color: Theme.text }
      onLeftClick: Docker.open(modelData)
    }
  }
}
