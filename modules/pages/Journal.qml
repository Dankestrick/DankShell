import QtQuick
import Quickshell.Io
import "../../"

// Journal — OmaJournal as a dashboard page: the month with your Obsidian
// note dots (one per 250 words, a hollow one for open to-dos), and the
// picked day's to-dos and journal under it. Every read and write goes through
// OmaJournal's own helper (helpers/omajournalctl), so notes are touched
// exactly the way the plugin touches them. Double-click a day to open it.
Column {
  id: page
  spacing: 10
  signal closeRequested()

  readonly property var hosted: PluginHost.hosted("journal")
  readonly property var settings: hosted ? hosted.settings || {} : ({})
  readonly property string helperPath: hosted ? hosted.dir + "/helpers/omajournalctl" : ""
  readonly property string vaultPath: String(settings.vaultPath || "")
  // OmaJournal's week start setting (0 Sunday .. 6 Saturday), else the locale's.
  readonly property int weekStart: {
    const w = Number(settings.weekStartDay)
    return w >= 0 && w <= 6 && settings.weekStartDay !== null && settings.weekStartDay !== undefined && settings.weekStartDay !== "" ? w : Qt.locale().firstDayOfWeek % 7
  }

  property date today: new Date()
  readonly property string todayKey: keyOf(today)
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  property string selectedKey: todayKey
  property var monthNotes: ({})
  property var dayNote: null
  property string error: ""
  readonly property var todos: dayNote && dayNote.todoList ? dayNote.todoList : []
  readonly property var journal: dayNote && dayNote.journal ? dayNote.journal.slice(-3) : []
  readonly property bool editing: editProc.running

  function pad(n) { return (n < 10 ? "0" : "") + n }
  function keyOf(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
  function dateOf(key) { const p = String(key).split("-"); return new Date(+p[0], +p[1] - 1, +p[2], 12) }
  function monthKey() { return viewYear + "-" + pad(viewMonth + 1) }

  // Six weeks from the week start, each { key, day, inMonth }.
  readonly property var cells: {
    const first = new Date(viewYear, viewMonth, 1, 12)
    const back = (first.getDay() - weekStart + 7) % 7
    const out = []
    for (let i = 0; i < 42; i++) {
      const d = new Date(viewYear, viewMonth, 1 - back + i, 12)
      out.push({ key: keyOf(d), day: d.getDate(), inMonth: d.getMonth() === viewMonth })
    }
    return out
  }
  readonly property var dayLetters: {
    const names = ["S", "M", "T", "W", "T", "F", "S"]
    const out = []
    for (let i = 0; i < 7; i++) out.push(names[(weekStart + i) % 7])
    return out
  }

  function helper(args) {
    let cmd = ["timeout", "-k", "2", "8", "python3", "-B", "-I", helperPath]
    if (vaultPath !== "") cmd = cmd.concat(["--vault", vaultPath])
    return cmd.concat(args)
  }
  function parse(text) {
    try { return JSON.parse(String(text || "").trim() || "{}") } catch (e) { return { ok: false, error: "Couldn't read your notes" } }
  }
  function loadMonth() {
    if (!helperPath) return
    monthProc.running = false
    monthProc.command = helper(["month", monthKey()])
    monthProc.running = true
  }
  function loadDay() {
    if (!helperPath) return
    dayProc.running = false
    dayProc.command = helper(["day", selectedKey])
    dayProc.running = true
  }
  function moveMonth(delta) {
    const d = new Date(viewYear, viewMonth + delta, 1, 12)
    viewYear = d.getFullYear(); viewMonth = d.getMonth()
    monthNotes = ({})
    loadMonth()
  }
  function goToday() {
    today = new Date()
    viewYear = today.getFullYear(); viewMonth = today.getMonth()
    selectedKey = todayKey
    loadMonth(); loadDay()
  }
  function select(cell) {
    selectedKey = cell.key
    if (!cell.inMonth) { const d = dateOf(cell.key); viewYear = d.getFullYear(); viewMonth = d.getMonth(); loadMonth() }
    loadDay()
  }
  function edit(args, stdinText) {
    if (editProc.running) return
    error = ""
    editProc.pending = stdinText || ""
    editProc.command = helper(args)
    editProc.running = true
  }
  function openNote() {
    if (dayNote && dayNote.uri) { Qt.openUrlExternally(dayNote.uri); page.closeRequested() }
  }

  // Fresh data each time the page is shown.
  property bool showing: false
  onShowingChanged: if (showing) goToday()
  onHelperPathChanged: { loadMonth(); loadDay() }
  onVaultPathChanged: { monthNotes = ({}); loadMonth(); loadDay() }

  Process {
    id: monthProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = page.parse(text)
        if (r.ok && r.month === page.monthKey()) page.monthNotes = r.days || ({})
        else if (!r.ok) page.error = r.error || ""
      }
    }
  }
  Process {
    id: dayProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = page.parse(text)
        if (r.ok && r.date === page.selectedKey) { page.dayNote = r; page.error = "" }
        else if (!r.ok) page.error = r.error || ""
      }
    }
  }
  // Typed text goes over stdin, never on the command line (as OmaJournal does).
  Process {
    id: editProc
    property string pending: ""
    stdinEnabled: true
    onStarted: { if (pending !== "") write(pending + "\n"); pending = "" }
    stdout: StdioCollector {
      onStreamFinished: {
        const r = page.parse(text)
        if (r.ok && r.date === page.selectedKey) { page.dayNote = r; page.error = "" }
        else if (!r.ok) { page.error = r.error || ""; page.loadDay() }
        page.loadMonth()
      }
    }
  }

  Text {
    visible: !page.hosted
    width: parent.width
    wrapMode: Text.WordWrap
    text: "Journal is still on Omarchy's side. Run `dankshell on` to hand it to DankShell."
    color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12
  }

  // ── The month ─────────────────────────────────
  Card {
    visible: !!page.hosted
    width: parent.width
    spacing: 6

    Item {
      width: parent.width
      height: 30
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.locale("en_US").standaloneMonthName(page.viewMonth, Locale.LongFormat) + " " + page.viewYear
        color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 15; font.weight: Font.Bold
      }
      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        RoundButton { width: 30; icon: "today"; visible: page.selectedKey !== page.todayKey || page.viewMonth !== page.today.getMonth(); onClicked: page.goToday() }
        RoundButton { width: 30; icon: "chevron_left"; onClicked: page.moveMonth(-1) }
        RoundButton { width: 30; icon: "chevron_right"; onClicked: page.moveMonth(1) }
      }
    }

    Grid {
      id: grid
      width: parent.width
      columns: 7
      readonly property real cellW: width / 7

      Repeater {
        model: page.dayLetters
        Text {
          required property string modelData
          width: grid.cellW
          horizontalAlignment: Text.AlignHCenter
          text: modelData
          color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
        }
      }
      Repeater {
        model: page.cells
        Item {
          id: cell
          required property var modelData
          readonly property var note: page.monthNotes[modelData.key] || null
          readonly property bool isToday: modelData.key === page.todayKey
          readonly property bool selected: modelData.key === page.selectedKey
          width: grid.cellW
          height: 36
          opacity: modelData.inMonth ? 1 : 0.35

          Rectangle {
            anchors.centerIn: parent
            width: 32; height: 32
            radius: cell.selected && !cell.isToday ? 10 : 16
            color: cell.isToday ? Theme.accent : cell.selected ? Theme.surface : "transparent"
            Behavior on radius { NumberAnimation { duration: Motion.ms(Motion.hover) } }
            Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 7
            text: cell.modelData.day
            color: cell.isToday ? Theme.surface : Theme.text
            font.family: Theme.fontText; font.pixelSize: 12
            font.weight: cell.isToday || cell.selected ? Font.Bold : Font.Normal
          }
          // Obsidian Calendar's dots: filled per 250 words, hollow for open to-dos.
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            spacing: 2
            Repeater {
              model: cell.note ? Math.min(5, cell.note.dots || 0) : 0
              Rectangle { width: 4; height: 4; radius: 2; color: cell.isToday ? Theme.surface : Theme.accent }
            }
            Rectangle {
              visible: !!(cell.note && cell.note.openTasks)
              width: 4; height: 4; radius: 2
              color: "transparent"
              border.width: 1
              border.color: cell.isToday ? Theme.surface : Theme.accent
            }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: page.select(cell.modelData)
            onDoubleClicked: { page.select(cell.modelData); page.openNote() }
          }
        }
      }
    }
  }

  // ── The day ───────────────────────────────────
  Card {
    visible: !!page.hosted
    width: parent.width
    spacing: 8

    Item {
      width: parent.width
      height: 38
      Column {
        anchors.verticalCenter: parent.verticalCenter
        Text {
          text: page.selectedKey === page.todayKey ? "Today" : Qt.formatDate(page.dateOf(page.selectedKey), "dddd, MMMM d")
          color: Theme.text; font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.DemiBold
        }
        Text {
          text: !page.dayNote ? "" : !page.dayNote.exists ? "No note yet"
            : (page.dayNote.words || 0) + " words" + (page.todos.length ? " · " + page.todos.filter(t => t.done).length + "/" + page.todos.length + " done" : "")
          color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
        }
      }
      RoundButton {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        visible: !!(page.dayNote && !page.dayNote.exists)
        enabled: !page.editing
        icon: "note_add"
        onClicked: page.edit(["create", page.selectedKey])
      }
      RoundButton {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        visible: !!(page.dayNote && page.dayNote.exists)
        icon: "open_in_new"
        onClicked: page.openNote()
      }
    }

    // To-dos: tick one to write it back into the note.
    Repeater {
      model: page.todos.slice(0, 8)
      Item {
        required property var modelData
        width: parent.width
        height: 22
        Icon {
          id: box
          x: (modelData.indent || 0) * 16
          anchors.verticalCenter: parent.verticalCenter
          name: modelData.done ? "check_box" : "check_box_outline_blank"
          filled: !!modelData.done
          color: modelData.done ? Theme.accent : Theme.textDim
          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            enabled: !page.editing && !!(page.dayNote && page.dayNote.hash)
            onClicked: page.edit(["toggle", page.selectedKey, String(modelData.line), page.dayNote.hash])
          }
        }
        Text {
          anchors.left: box.right; anchors.leftMargin: 8
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.text
          elide: Text.ElideRight
          font.strikeout: !!modelData.done
          color: modelData.done ? Theme.textDim : Theme.text
          font.family: Theme.fontText; font.pixelSize: 12
        }
      }
    }
    Text {
      visible: page.todos.length > 8
      text: "+" + (page.todos.length - 8) + " more in the note"
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
    }

    // The newest journal lines.
    Repeater {
      model: page.journal
      Text {
        required property string modelData
        width: parent.width
        text: modelData
        wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
        color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
      }
    }

    Field {
      visible: !!(page.dayNote && page.dayNote.exists)
      placeholderText: "Add a to-do"
      enabled: !page.editing
      onSubmitted: (t) => { if (page.dayNote && page.dayNote.hash) page.edit(["add", page.selectedKey, page.dayNote.hash], t) }
    }
    Field {
      visible: !!(page.dayNote && page.dayNote.exists)
      placeholderText: "Add to the journal"
      enabled: !page.editing
      onSubmitted: (t) => { if (page.dayNote && page.dayNote.hash) page.edit(["note", page.selectedKey, page.dayNote.hash], t) }
    }

    Text {
      width: parent.width
      visible: page.error !== ""
      text: page.error
      wrapMode: Text.WordWrap
      color: Theme.urgent; font.family: Theme.fontText; font.pixelSize: 11
    }
  }
}
