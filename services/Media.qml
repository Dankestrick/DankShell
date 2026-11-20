pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Media — what's playing, from any music app that talks MPRIS
// (Pandora/Pithos, Spotify, browsers...). Picks the one that's playing,
// otherwise the last one that has a song loaded.
Singleton {
  id: media

  readonly property var players: Mpris.players ? Mpris.players.values : []

  readonly property var player: {
    let fallback = null
    for (const p of players) {
      if (!p || !p.trackTitle) continue
      if (p.isPlaying) return p
      if (!fallback) fallback = p
    }
    return fallback
  }

  readonly property bool hasSong: player !== null
  readonly property bool playing: hasSong && player.isPlaying
  // Song cards show only while music plays. A song you just paused stays a
  // minute, so the card doesn't vanish under your finger and you can resume.
  readonly property bool showing: playing || justPaused
  property bool justPaused: false
  onPlayingChanged: { if (playing) { pauseGrace.stop(); justPaused = false } else if (hasSong) { justPaused = true; pauseGrace.restart() } }
  Timer { id: pauseGrace; interval: 60000; onTriggered: media.justPaused = false }
  readonly property string title: hasSong ? player.trackTitle : ""
  readonly property string artist: hasSong ? (player.trackArtist || "") : ""
  readonly property string artUrl: hasSong ? (player.trackArtUrl || "") : ""

  function toggle() { if (hasSong && player.canTogglePlaying) player.togglePlaying() }
  function next() { if (hasSong && player.canGoNext) player.next() }
  function previous() { if (hasSong && player.canGoPrevious) player.previous() }
}
