import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Composite thumbnail of one Hyprland workspace: wallpaper background plus
// live captures of every window, positioned by the geometry reported in each
// toplevel's hyprctl JSON. Quickshell's ScreencopyView can capture windows on
// inactive workspaces (Hyprland toplevel export), which is what makes a real
// preview possible at all -- the compositor never renders hidden workspaces.
Item {
  id: root

  property var workspace: null        // HyprlandWorkspace or null
  property var monitor: null          // HyprlandMonitor owning the workspace
  property bool live: false           // keep captures refreshing while open
  property string stateHome: ""       // bar.stateHome, for the wallpaper symlink
  property real targetWidth: 420

  readonly property var monitorIpc: monitor && monitor.lastIpcObject ? monitor.lastIpcObject : null
  // hyprctl reports monitor width/height in physical pixels; window geometry
  // (`at`, `size`) is logical. Divide by scale to get the logical desktop the
  // windows live in.
  readonly property real monScale: monitorIpc && monitorIpc.scale > 0
    ? monitorIpc.scale
    : (monitor && monitor.scale > 0 ? monitor.scale : 1)
  readonly property real monWidth: monitorIpc && monitorIpc.width > 0
    ? monitorIpc.width / monScale
    : 1920
  readonly property real monHeight: monitorIpc && monitorIpc.height > 0
    ? monitorIpc.height / monScale
    : 1080
  readonly property real monX: monitorIpc && monitorIpc.x !== undefined
    ? monitorIpc.x
    : (monitor ? monitor.x : 0)
  readonly property real monY: monitorIpc && monitorIpc.y !== undefined
    ? monitorIpc.y
    : (monitor ? monitor.y : 0)

  readonly property real desiredWidth: Math.max(160, targetWidth)
  readonly property real desiredHeight: Math.round(desiredWidth * monHeight / Math.max(1, monWidth))
  readonly property real scaleFactor: width > 0 ? width / Math.max(1, monWidth) : 0

  // Windows to draw, back to front. `focusHistoryID` 0 is the most recently
  // focused window, so sorting descending puts the oldest at the bottom and
  // the active window on top. Not an exact z-order for stacked floats, but it
  // reads correctly for the tiling layouts this bar usually shows.
  readonly property var windows: {
    var result = []
    if (!workspace) return result
    var values = workspace.toplevels.values
    for (var i = 0; i < values.length; i++) {
      var toplevel = values[i]
      var ipc = toplevel.lastIpcObject
      if (!ipc || ipc.mapped === false) continue
      result.push({
        toplevel: toplevel,
        ipc: ipc,
        focus: Number(ipc.focusHistoryID) || 0
      })
    }
    result.sort(function(left, right) { return right.focus - left.focus })
    return result
  }

  function windowRect(toplevel, ipc) {
    var at = ipc.at || [0, 0]
    var size = ipc.size || [0, 0]
    // Pinned windows can live on another monitor; subtract that monitor's
    // origin when available so they still land in the right place.
    var toplevelMonitorIpc = toplevel && toplevel.monitor && toplevel.monitor.lastIpcObject
      ? toplevel.monitor.lastIpcObject
      : null
    var originX = toplevelMonitorIpc && toplevelMonitorIpc.x !== undefined ? toplevelMonitorIpc.x : root.monX
    var originY = toplevelMonitorIpc && toplevelMonitorIpc.y !== undefined ? toplevelMonitorIpc.y : root.monY
    var scale = root.scaleFactor
    return Qt.rect(Math.round((at[0] - originX) * scale),
                   Math.round((at[1] - originY) * scale),
                   Math.max(1, Math.round(size[0] * scale)),
                   Math.max(1, Math.round(size[1] * scale)))
  }

  clip: true

  // ~/.local/state/omarchy/current/background is a symlink to the active
  // wallpaper; bumping the revision on file change busts Qt's image cache.
  FileView {
    id: backgroundFile
    path: root.stateHome !== "" ? root.stateHome + "/omarchy/current/background" : ""
    watchChanges: true
    printErrors: false
    onFileChanged: root.wallpaperRevision += 1
    onPathChanged: root.wallpaperRevision += 1
  }

  property int wallpaperRevision: 0
  readonly property string wallpaperSource: backgroundFile.path === ""
    ? ""
    : "file://" + backgroundFile.path + "?v=" + wallpaperRevision

  Rectangle {
    anchors.fill: parent
    color: Color.background
    clip: true

    Image {
      anchors.fill: parent
      source: root.wallpaperSource
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
    }

    Rectangle {
      anchors.fill: parent
      color: "#000000"
      opacity: 0.25
    }

    Repeater {
      model: root.windows

      Item {
        id: windowItem
        required property var modelData
        readonly property var rect: root.windowRect(modelData.toplevel, modelData.ipc)
        x: rect.x
        y: rect.y
        width: rect.width
        height: rect.height

        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.65)
          visible: capture.opacity < 1
        }

        ScreencopyView {
          id: capture
          anchors.fill: parent
          // HyprlandToplevel wraps the Wayland Toplevel that screencopy
          // accepts; fall back to the Hyprland object if the bridge is absent.
          captureSource: modelData.toplevel.wayland !== null && modelData.toplevel.wayland !== undefined
            ? modelData.toplevel.wayland
            : modelData.toplevel
          live: root.live
          constraintSize: Qt.size(Math.max(1, Math.round(width)), Math.max(1, Math.round(height)))
          opacity: hasContent ? 1 : 0

          Behavior on opacity {
            NumberAnimation { duration: 120 }
          }
        }

        Rectangle {
          anchors.fill: parent
          color: "transparent"
          border.width: 1
          border.color: Qt.rgba(Color.popups.border.r, Color.popups.border.g, Color.popups.border.b, 0.35)
        }
      }
    }

    Text {
      anchors.centerIn: parent
      visible: root.windows.length === 0
      text: root.workspace ? "Workspace " + root.workspace.id : ""
      color: Color.popups.text
      opacity: 0.55
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }
}
