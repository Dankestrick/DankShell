pragma Singleton
import QtQuick
import Quickshell

// Time — the current time, shared by every screen so there's one clock.
Singleton {
  readonly property date now: clock.date
  readonly property string hhmm: Qt.formatDateTime(clock.date, "HH:mm")
  readonly property string dateLong: Qt.formatDateTime(clock.date, "dddd, MMMM d")

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
