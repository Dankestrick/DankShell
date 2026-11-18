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
  readonly property string title: hasSong ? player.trackTitle : ""
  readonly property string artist: hasSong ? (player.trackArtist || "") : ""
  readonly property string artUrl: hasSong ? (player.trackArtUrl || "") : ""

  function toggle() { if (hasSong && player.canTogglePlaying) player.togglePlaying() }
  function next() { if (hasSong && player.canGoNext) player.next() }
  function previous() { if (hasSong && player.canGoPrevious) player.previous() }
}
