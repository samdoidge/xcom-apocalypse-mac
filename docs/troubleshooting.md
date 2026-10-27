# Troubleshooting

## Get a real log first

Launching through `open` hides the emulator's output. Run the binary directly to see what DOSBox is doing:

```sh
"/Applications/DOSBox Staging.app/Contents/MacOS/dosbox" \
  --noprimaryconf --nolocalconf \
  --conf "$HOME/Games/XCOMApocalypse/dosbox.conf"
```

You should see the config load, the `C:` mount, the CD image mount, and then the game start. The first error after `CONFIG:` is usually the real problem.

## The game exits immediately / black screen

1. Check the paths in `dosbox.conf` are absolute. DOSBox does not expand `~` or environment variables.
2. Confirm the files are where the config says:

   ```sh
   ls -l "$HOME/Games/XCOMApocalypse/XCOMAPOC.EXE"
   ls -l "$HOME/Games/XCOMApocalypse/CD/"
   ```

3. Run the game from the DOS prompt to see the DOS-level error. Change the `[autoexec]` tail to `C:` only, launch, then type `xcomapoc.exe`.

## The CD image fails to mount or the game asks for the CD

DOSBox Staging 0.83 uses `mount D "...cue" -t cdrom`; 0.82 and earlier use `imgmount D "...cue" -t cdrom`. `setup.sh` writes the correct form for the installed version. `imgmount` still works on 0.83 but prints a deprecation warning.

The `.cue` is a text file. Its `FILE` line must name the `.bin` exactly as it appears on disk:

```
FILE "XCOM.BIN" BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
```

If you renamed the image, edit the `FILE` line. Keep both files in the same folder and point the mount command at the `.cue`, not the `.bin`.

A data-only rip (one `TRACK`) plays without CD music. If your image has audio tracks, the `.cue` lists `TRACK 02 AUDIO`, `TRACK 03 AUDIO`, and so on.

`MOUNT: MSCDEX: Failure: File is either no ISO/CUE image or contains errors` means the `.bin` is truncated, zero bytes, or not the file the `.cue` names. Compare the `FILE` line with `ls -l`; a full X-COM Apocalypse image is hundreds of megabytes.

## No music or no sound effects

- Press `Cmd`+`F8` — it toggles mute.
- Keep `sbtype = sb16` and `irq = 7`. GOG's own config uses those values.
- The game's setup utility can retest audio. Run `SETUP.EXE` from the mounted `C:` drive if the music device is misconfigured.

## The mouse is captured and I can't click anything else

Press `Cmd`+`F10` to release the mouse. Middle-click also releases it. `Cmd`+`F1` opens the key mapper if a binding is wrong.

## The game runs too fast or too slow

`cpu_cycles = max` lets the emulated CPU run as fast as the host. That is usually right for this game, but if the simulation is too quick:

```ini
[cpu]
cpu_cycles = 60000
```

Tune it live with `Cmd`+`F11` / `Cmd`+`F12`, then write down the value that feels right. `Alt`+`F12` toggles turbo.

## Fullscreen is on the wrong display

Start windowed (`fullscreen = false`), drag the window to the display you want, then press `Alt`+`Enter`. macOS remembers the arrangement, not DOSBox.

The `sharp` shader is the right default for 640×480-era graphics. If you prefer softer scaling, remove the `glshader` line or try another shader from `--list-glshaders`.

## macOS says "DOSBox Staging is damaged"

This is Gatekeeper quarantine, not a corrupt download. Homebrew installs avoid it; manual downloads may not:

```sh
xattr -dr com.apple.quarantine "/Applications/DOSBox Staging.app"
```

## The `.app` opens but nothing happens

The wrapper launches the emulator by name:

```sh
open -na "DOSBox Staging" --args -conf "$HOME/Games/XCOMApocalypse/dosbox.conf"
```

- `DOSBox Staging.app` must be installed in `/Applications`.
- Test the command above in Terminal. If it works, rebuild the app: `./scripts/make-app.sh`.
- Inspect the compiled script with `osadecompile "$HOME/Applications/X-COM Apocalypse.app"`.

## I launched it twice and lost progress

Each launch starts a new DOSBox instance and the game writes saves at exit. Close the game before launching another instance. If a save is corrupted, restore `SAVEGAME` from Time Machine; the files are plain and versioned by slot.

## Installing from GOG

```sh
brew install innoextract
innoextract -d gog setup_xcom_apocalypse_*.exe
```

The game lands under `gog/app`. Either point `GAME_DIR` at that folder:

```sh
GAME_DIR="$PWD/gog/app" ./scripts/setup.sh
```

or copy it into place:

```sh
cp -R gog/app/. "$HOME/Games/XCOMApocalypse/"
```

Steam sells the same DOS data. There is no macOS Steam client build of the game; use the installed data files, not the Windows client.

## Config warnings after upgrading DOSBox Staging

- `Invalid option 'shader'` on 0.82 or earlier: use `glshader = sharp`.
- `Deprecated setting 'glshader'` on 0.83: use `shader = sharp`.
- `'imgmount' is deprecated` on 0.83: use `mount D "...cue" -t cdrom`.
- `Invalid 'cpu_cycles_protected' setting` on 0.82: delete that line; it only exists on 0.83+.
- `cpu_cycles_protected` warning on 0.83 with `cpu_cycles = max`: add `cpu_cycles_protected = max` under `[cpu]`.

Re-running `setup.sh` does not rewrite an existing config; delete `dosbox.conf` first if you want the script to regenerate it for the current version.

## Saves and backups

`~/Games/XCOMApocalypse/SAVEGAME` is the only state that matters. The config, the CD image, and the game files are replaceable. Back up `SAVEGAME` (Time Machine does this by default) before experiments with `cpu_cycles` or OpenApoc.
