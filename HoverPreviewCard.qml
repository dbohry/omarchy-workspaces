import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Minimal passive popup anchored to a bar item, styled like Ui/PopupCard but
// deliberately without the bar's popout coordination: a hover preview must not
// close an open click-popup (tray menu, audio panel, ...). Copied from the
// packaged PopupCard and trimmed; this plugin owns its copy, so shell updates
// can't change the behavior under us.
PopupWindow {
  id: root

  required property Item anchorItem
  required property var bar

  property int margin: Style.gapsOut
  property int padding: Style.spacing.popupPadding
  property int contentWidth: Style.space(280)
  property int contentHeight: Style.space(200)
  property bool open: false
  property var borderSpec: Border.localOrSurfaceSpec("popups", "border", Color.popups.border, Color.popups.border, Style.normalBorderWidth)

  // Size the window needs for a given content size, so callers can pass the
  // desired *canvas* size and get an exact aspect ratio inside the padding.
  readonly property int horizontalChrome: Border.left(borderSpec) + Border.right(borderSpec) + padding * 2
  readonly property int verticalChrome: Border.top(borderSpec) + Border.bottom(borderSpec) + padding * 2

  readonly property bool containsMouse: cardHover.hovered
  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property var anchorScreen: anchorWindow ? anchorWindow.screen : null

  default property alias contentItem: contentHolder.children

  visible: open || card.opacity > 0
  color: "transparent"
  implicitWidth: root.anchorScreen
    ? Math.min(root.contentWidth, Math.max(120, root.anchorScreen.width - root.margin * 2))
    : root.contentWidth
  implicitHeight: root.anchorScreen
    ? Math.min(root.contentHeight, Math.max(120, root.anchorScreen.height - root.margin * 2))
    : root.contentHeight

  anchor {
    id: popupAnchor
    window: root.anchorWindow
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1

    onAnchoring: {
      if (!root.anchorItem || !root.bar || !root.anchorWindow) return

      var target = root.anchorItem
      var popupWidth = root.implicitWidth
      var popupHeight = root.implicitHeight
      var localX = target.width / 2 - popupWidth / 2
      var localY = target.height + root.margin

      if (root.bar.position === "bottom") {
        localY = -popupHeight - root.margin
      } else if (root.bar.position === "left") {
        localX = target.width + root.margin
        localY = target.height / 2 - popupHeight / 2
      } else if (root.bar.position === "right") {
        localX = -popupWidth - root.margin
        localY = target.height / 2 - popupHeight / 2
      }

      var point = root.anchorWindow.contentItem.mapFromItem(target, localX, localY)
      if (root.bar.position === "top" || root.bar.position === "bottom") {
        point.x = Math.max(root.margin, Math.min(point.x, root.anchorWindow.width - popupWidth - root.margin))
      } else {
        point.y = Math.max(root.margin, Math.min(point.y, root.anchorWindow.height - popupHeight - root.margin))
      }

      popupAnchor.rect.x = Math.round(point.x)
      popupAnchor.rect.y = Math.round(point.y)
    }
  }

  BorderSurface {
    id: card
    anchors.fill: parent
    color: Color.popups.background
    borderSpec: root.borderSpec
    padding: root.padding
    radius: Style.cornerRadius
    opacity: root.open ? 1.0 : 0

    Behavior on opacity {
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Item {
      id: contentHolder
      anchors.fill: parent
      anchors.topMargin: card.contentTopInset
      anchors.rightMargin: card.contentRightInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.leftMargin: card.contentLeftInset
    }

    HoverHandler {
      id: cardHover
    }
  }
}
