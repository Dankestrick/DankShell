import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../"

// TrayRow — the apps sitting in the tray (Vesktop, Steam, Dropbox...) and the
// Docker containers that are running, as one row of icons.
// Tray: click opens/focuses the app, right-click asks for its menu.
// Docker: click opens the container's page (or focuses it).
Row {
  id: row
  spacing: 6
  signal menuRequested(var item)
  property string hoverName: ""        // name of the icon under the mouse (Hover shows it)

  readonly property var trayItems: SystemTray.items.values
  readonly property int count: trayItems.length + Docker.running.length

  component Slot: Rectangle {
    id: s
    property string name: ""
    property bool docker: false
    signal leftClick()
    signal rightClick()
    default property alias content: inner.data
    width: 24; height: 24; radius: 7
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
    model: row.trayItems
    Slot {
      required property var modelData
      name: modelData.tooltipTitle || modelData.title || modelData.id
      Image {
        anchors.centerIn: parent
        width: 16; height: 16
        sourceSize.width: 32; sourceSize.height: 32
        source: modelData.icon
        smooth: true
      }
      onLeftClick: modelData.onlyMenu ? row.menuRequested(modelData) : modelData.activate()
      onRightClick: if (modelData.hasMenu) row.menuRequested(modelData)
    }
  }

  // a thin line between the tray and the containers
  Rectangle {
    visible: row.trayItems.length > 0 && Docker.running.length > 0
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
