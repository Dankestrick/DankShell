import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../"

// Island — one per monitor. A see-through strip across the top of the
// screen that holds the pill in the middle and keeps windows below it.
//
// States (one surface that stretches, never a new box):
//   closed  → just the clock
//   bubble  → mouse touched it: grows a little right away
//   hover   → mouse rested a moment: medium card (clock, date, music, workspaces)
//   open    → clicked: the dashboard. Esc, a click outside, or a click on the clock closes it.
//
// The clock is ONE item that slides between its spot in each state
// (saneAspect's trick: it moves, it never fades out and back in).
PanelWindow {
  id: island

  required property var modelData   // the monitor this island is on
  screen: modelData

  property bool hidden: false        // Omarchy's "hide bar" toggle
  property string state: "closed"
  readonly property bool isOpen: state === "open"
  readonly property bool isThemes: state === "themes"
  readonly property bool held: isOpen || isThemes   // opened on purpose: hover doesn't close it

  anchors { top: true; left: true; right: true }
  color: "transparent"
  implicitHeight: Sizes.reserved + Math.max(Sizes.hoverHeight, dashboard.contentHeight, themeSwitcher.contentHeight) + 24  // room to grow into
  exclusiveZone: hidden ? 0 : Sizes.reserved
  WlrLayershell.namespace: "dankshell-island"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: held ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  // Only the pill takes clicks; the empty strip around it lets them through.
  mask: Region { item: pill }

  // Toggle states only refresh while a dashboard is open.
  onIsOpenChanged: { Toggles.watching = isOpen; if (!isOpen) dashboard.reset() }

  function showPage(key) { open(); dashboard.page = key }
  function open() { openTimer.stop(); closeTimer.stop(); state = "open"; keys.forceActiveFocus() }
  function close() { state = hover.hovered ? "hover" : "closed" }
  function showThemes() { openTimer.stop(); closeTimer.stop(); state = "themes"; themeSwitcher.reset() }

  // A click anywhere outside the island closes the dashboard.
  HyprlandFocusGrab {
    windows: [island]
    active: island.held
    onCleared: if (island.held) island.state = "closed"
  }

  // ── Hover timing ──────────────────────────────
  Timer { id: openTimer; interval: Motion.openDelay; onTriggered: if (hover.hovered && island.state === "bubble") island.state = "hover" }
  Timer { id: closeTimer; interval: Motion.closeDelay; onTriggered: if (!hover.hovered && !island.held) island.state = "closed" }

  Connections {
    target: hover
    function onHoveredChanged() {
      if (island.held) return
      if (hover.hovered) {
        closeTimer.stop()
        if (island.state === "closed") island.state = "bubble"
        openTimer.restart()
      } else {
        openTimer.stop()
        closeTimer.restart()
      }
    }
  }

  // ── The pill ──────────────────────────────────
  Pill {
    id: pill
    visible: !island.hidden
    clip: true
    anchors.horizontalCenter: parent.horizontalCenter
    y: Sizes.gapFromEdge

    readonly property int closedWidth: Math.max(Sizes.collapsedWidth, clock.closedWidth + Sizes.barHeight)

    width: island.isThemes ? Sizes.themesWidth
         : island.isOpen ? Sizes.dashWidth
         : island.state === "hover" ? Sizes.hoverWidth
         : island.state === "bubble" ? closedWidth + Sizes.hoverLift * 2
         : closedWidth
    height: island.isThemes ? themeSwitcher.contentHeight
          : island.isOpen ? Math.max(Sizes.dashHeight, dashboard.contentHeight)
          : island.state === "hover" ? Sizes.hoverHeight
          : island.state === "bubble" ? Sizes.barHeight + Sizes.hoverLift
          : Sizes.barHeight
    radius: island.held ? Sizes.radiusExpanded
          : island.state === "hover" ? Sizes.radiusHover
          : height / 2

    HoverHandler { id: hover }

    // Click the pill or the card to open the dashboard.
    TapHandler {
      enabled: !island.isOpen
      onTapped: island.open()
    }

    // Esc closes.
    Item {
      id: keys
      focus: true
      Keys.onEscapePressed: island.state = "closed"
    }

    Hover {
      width: Sizes.hoverWidth
      height: Sizes.hoverHeight
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      screenName: island.modelData.name
      opacity: island.state === "hover" ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
    }

    Dashboard {
      id: dashboard
      onCloseRequested: island.state = "closed"
      onThemesRequested: island.showThemes()
      width: Sizes.dashWidth
      height: Math.max(Sizes.dashHeight, contentHeight)
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      opacity: island.isOpen ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
    }

    ThemeSwitcher {
      id: themeSwitcher
      width: Sizes.themesWidth
      height: contentHeight
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      opacity: island.isThemes ? 1 : 0
      visible: opacity > 0
      onCloseRequested: island.state = "closed"
      Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
    }

    // ── The one clock ───────────────────────────
    Text {
      id: clock
      readonly property bool big: island.state === "hover" || island.isOpen
      readonly property int closedWidth: closedMetrics.width

      text: Time.hhmm
      color: Theme.text
      opacity: island.isThemes ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: Motion.ms(Motion.fade) } }
      font.family: Theme.fontDisplay
      font.weight: big ? Font.Bold : Theme.clockWeight
      font.pixelSize: island.isOpen ? 24 : island.state === "hover" ? 28 : Theme.clockSize

      // Closed/bubble: centered in the pill. Hover: top-left of the card.
      // Open: top-left corner of the dashboard.
      x: big ? (island.isOpen ? Sizes.dashPadding + 6 : 20) : (pill.width - width) / 2
      y: island.isOpen ? 16 : island.state === "hover" ? 12 : (pill.height - height) / 2

      Behavior on x { NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
      Behavior on y { NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
      Behavior on font.pixelSize { NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }

      TextMetrics {
        id: closedMetrics
        text: clock.text
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.clockSize
        font.weight: Theme.clockWeight
      }

      // In the dashboard, clicking the clock closes it (like saneAspect's).
      MouseArea {
        anchors.fill: parent
        enabled: island.isOpen
        cursorShape: Qt.PointingHandCursor
        onClicked: island.close()
      }
    }
  }
}
