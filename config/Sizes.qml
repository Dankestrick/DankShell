pragma Singleton
import QtQuick

// Sizes — every size in DankShell, in pixels.
// Starting values are saneAspect's own (his Bar & Island settings page).
// Change a number here and every screen updates.
QtObject {
  // ── Closed pill ───────────────────────────────
  property int barHeight: 33        // how tall the pill is
  property int collapsedWidth: 96   // how wide the pill is when closed
  property int gapFromEdge: 11      // space between the pill and the top of the screen
  property int innerPadding: 3      // space inside the pill's edge
  property int radius: 20           // corner rounding when closed

  // ── Hover ─────────────────────────────────────
  property int hoverLift: 14        // how far it bubbles out the moment the mouse touches it (saneAspect: 7)

  // ── Hover card (mouse rests on the pill) ──────
  property int hoverWidth: 440      // width of the medium card
  property int hoverHeight: 100     // height of the medium card
  property int radiusHover: 28      // corner rounding of the medium card

  // ── Dashboard (click the card) ────────────────
  property int dashWidth: 460       // width of the open dashboard
  property int dashHeight: 236      // smallest height; it grows to fit what's on the page
  property int radiusExpanded: 31   // corner rounding when open (saneAspect: 31)
  property int dashPadding: 16      // space between the dashboard's edge and its cards
  property int cardRadius: 18       // corner rounding of cards inside the dashboard

  // Tallest the island can get (the window reserves this much room to draw in).
  readonly property int expandedHeight: Math.max(hoverHeight, dashHeight)

  // Room kept free at the top so windows sit below the island.
  readonly property int reserved: gapFromEdge + barHeight
}
