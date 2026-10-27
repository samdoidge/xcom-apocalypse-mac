# X-COM: Apocalypse on macOS (Apple Silicon)

[![GitHub stars](https://img.shields.io/github/stars/samdoidge/xcom-apocalypse-mac?style=flat)](https://github.com/samdoidge/xcom-apocalypse-mac/stargazers)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Play the 1997 original — not a remake — on a modern Mac with DOSBox Staging. Native Universal binary, fullscreen, Sound Blaster audio, and save files that live in a folder you can back up.

**Verified on** macOS 26 (Apple Silicon) with DOSBox Staging 0.82.2 and 0.83.0. Intel Macs work too.

**No game files are included.** You need to own X-COM: Apocalypse.

## Why this route

| Option | State | Pick it when |
| --- | --- | --- |
| **DOSBox Staging** (this guide) | Runs the original DOS game, natively on Apple Silicon | You want the real 1997 game with minimal fuss |
| [OpenApoc](https://github.com/OpenApoc/OpenApoc) | Open-source engine rewrite, alpha, builds from source | You want widescreen, 60 fps, mods, XML saves |
| Windows VM / Whisky | The GOG Windows build inside an emulator | You already have a VM and no interest in DOSBox |

X-COM: Apocalypse was never ported to macOS. The GOG release is the DOS game wrapped in a Windows installer; the data files inside are what you need. DOSBox Staging runs those files natively and gives you a fullscreen, correctly-timed game with working audio.

## Quick start

```sh
brew install --cask dosbox-staging-app
git clone https://github.com/samdoidge/xcom-apocalypse-mac.git
cd xcom-apocalypse-mac
./scripts/setup.sh --source "/path/to/folder/with/XCOMAPOC.EXE"
```

`setup.sh` copies the game to `~/Games/XCOMApocalypse`, writes `dosbox.conf`, and builds `~/Applications/X-COM Apocalypse.app`. Run it without `--source` if the game is already in that folder — it will regenerate the config and app wrapper. Pass a GOG `setup_xcom_apocalypse_*.exe` and the script unpacks it with `innoextract`.

## Manual setup

### 1. Put the game files somewhere sane

Any folder works. This guide uses:

```
~/Games/XCOMApocalypse/
├── XCOMAPOC.EXE
├── ...game data...
├── CD/
│   ├── XCOM.cue
│   └── XCOM.BIN
└── SAVEGAME/          # created by the game
```

- **Own the CD?** Rip the disc to BIN/CUE, keep both files together, and point the config at the `.cue`.
- **GOG?** `brew install innoextract`, then `innoextract -d gog setup_xcom_apocalypse_*.exe`. Copy the contents of the extracted `app/` folder into `~/Games/XCOMApocalypse`. Move the `.cue`/`.bin` pair into `CD/` if you want to match this layout.
- The `.cue` must reference the `.bin` by the exact filename sitting next to it. If you rename one, edit the `FILE` line in the `.cue`.

### 2. Install DOSBox Staging

```sh
brew install --cask dosbox-staging-app
```

Installs `/Applications/DOSBox Staging.app`. Requires macOS 12 or later.

### 3. Config

Save as `~/Games/XCOMApocalypse/dosbox.conf`, replacing `/Users/you` with your home directory:

```ini
# X-COM: Apocalypse — DOSBox Staging
[sdl]
fullscreen = true

[capture]
capture_dir = /Users/you/Movies/XCOMApocalypse

[dosbox]
machine = svga_s3
memsize = 16

[cpu]
cpu_cycles = max
cpu_cycles_protected = max

[render]
shader = sharp

[sblaster]
sbtype = sb16
irq = 7

[autoexec]
@echo off
mount C "/Users/you/Games/XCOMApocalypse"
mount D "/Users/you/Games/XCOMApocalypse/CD/XCOM.cue" -t cdrom
C:
xcomapoc.exe
exit
```

> **DOSBox Staging 0.82 and earlier:** use `glshader = sharp`, replace `mount D` with `imgmount D`, and delete the `cpu_cycles_protected` line. `setup.sh` detects the installed version and writes the right variant.

What matters:

| Setting | Why |
| --- | --- |
| `machine = svga_s3` | The game's SVGA mode; matches GOG's own config |
| `memsize = 16` | Plenty for DOS plus the game; more buys nothing |
| `cpu_cycles = max` | Smooth real-time simulation on Apple Silicon. If the game runs too fast, use a fixed number such as `cpu_cycles = 60000` |
| `cpu_cycles_protected = max` | Matches the protected-mode cycle setting on 0.83+, otherwise it warns and falls back to `auto` |
| `shader = sharp` | Crisp upscaling instead of blurry bilinear |
| `sbtype = sb16`, `irq = 7` | Music and effects through the emulated Sound Blaster |
| `mount D ... -t cdrom` | The game expects the disc mounted, even though it runs from the hard disk |

### 4. Launch

```sh
open -na "DOSBox Staging" --args -conf "/Users/you/Games/XCOMApocalypse/dosbox.conf"
```

`-n` starts a fresh instance so an already-running DOSBox does not swallow the config; `-a` selects the app by name.

### 5. Make it a real app

```sh
./scripts/make-app.sh
```

Builds `~/Applications/X-COM Apocalypse.app` — an AppleScript wrapper that launches DOSBox Staging with the config. Open it from Finder, Spotlight, Dock, or Launchpad. For a proper icon: Finder → Get Info → drag a `.icns` file onto the icon.

The wrapper runs:

```applescript
do shell script "open -na " & quoted form of "DOSBox Staging" & " --args -conf " & quoted form of "/Users/you/Games/XCOMApocalypse/dosbox.conf"
```

### Controls (macOS)

| Keys | Action |
| --- | --- |
| `Cmd`+`F10` | Release the mouse |
| `Alt`+`Enter` | Toggle fullscreen |
| `Cmd`+`F1` | Key mapper |
| `Cmd`+`P` | Pause emulation |
| `Cmd`+`F5` | Screenshot → `capture_dir` |
| `Cmd`+`F9` | Shut down DOSBox |
| `Cmd`+`F11` / `Cmd`+`F12` | Decrease / increase CPU cycles |

Quit through the game's own menu so it saves. `Cmd`+`F9` kills the emulator.

### Saves

`~/Games/XCOMApocalypse/SAVEGAME` — plain files, outside the app bundle. Back up the folder; Time Machine picks it up by default. Saves are not compatible with OpenApoc.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Black screen, then exit | The CD image path is wrong. Run the launch command in Terminal and read the log. |
| `CD-ROM not found` or no music | `.cue` and `.bin` names must match; the `.cue` needs a valid `FILE` line. |
| Mouse won't leave the window | `Cmd`+`F10` |
| Too fast or too slow | Replace `cpu_cycles = max` with a fixed value, e.g. `60000` |
| "DOSBox Staging is damaged" | Only happens with manual downloads. `xattr -dr com.apple.quarantine "/Applications/DOSBox Staging.app"` |
| The `.app` opens but no game | DOSBox Staging must be installed as `/Applications/DOSBox Staging.app`; the wrapper launches it by name. |
| No sound | Check `Cmd`+`F8` is not muted; keep `sbtype = sb16` and `irq = 7`. |

More detail: [docs/troubleshooting.md](docs/troubleshooting.md).

## OpenApoc (native rewrite)

[OpenApoc](https://github.com/OpenApoc/OpenApoc) reimplements the engine in C++/SDL2: widescreen, 60 fps, mods, XML save editing. It still needs the original data and is alpha. macOS builds from source; steps in [docs/openapoc.md](docs/openapoc.md).

## Legal

X-COM: Apocalypse is © 1997 Mythos Games / MicroProse, now owned by 2K. This repository contains no game data. Buy the game (GOG, Steam) or use your own CD. The config and scripts here are MIT-licensed.

If this saved you an evening, star the repo — it helps other people find it.
