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
