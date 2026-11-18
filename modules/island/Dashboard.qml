import QtQuick
import "../../"
import "../../config/Plugins.js" as Plugins

// Dashboard — what the island opens into when you click it.
// The clock isn't in here: it's the same clock from the pill, sliding into
// the top-left corner (see Island.qml). This file leaves room for it.
//
// Header: clock (left), page tabs (right). The date lives on the hover card.
// Pages live in modules/pages/, one file each. Home and System are built in;
// every plugin in config/Plugins.js (not `off`) adds its own page and tab.
Item {
  id: dash

  readonly property int headerHeight: 52
  property string page: "home"

  // icon + page file, in tab order
  readonly property var pages: [
    { key: "home",   icon: "home", name: "Home",   file: "Home.qml" },
    { key: "system", icon: "tune", name: "System", file: "System.qml" }
  ].concat(Plugins.active().map(p => ({ key: p.key, icon: p.icon, name: p.name,
                                       file: p.key.charAt(0).toUpperCase() + p.key.slice(1) + ".qml" })))

  signal closeRequested()
  signal themesRequested()

  function reset() { page = "home" }

  // ── Header: page tabs on the right ────────────
  Row {
    anchors.right: parent.right
    anchors.rightMargin: Sizes.dashPadding
    y: 14
    spacing: 4

    // Theme switcher (not a page: the island turns into it).
    Rectangle {
      width: 30; height: 28; radius: 14
      color: palTap.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
      Icon { anchors.centerIn: parent; name: "palette"; color: Theme.textDim }
      MouseArea { id: palTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dash.themesRequested() }
    }
    Rectangle { width: 1; height: 16; anchors.verticalCenter: parent.verticalCenter; color: Theme.edge }

    Repeater {
      model: dash.pages
      Rectangle {
        required property var modelData
        readonly property bool here: dash.page === modelData.key
        width: here ? 34 + label.implicitWidth : 30
        height: 28
        radius: 14
        color: here ? Theme.surfaceRaised : tap.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        clip: true
        Behavior on width { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }

        Icon {
          id: tabIcon
          x: 7
          anchors.verticalCenter: parent.verticalCenter
          name: modelData.icon
          filled: here
          color: here ? Theme.accent : Theme.textDim
        }
        Text {
          id: label
          anchors.left: tabIcon.right
          anchors.leftMargin: 5
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.name
          opacity: here ? 1 : 0
          color: Theme.text
          font.family: Theme.fontText
          font.pixelSize: 11
          font.weight: Font.DemiBold
          Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
        }
        MouseArea {
          id: tap
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: dash.page = modelData.key
        }
      }
    }
  }

  // ── Pages ─────────────────────────────────────
  // Each page slides and fades in; the dashboard height follows the page.
  Item {
    id: pageArea
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Sizes.dashPadding
    y: dash.headerHeight + 8
    height: current ? current.implicitHeight : 0

    property var current: null

    Repeater {
      model: dash.pages
      Loader {
        required property var modelData
        required property int index
        readonly property bool here: dash.page === modelData.key
        readonly property int myIndex: index
        width: pageArea.width
        source: Qt.resolvedUrl("../pages/" + modelData.file)
        opacity: here ? 1 : 0
        // slide in from the side the tab is on
        x: here ? 0 : (myIndex < dash.pages.findIndex(p => p.key === dash.page) ? -24 : 24)
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

  // The dashboard's real height, so the island can size itself to fit.
  readonly property int contentHeight: pageArea.y + pageArea.height + Sizes.dashPadding
}
