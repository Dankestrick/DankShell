pragma Singleton
import QtQuick
import Quickshell

// Popouts — which centered window is up, and on which monitor.
// The Center window (plugins + settings) pops up in the middle of the
// screen like saneAspect's Settings app, instead of tabs in the island.
Singleton {
  property string center: ""   // page shown in the Center window; "" = closed
  property string screen: ""   // monitor it's on
  property string mode: ""     // plugins, settings or device (Center sets it)

  property bool rightClickHere: false // the mouse is on something with its own right-click (back steps aside)
  property bool fromIsland: false    // opened from the dashboard: "back" reopens it
  property string lastDevice: "game" // the Device button opens the last Device page you used

  function openCenter(key, screenName, viaIsland) { screen = screenName; fromIsland = !!viaIsland; center = key }
  function closeCenter() { center = "" }
  // Right-click in the window: close it and go back to the dashboard if that's where you came from.
  function back() {
    const s = screen, again = fromIsland
    closeCenter()
    if (again) backToIsland(s)
  }
  signal backToIsland(string screenName)

  // Open a bar widget's dropdown under the island (Bar.qml listens).
  signal summon(string id)
}
