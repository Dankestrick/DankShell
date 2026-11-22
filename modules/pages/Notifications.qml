import QtQuick
import "../../"

// Notifications — one tab of the Notifications window:
//   unread:  today's you haven't opened. Click one to read it (it moves to Read
//            when you leave the tab).
//   read:    today's you've opened.
//   archive: everything from before midnight, until Omarchy lets it go (24 h).
// × deletes one; the button up top marks all read, or deletes the whole tab.
Column {
  id: page
  property bool showing: false
  property string stage: "unread"
  property string open: ""      // key of the one showing all its text
  property var keep: []         // read during this visit: stay in Unread until you leave
  spacing: 10

  readonly property var rows: {
    if (stage !== "unread") return Notifications.stage(stage)
    const extra = Notifications.read.filter(e => keep.indexOf(e.key) >= 0)
    return Notifications.unread.concat(extra).sort((a, b) => b.ts - a.ts)
  }

  function clicked(e) {
    page.open = page.open === e.key ? "" : e.key
    if (!e.read) { keep = keep.concat([e.key]); Notifications.markRead(e.key) }
  }

  component Head: Text { color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase; leftPadding: 4 }
  component Pill: Rectangle {
    id: pb
    property string label: ""
    property string icon: ""
    signal clicked()
    width: pr.implicitWidth + 20; height: 28; radius: 14
    color: tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.6) : Theme.surface
    Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
    Row { id: pr; anchors.centerIn: parent; spacing: 5
      Icon { name: pb.icon; font.pixelSize: 15; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
      Text { text: pb.label; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pb.clicked() }
  }

  // ── Top: how many, and the one button ─────────
  Card {
    width: parent.width
    Item {
      width: parent.width; height: 44
      DeviceHeader {
        width: parent.width - allBtn.width - 12
        icon: page.stage === "archive" ? "inventory_2" : page.stage === "read" ? "drafts" : "notifications_unread"
        active: page.stage === "unread" && Notifications.count > 0
        title: page.stage === "unread" ? (Notifications.count === 0 ? "All caught up" : Notifications.count + " unread")
             : page.stage === "read" ? Notifications.read.length + " read today"
             : Notifications.archive.length + " from before today"
        subtitle: page.stage === "archive" ? "Yesterday" : "Today"
      }
      Pill {
        id: allBtn
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        visible: page.stage === "unread" ? Notifications.count > 0 : page.rows.length > 0
        icon: page.stage === "unread" ? "done_all" : "delete"
        label: page.stage === "unread" ? "Mark all read" : "Delete all"
        onClicked: page.stage === "unread" ? Notifications.markAllRead() : Notifications.removeAll(page.stage)
      }
    }
  }

  // ── The list ──────────────────────────────────
  Card {
    width: parent.width
    spacing: 4
    Head { text: page.stage === "archive" ? "Yesterday" : "Today" }
    Text {
      visible: page.rows.length === 0
      leftPadding: 10
      text: page.stage === "unread" ? "Nothing new" : page.stage === "read" ? "Nothing read yet today" : "Nothing from before today"
      color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
    }
    Repeater {
      model: page.rows
      Rectangle {
        id: row
        required property var modelData
        readonly property bool expanded: page.open === modelData.key
        readonly property bool hasMore: modelData.body.length > 70 || modelData.body.indexOf("\n") >= 0
        width: parent ? parent.width : 300
        height: col.implicitHeight + 16
        radius: 12
        color: !modelData.read ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
             : tap.containsMouse ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
        Behavior on height { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
        clip: true

        MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.clicked(row.modelData) }

        // App's glyph (or first letter) in a round chip; red when urgent.
        Rectangle {
          id: chip
          x: 8; y: 8
          width: 30; height: 30; radius: 15
          color: row.modelData.urgency >= 2 ? Theme.urgent : Theme.surface
          Text {
            anchors.centerIn: parent
            text: row.modelData.glyph !== "" ? row.modelData.glyph : row.modelData.app.charAt(0).toUpperCase()
            color: row.modelData.read ? Theme.textDim : Theme.accent
            font.family: Theme.fontText; font.pixelSize: 14; font.weight: Font.Bold
          }
        }
        Column {
          id: col
          anchors.left: chip.right; anchors.leftMargin: 10
          anchors.right: x.left; anchors.rightMargin: 6
          y: 8
          spacing: 1
          Text {
            width: parent.width
            text: row.modelData.summary !== "" ? row.modelData.summary : row.modelData.app
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.fontText; font.pixelSize: 12
            font.weight: row.modelData.read ? Font.Normal : Font.DemiBold
          }
          Text {
            width: parent.width
            visible: row.modelData.body !== ""
            text: row.modelData.body
            wrapMode: Text.Wrap
            maximumLineCount: row.expanded ? 40 : 1
            elide: Text.ElideRight
            textFormat: Text.PlainText
            color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11
          }
          Text {
            text: row.modelData.app + "  ·  " + (page.stage === "archive" ? Notifications.clock(row.modelData.ts) : Notifications.ago(row.modelData.ts))
                  + (row.hasMore && !row.expanded ? "  ·  click to read all" : "")
            color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10
          }
        }
        Rectangle {
          id: x
          anchors.right: parent.right; anchors.rightMargin: 6
          y: 8
          width: 28; height: 28; radius: 14
          color: xTap.containsMouse ? Theme.surfaceRaised : "transparent"
          Icon { anchors.centerIn: parent; name: "close"; font.pixelSize: 15; color: xTap.containsMouse ? Theme.urgent : Theme.textDim }
          MouseArea { id: xTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifications.remove(row.modelData.key) }
        }
      }
    }
  }
}
