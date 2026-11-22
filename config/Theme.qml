pragma Singleton
import QtQuick
import ".."
import qs.Commons

// Theme — colors and fonts. Colors follow your Omarchy theme live.
// Three steps (saneAspect's contrast rule):
//   1. surfaces: the pill and cards, quiet and close to each other
//   2. text: bright, with a dimmer version for minor things
//   3. accent: the ONE bright color, only for "you are here"
QtObject {
  // Omarchy's colors. Bar.qml keeps these in step with Omarchy's Color
  // (Color can't be reached from in here, so it's handed in from there:
  // startup, theme switches and a new accent from the Themes window all
  // update them live). The values below only cover the first moment.
  property int rev: 0
  property color fg: "#cacccc"
  property color bg: "#101315"

  // ── 1. Surfaces ───────────────────────────────
  property color surface: Settings.v.pureBlack ? "#000000" : bg  // the island itself (his is pure black)
  property color edge: Qt.rgba(fg.r, fg.g, fg.b, Settings.v.outline ? 0.10 : 0) // faint outline so the black pill shows on dark windows
  property color surfaceRaised: Qt.rgba(fg.r, fg.g, fg.b, 0.07) // cards inside the island, one quiet step up from black

  // ── 2. Text ───────────────────────────────────
  property color text: fg
  property color textDim: Qt.rgba(fg.r, fg.g, fg.b, 0.6)

  // ── 3. Accent ─────────────────────────────────
  property color accent: "#7aa2f7"
  property color urgent: "#a55555"   // warnings (low battery)

  // ── Fonts ─────────────────────────────────────
  // saneAspect uses "SF Compact Display" (AUR: apple-fonts). Until that's
  // installed, this follows your Omarchy font.
  property string fontDisplay: Style.font.family  // the clock and headings
  property string fontText: Style.font.family     // everything else
  property int clockSize: Settings.v.clockSize
  property int clockWeight: Font.DemiBold

  // ── Icons ─────────────────────────────────────
  // Material Symbols: type the icon's name as text ("wifi", "battery_full",
  // "music_note") and the font draws the icon. Names: fonts.google.com/icons
  property string iconFont: "Material Symbols Rounded"
  property int iconSize: 16
  // The font's four dials (saneAspect's settings):
  //   FILL 0 = outline, 1 = solid · wght 100 thin to 700 bold
  //   GRAD -25 to 200 emphasis   · opsz = the size it's drawn at
  property var iconAxes: ({ "FILL": Settings.v.iconFilled ? 1 : 0, "wght": Settings.v.iconWeight, "GRAD": 0, "opsz": iconSize })
}
