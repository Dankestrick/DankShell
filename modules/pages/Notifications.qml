import QtQuick
import "../../"

// Notifications — every recent notification, newest first. Click one to
// read all of it, click again to clear it; × clears it right away.
Column {
  id: page
  property bool showing: false
  property string open: ""   // key of the one showing its full text
  spacing: 8

  Item {
    width: parent.width
    height: 30
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Notifications.count === 0 ? "All caught up" : Notifications.count + (Notifications.count === 1 ? " notification" : " notifications")
      color: Theme.textDim
      font.family: Theme.fontText
      font.pixelSize: 12
    }
    Rectangle {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      visible: Notifications.count > 0
      width: clearText.implicitWidth + 28
      height: 30
      radius: 15
      color: clearTap.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
      Text { id: clearText; anchors.centerIn: parent; text: "Clear all"; color: Theme.surface; font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold }
      MouseArea { id: clearTap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifications.clearAll() }
    }
  }

  // Empty
  Card {
    visible: Notifications.count === 0
    width: parent.width
    Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "notifications_off"; color: Theme.textDim; font.pixelSize: 28 }
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Nothing new"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 12 }
  }

  Repeater {
    model: Notifications.shown
    Rectangle {
      id: card
      required property var modelData
      readonly property bool expanded: page.open === modelData.key
      readonly property string bodyText: String(modelData.body || modelData.bodyLine || "").replace(/<[^>]*>/g, "")
      width: page.width
      height: col.implicitHeight + 24
      radius: Sizes.cardRadius
      color: tap.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.5) : Theme.surfaceRaised
      Behavior on color { ColorAnimation { duration: Motion.ms(Motion.fade) } }
      Behavior on height { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
      clip: true

      // Click to read all of it; click again (or one with nothing more) clears it.
      readonly property bool hasMore: bodyText.length > 90 || bodyText.indexOf("\n") >= 0
      MouseArea {
        id: tap; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: { if (!card.expanded && card.hasMore) page.open = card.modelData.key; else Notifications.dismiss(card.modelData.key) }
      }

      Rectangle {
        id: badge
        x: 12; y: 12
        width: 32; height: 32; radius: 16
        color: card.modelData.urgency >= 2 ? Theme.urgent : Theme.surface
        Text {
          anchors.centerIn: parent
          text: String(card.modelData.app || card.modelData.source || "?").charAt(0).toUpperCase()
          color: Theme.accent
          font.family: Theme.fontDisplay
          font.pixelSize: 14
          font.weight: Font.Bold
        }
      }
      Column {
        id: col
        anchors.left: badge.right
        anchors.leftMargin: 10
        anchors.right: closeBtn.left
        anchors.rightMargin: 6
        y: 12
        spacing: 2
        Row {
          spacing: 6
          Text { text: card.modelData.app || card.modelData.source || ""; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
          Text { text: { void(Notifications.tick); return "· " + Notifications.ago(card.modelData.ts || 0) } color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
        }
        Text {
          width: parent.width
          text: card.modelData.summary || ""
          elide: Text.ElideRight
          color: Theme.text
          font.family: Theme.fontText
          font.pixelSize: 12
          font.weight: Font.DemiBold
        }
        Text {
          width: parent.width
          visible: card.bodyText !== ""
          text: card.bodyText
          wrapMode: Text.Wrap
          maximumLineCount: card.expanded ? 40 : 2
          elide: Text.ElideRight
          textFormat: Text.PlainText
          color: Theme.textDim
          font.family: Theme.fontText
          font.pixelSize: 11
        }
      }
      Rectangle {
        id: closeBtn
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 12
        width: 26; height: 26; radius: 13
        color: x2.containsMouse ? Theme.surface : "transparent"
        Icon { anchors.centerIn: parent; name: "close"; color: Theme.textDim; font.pixelSize: 14 }
        MouseArea { id: x2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifications.dismiss(card.modelData.key) }
      }
    }
  }
}
