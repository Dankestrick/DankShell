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
  property int hoverLift: 14        // how far it grows when the mouse is on it (saneAspect: 7)

  // ── Open card ─────────────────────────────────
  property int expandedHeight: 125  // how tall the card gets
  property int radiusExpanded: 31   // corner rounding when open

  // Room kept free at the top so windows sit below the island.
  readonly property int reserved: gapFromEdge + barHeight
}
