pragma Singleton
import QtQuick
import ".."

// Sizes — every size in DankShell, in pixels.
// Starting values are saneAspect's own (his Bar & Island settings page).
// The ones marked Settings.v come from the Settings window (saved in
// ~/.config/dankshell/settings.json); change the rest here.
QtObject {
  // ── Closed pill ───────────────────────────────
  property int barHeight: Settings.v.barHeight        // how tall the pill is
  property int collapsedWidth: Settings.v.collapsedWidth   // how wide the pill is when closed
  property int gapFromEdge: Settings.v.gapFromEdge      // space between the pill and the top of the screen
  property int innerPadding: 3      // space inside the pill's edge
  property int radius: 20           // corner rounding when closed

  // ── Hover ─────────────────────────────────────
  property int hoverLift: Settings.v.hoverLift        // how far it bubbles out the moment the mouse touches it (saneAspect: 7)

  // ── Hover card (mouse rests on the pill) ──────
  property int hoverWidth: Settings.v.hoverWidth      // width of the medium card
  property int hoverHeight: Settings.v.hoverHeight     // height of the medium card
  property int radiusHover: 28      // corner rounding of the medium card

  // ── Dashboard (click the card) ────────────────
  property int dashWidth: Settings.v.dashWidth       // width of the open dashboard
  property int dashHeight: 236      // smallest height; it grows to fit what's on the page
  property int radiusExpanded: Settings.v.radiusExpanded   // corner rounding when open (saneAspect: 31)
  property int dashPadding: 16      // space between the dashboard's edge and its cards
  property int cardRadius: 18       // corner rounding of cards inside the dashboard

  // ── Center window (plugins + settings) ───────
  property int centerWidth: 780
  property int centerHeight: 720

  // Tallest the island can get (the window reserves this much room to draw in).
  readonly property int expandedHeight: Math.max(hoverHeight, dashHeight)

  // Room kept free at the top so windows sit below the island.
  readonly property int reserved: gapFromEdge + barHeight
}
