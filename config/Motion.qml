pragma Singleton
import QtQuick

// Motion — how fast everything animates, in milliseconds.
// Starting values are saneAspect's own (his Motion settings page).
QtObject {
  property bool reduceMotion: false // true = no animation at all

  property int move: 420   // size and position changes (the pill growing)
  property int fade: 180   // fades and color changes
  property int hover: 150  // reacting to the mouse
  property real bounce: 0.7 // 0 = no bounce, 1 = very springy (saneAspect: 0.4)

  property int openDelay: 350  // how long the mouse rests on the pill before the card opens
  property int closeDelay: 300 // grace time after the mouse leaves before it shrinks back

  property int slide: 380      // the clock sliding between its spots (no bounce, text shouldn't wobble)

  // The easing curve used for moves. OutBack overshoots a little, which is the bounce.
  readonly property int moveEasing: bounce > 0 ? Easing.OutBack : Easing.OutCubic
  readonly property real overshoot: bounce * 2.5

  // Use these in animations so "reduce motion" works everywhere.
  function ms(value) { return reduceMotion ? 0 : value }
}
