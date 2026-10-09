# Workspaces (with hover previews)

A clone of Omarchy's workspace indicator that shows a live thumbnail of the
desktop you're about to jump to.

Hover a workspace number in the bar and a small preview opens underneath it:
your wallpaper, with every window on that workspace drawn where it actually
sits — like a miniature of the screen, updated live while you hover.

## Features

- **Live previews, not screenshots.** Windows stream into the preview while
  it's open, even when the workspace is not visible.
- **Real layout.** Each window is placed at its true position and size for the
  workspace's monitor, so tiling and floating windows land where you expect.
- **Works for workspaces you've never visited.** Empty workspaces show just
  the wallpaper and their number.
- **Plays well with the rest of the bar.** The preview is passive: it never
  steals focus and never closes an open tray menu or panel.
- **Stock behavior preserved.** Clicking still focuses the workspace,
  `Super+{1..10}` works as before, and the focused/occupied styling is
  unchanged.

## Settings

Settings are optional and go on the widget's entry in
`~/.config/omarchy/shell.json`:

```json
{
  "id": "workspaces",
  "previewWidth": 420,
  "previewDelay": 350
}
```

| Setting        | Default | Meaning                                                        |
| -------------- | ------- | -------------------------------------------------------------- |
| `previewWidth` | `420`   | Preview width in logical pixels. Height follows the monitor's aspect ratio. |
| `previewDelay` | `350`   | Milliseconds of hovering before the preview opens. `0` opens immediately. |

Changes hot-reload when you save `shell.json`.

## How it works

Hyprland never renders inactive workspaces, so a plain screenshot can't show
them. Instead, each window is captured individually through Hyprland's
toplevel-export protocol, which works for hidden workspaces too. The captures
are composited over the current wallpaper using geometry from each window's
`hyprctl` data. Captures are downscaled to thumbnail size while they're made,
and only run while a preview is open.

## Notes and limitations

- The preview has no bar, window decorations, or shadows — just windows over
  wallpaper, like most workspace overviews.
- A fullscreen window covers the whole preview, as it does on screen.
- Overlapping floating windows use focus order as a z-order hint, which is
  close but not always pixel-exact.
- Previews are live while hovered; if you're on a very busy workspace you may
  briefly notice a little GPU cost. This is by design and stops on unhover.

## Files

| File                 | Purpose                                              |
| -------------------- | ---------------------------------------------------- |
| `Workspaces.qml`     | Workspace buttons and the hover state machine         |
| `WorkspacePreview.qml` | Wallpaper + window captures composite               |
| `HoverPreviewCard.qml` | Passive themed popup the preview renders into       |

## Removing

```bash
omarchy plugin remove workspaces
```

You can bring it back any time with `omarchy plugin clone omarchy.workspaces`.
