import QtQuick
import Quickshell
import "../../"

// Power — one tab of the Power window (Lock, Screensaver, Restart, Power off).
// One big button. Restart and Power off ask first: the first click turns it
// red, a second click within 3 seconds does it.
Column {
  id: page
  property bool showing: false
  property string action: "lock"
  signal closeRequested()
  spacing: 10

  readonly property bool asks: action === "reboot" || action === "shutdown"
  property bool armed: false
  onShowingChanged: armed = false
  Timer { id: disarm; interval: 3000; onTriggered: page.armed = false }

  readonly property var info: ({
    lock:        { icon: "lock",               label: "Lock now",          sure: "" },
    screensaver: { icon: "auto_awesome",       label: "Start screensaver", sure: "" },
    reboot:      { icon: "restart_alt",        label: "Restart",           sure: "Click again to restart" },
    shutdown:    { icon: "power_settings_new", label: "Power off",         sure: "Click again to power off" }
  })[action] || ({ icon: "", label: "", sure: "" })

  function go() {
    if (asks && !armed) { armed = true; disarm.restart(); return }
    armed = false
    closeRequested()
    Quickshell.execDetached(action === "lock" ? ["omarchy", "system", "lock"]
                          : action === "screensaver" ? ["omarchy-launch-screensaver", "force"]
                          : ["omarchy", "system", action])
  }

  Card {
    width: parent.width
    padding: 24
    Rectangle {
      id: big
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(parent.width, row.implicitWidth + 56)
      height: 52
      radius: 26
      color: page.armed ? Theme.urgent : tap.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
      Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
      Behavior on width { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
      Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon { name: page.info.icon; filled: true; color: Theme.surface; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
        Text {
          text: page.armed ? page.info.sure : page.info.label
          color: Theme.surface
          font.family: Theme.fontText; font.pixelSize: 14; font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
      MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.go() }
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: page.asks
      text: page.armed ? "Wait 3 seconds or click another tab to back out." : "It asks once more before it goes."
      color: page.armed ? Theme.urgent : Theme.textDim
      font.family: Theme.fontText; font.pixelSize: 11
    }
  }
}
