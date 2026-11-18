import QtQuick
import "../../"

// Dashboard — what the island opens into when you click it.
// The clock isn't in here: it's the same clock from the pill, sliding into
// the top-left corner (see Island.qml). This file leaves room for it.
//
// Header: clock (left), page tabs (right). The date lives on the hover card.
// Pages live in modules/pages/, one file each. To add a page: make the file,
// list it in qmldir, and add it to `pages` below.
Item {
  id: dash

  readonly property int headerHeight: 52
  property string page: "home"

  // icon + page file, in tab order
  readonly property var pages: [
    { key: "home",   icon: "home",     name: "Home" },
    { key: "system", icon: "tune",     name: "System" }
  ]

  function reset() { page = "home" }

  // ── Header: page tabs on the right ────────────
  Row {
    anchors.right: parent.right
    anchors.rightMargin: Sizes.dashPadding
    y: 14
    spacing: 4

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

    readonly property var current: dash.page === "system" ? systemPage : homePage

    Home {
      id: homePage
      width: parent.width
      readonly property bool here: dash.page === "home"
      opacity: here ? 1 : 0
      x: here ? 0 : -24
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
      Behavior on x { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
    }
    System {
      id: systemPage
      width: parent.width
      readonly property bool here: dash.page === "system"
      opacity: here ? 1 : 0
      x: here ? 0 : 24
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
      Behavior on x { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
    }
  }

  // The dashboard's real height, so the island can size itself to fit.
  readonly property int contentHeight: pageArea.y + pageArea.height + Sizes.dashPadding
}
