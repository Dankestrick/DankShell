import QtQuick
import "../../"
import "../../config/Plugins.js" as Plugins

// Dashboard — what the island opens into when you click it.
// The clock isn't in here: it's the same clock from the pill, sliding into
// the top-left corner (see Island.qml). This file leaves room for it.
//
// Header (right): themes, wallpapers, settings.
// Body: Home (toggles, music, volume, notifications).
// Bottom: one round button per plugin. A plugin's page pops up in the
// Center window in the middle of the screen (modules/center/Center.qml),
// so the island never fills up with tabs.
Item {
  id: dash

  readonly property int headerHeight: 68
  property string hoverName: ""

  signal closeRequested()
  signal themesRequested()
  signal wallsRequested()
  signal pageRequested(string key)   // open this page in the Center window

  function reset() { hoverName = "" }

  // Plugin buttons, minus the ones hidden in Settings › Dashboard.
  readonly property var apps: Plugins.active()
    .filter(p => Settings.v.hiddenApps.indexOf(p.key) < 0)
    .concat([{ key: "sound", name: "Sound & Bluetooth", icon: "tune" }])

  component HeaderButton: Rectangle {
    property string icon: ""
    property string tip: ""
    signal clicked()
    width: 32; height: 30; radius: 15
    color: tap.containsMouse ? Theme.surfaceRaised : "transparent"
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Icon { anchors.centerIn: parent; name: parent.icon; color: tap.containsMouse ? Theme.text : Theme.textDim }
    MouseArea {
      id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
      onClicked: parent.clicked()
      onContainsMouseChanged: dash.hoverName = containsMouse ? parent.tip : ""
    }
  }

  // ── Date under the clock: click it for the Journal (OmaJournal) ──
  Rectangle {
    id: dateChip
    x: Sizes.dashPadding
    y: 46
    width: dateText.implicitWidth + 12
    height: 20
    radius: 10
    color: dateTap.containsMouse ? Theme.surfaceRaised : "transparent"
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Text {
      id: dateText
      anchors.centerIn: parent
      text: Time.dateLong
      color: dateTap.containsMouse ? Theme.accent : Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 11
    }
    MouseArea {
      id: dateTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
      onClicked: dash.pageRequested(Plugins.byKey("journal") ? "journal" : "island")
      onContainsMouseChanged: dash.hoverName = containsMouse ? "Journal" : ""
    }
  }

  // ── Header buttons ────────────────────────────
  Row {
    anchors.right: parent.right
    anchors.rightMargin: Sizes.dashPadding - 4
    y: 17
    spacing: 2
    HeaderButton { icon: "palette"; tip: "Themes"; onClicked: dash.themesRequested() }
    HeaderButton { icon: "wallpaper"; tip: "Wallpapers"; onClicked: dash.wallsRequested() }
    HeaderButton { icon: "settings"; tip: "Settings"; onClicked: dash.pageRequested("island") }
  }

  // ── Home ──────────────────────────────────────
  Home {
    id: home
    x: Sizes.dashPadding
    y: dash.headerHeight + 8
    width: parent.width - Sizes.dashPadding * 2
  }

  // ── Your bar widgets, the real ones ───────────
  // Webcam, mail, Dropbox, network, DualSense, weather, updates, tray...
  // Each keeps its own dropdown, which opens under the island.
  // Which ones: config/Widgets.js.
  Rectangle {
    id: widgetStrip
    x: Sizes.dashPadding
    y: home.y + home.implicitHeight + 10
    width: parent.width - Sizes.dashPadding * 2
    height: flow.implicitHeight > 0 ? flow.implicitHeight + 12 : 0
    visible: height > 0
    radius: Sizes.cardRadius
    color: Theme.surfaceRaised
    Flow {
      id: flow
      x: 10
      width: parent.width - 20
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4
      Repeater {
        model: WidgetHost.entries
        HostedWidget { required property var modelData; entry: modelData }
      }
    }
  }

  // ── Plugin buttons ────────────────────────────
  Row {
    id: dock
    anchors.horizontalCenter: parent.horizontalCenter
    y: widgetStrip.y + widgetStrip.height + 12
    spacing: 8

    Repeater {
      model: dash.apps
      Rectangle {
        id: app
        required property var modelData
        width: 40; height: 40; radius: 20
        color: appTap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.8) : Theme.surfaceRaised
        scale: appTap.pressed ? 0.92 : appTap.containsMouse ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: Motion.ms(Motion.hover); easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
        Icon { anchors.centerIn: parent; name: app.modelData.icon; color: appTap.containsMouse ? Theme.accent : Theme.text; font.pixelSize: 18 }
        MouseArea {
          id: appTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: dash.pageRequested(app.modelData.key)
          onContainsMouseChanged: dash.hoverName = containsMouse ? app.modelData.name : ""
        }
      }
    }
  }
  // Name of the button under the mouse.
  Text {
    id: tipText
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: dock.bottom
    anchors.topMargin: 6
    text: dash.hoverName || WidgetHost.tip
    opacity: text !== "" ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
    color: Theme.textDim
    font.family: Theme.fontText
    font.pixelSize: 10
  }

  // The dashboard's real height, so the island can size itself to fit.
  readonly property int contentHeight: tipText.y + 14 + Sizes.dashPadding - 4
}
