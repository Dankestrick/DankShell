pragma Singleton
import QtQuick
import qs.Commons

// Theme — colors and fonts. Colors follow your Omarchy theme live.
// Three steps (saneAspect's contrast rule):
//   1. surfaces: the pill and cards, quiet and close to each other
//   2. text: bright, with a dimmer version for minor things
//   3. accent: the ONE bright color, only for "you are here"
QtObject {
  // ── 1. Surfaces ───────────────────────────────
  property color surface: "#000000"                       // the island itself (his is pure black)
  property color edge: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.10) // faint outline so the black pill shows on dark windows
  property color surfaceRaised: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.07) // cards inside the island, one quiet step up from black

  // ── 2. Text ───────────────────────────────────
  property color text: Color.foreground
  property color textDim: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.6)

  // ── 3. Accent ─────────────────────────────────
  property color accent: Color.accent

  // ── Fonts ─────────────────────────────────────
  // saneAspect uses "SF Compact Display" (AUR: apple-fonts). Until that's
  // installed, this follows your Omarchy font.
  property string fontDisplay: Style.font.family  // the clock and headings
  property string fontText: Style.font.family     // everything else
  property int clockSize: 14
  property int clockWeight: Font.DemiBold

  // ── Icons ─────────────────────────────────────
  // Material Symbols: type the icon's name as text ("wifi", "battery_full",
  // "music_note") and the font draws the icon. Names: fonts.google.com/icons
  property string iconFont: "Material Symbols Rounded"
  property int iconSize: 16
  // The font's four dials (saneAspect's settings):
  //   FILL 0 = outline, 1 = solid · wght 100 thin to 700 bold
  //   GRAD -25 to 200 emphasis   · opsz = the size it's drawn at
  property var iconAxes: ({ "FILL": 0, "wght": 700, "GRAD": 0, "opsz": iconSize })
}
