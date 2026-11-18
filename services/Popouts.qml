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

  function openCenter(key, screenName) { screen = screenName; center = key }
  function closeCenter() { center = "" }

  // Open a bar widget's dropdown under the island (Bar.qml listens).
  signal summon(string id)
}
