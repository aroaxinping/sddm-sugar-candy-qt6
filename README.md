# Sugar Candy for SDDM — Qt6 port

Qt6 / Plasma 6 port of [Marian Arlt's Sugar Candy](https://framagit.org/MarianArlt/sddm-sugar-candy)
SDDM theme. The original targets Qt5 only and has not been updated since February 2020.

**Visually identical to the original.** This fork changes nothing but the imports and the
Qt version declaration.

## Why this exists

On a current Arch / Plasma 6 system, the upstream theme makes the SDDM greeter die on startup:

```
sddm-greeter: error while loading shared libraries: libQt5Quick.so.5:
cannot open shared object file: No such file or directory
```

The cause is that `metadata.desktop` declares no `QtVersion`, so SDDM launches its **Qt5**
greeter — and Qt5 is no longer installed on most modern systems. The result is a login
screen that never appears and a drop to a TTY.

## What changed

| | Upstream | Here |
|---|---|---|
| `import QtQuick 2.11` etc. | versioned imports | unversioned (Qt6 style) |
| `QtGraphicalEffects 1.0` | removed in Qt6 | `Qt5Compat.GraphicalEffects` |
| `metadata.desktop` | no `QtVersion` | `QtVersion=6` |

24 import lines across 8 QML files. `GaussianBlur` in `Main.qml` is the only
`QtGraphicalEffects` type the theme uses, which is why the port is this small.

Verified with `qmllint` from Qt 6.11 — no errors in any file.

## Fixes beyond the port

The migration exposed a few genuine bugs in the upstream theme. These are fixed here.

### Password characters were revealed for a full second

Upstream hardcoded a one-second reveal of each typed character:

```qml
passwordMaskDelay: config.ForceHideCompletePassword == "true" ? undefined : 1000
```

This is not a Qt default — the theme asked for it. Anyone glancing at the screen could read
the password one character at a time. Now masked immediately (`passwordMaskDelay: 0`).

The "Show Password" checkbox is untouched: revealing the password stays a deliberate action.

### Login form stretched on ultrawide displays

The form was sized as a fraction of total screen width:

```qml
width: parent.width / 2.5
```

On 1920px that is 768px. On a 5120px ultrawide it is **2048px** — a form as wide as an entire
monitor, which looks flat and disproportionate.

Now capped: `Math.min(width / 2.5, height * 0.72)`. The `0.72` is calibrated so **16:9 output is
identical to upstream** — nothing changes on standard displays. No resolution is hardcoded.

The virtual keyboard was also spanning the full screen width and is now capped the same way.

### `Screen.ScreenWidth` does not exist

```qml
width: config.ScreenWidth || Screen.ScreenWidth   // undefined
```

The fallback referenced a property that does not exist in Qt, so leaving `ScreenWidth` empty in
`theme.conf` left the root window width `undefined`. Fixed to `Screen.width`.

## New `theme.conf` options

All optional; the theme behaves exactly as before if you leave them alone.

| Option | Default | Purpose |
|---|---|---|
| `FormMaxWidth` | `""` | Max login form width in px. Empty = automatic, proportional to screen height. |
| `BackgroundFillBlurBackdrop` | `"false"` | Fill leftover space with a cropped, blurred copy of the background instead of empty bars. Only applies when `ScaleImageCropped="false"`. |
| `BackdropBlurRadius` | `"64"` | Blur strength for the backdrop above. |

On very wide displays, `ScaleImageCropped="false"` together with
`BackgroundFillBlurBackdrop="true"` shows a 16:9 wallpaper whole and centred instead of
magnifying and cropping it.

## Requirements

- SDDM 0.21+ built against Qt6
- `qt5compat` (provides `Qt5Compat.GraphicalEffects`)

## Install

```sh
sudo cp -r . /usr/share/sddm/themes/sugar-candy-qt6
sudo sed -i 's/^Current=.*/Current=sugar-candy-qt6/' /etc/sddm.conf.d/theme.conf.user
sudo systemctl restart sddm
```

Configuration is unchanged from upstream — see `theme.conf` and the original documentation.

## Credits

All design and original code by **Marian Arlt**. This fork only performs the Qt6 migration.

- Upstream: <https://framagit.org/MarianArlt/sddm-sugar-candy>
- Mirrors: <https://www.opencode.net/marianarlt/sddm-sugar-candy> ·
  <https://git.opendesktop.org/marianarlt/sddm-sugar-candy>
- KDE Store: <https://store.kde.org/p/1312658>

Upstream's original README is preserved as `README.upstream.md`.

## License

GPL-3.0-or-later, same as upstream. See `COPYING`.
