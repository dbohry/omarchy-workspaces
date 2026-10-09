import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "workspaces"

  // Workspace whose hover preview may open (-1 = none). Kept at widget level
  // so only one preview exists at a time; moving between numbers swaps cards
  // without both being visible.
  property int activePreviewId: -1

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        id: button
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        // Cursor on the number, or moved into the preview card.
        readonly property bool previewHovered: tooltipHovered || (previewCard.open && previewCard.containsMouse)
        // After clicking a workspace, don't re-open the preview until the
        // pointer has left the number once.
        property bool suppressPreview: false

        bar: root.bar
        text: focused ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize

        onTooltipHoveredChanged: if (!tooltipHovered) suppressPreview = false

        onPressed: function() {
          root.activePreviewId = -1
          suppressPreview = true
          root.focusWorkspace(modelData)
        }

        Timer {
          id: openDelay
          interval: Math.max(0, Number(root.setting("previewDelay", 350)))
          running: button.tooltipHovered && !button.suppressPreview && root.activePreviewId !== button.modelData
          onTriggered: root.activePreviewId = button.modelData
        }

        Timer {
          id: closeDelay
          interval: 220
          onTriggered: {
            if (button.previewHovered) return
            if (root.activePreviewId === button.modelData) root.activePreviewId = -1
          }
        }

        onPreviewHoveredChanged: {
          if (previewHovered) {
            closeDelay.stop()
          } else if (root.activePreviewId === button.modelData) {
            closeDelay.restart()
          }
        }

        HoverPreviewCard {
          id: previewCard
          anchorItem: button
          bar: root.bar
          open: root.activePreviewId === button.modelData
          contentWidth: Math.round(preview.desiredWidth) + previewCard.horizontalChrome
          contentHeight: Math.round(preview.desiredHeight) + previewCard.verticalChrome

          WorkspacePreview {
            id: preview
            anchors.fill: parent
            workspace: button.workspace
            monitor: button.workspace && button.workspace.monitor ? button.workspace.monitor : null
            stateHome: root.bar && root.bar.stateHome ? root.bar.stateHome : ""
            targetWidth: Math.max(160, Number(root.setting("previewWidth", 420)))
            live: previewCard.open
          }
        }
      }
    }
  }
}
