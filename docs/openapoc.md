# OpenApoc on macOS

[OpenApoc](https://github.com/OpenApoc/OpenApoc) is an open-source C++/SDL2 reimplementation of the X-COM: Apocalypse engine. It adds widescreen resolutions, 60 fps, mod support, and XML save editing. It still requires the original game data and is alpha: expect bugs and missing features.

There are no prebuilt macOS packages. You build it with CMake and Homebrew dependencies. The upstream instructions were tested on macOS Sequoia 15.6; this page tracks them and adds the GOG BIN/CUE path.

**Known issue:** the GL2 renderer has been reported to show a black window on Apple Silicon while the intro, music, and input still work ([upstream PR #1636](https://github.com/OpenApoc/OpenApoc/pull/1636), unmerged). Upstream's direction is a GLES3 renderer. Treat OpenApoc on macOS as build-it-and-see; the DOSBox route is the one that currently plays.

## Build

```sh
git clone https://github.com/OpenApoc/OpenApoc.git
cd OpenApoc
git submodule update --init --recursive

brew install cmake boost pkg-config sdl2 qt@6 libvorbis
echo 'export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"' >> ~/.zprofile
export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"
```

The build extracts data tables from the original disc image, so an installed game directory on its own is not enough. A Steam `cd.iso` works as-is:

```sh
cp /path/to/cd.iso data/
```

A GOG install ships `XCOM.cue` + `XCOM.BIN` instead of an ISO. Either rename the cue and leave the BIN next to it:

```sh
cp /path/to/XCOM.cue data/cd.iso
cp /path/to/XCOM.BIN data/
```

or keep the filenames and point CMake at the cue sheet:

```sh
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCD_PATH=/path/to/XCOM.cue ..
```

Point `CD_PATH` at the `.cue` file, not the directory containing it. The image must include the audio tracks; without them the game builds but starts with sound disabled.

Then:

```sh
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
make -j"$(sysctl -n hw.ncpu)"
open ./build/bin/OpenApoc.app
```

OpenApoc expects the game data in `data/` next to the executable, so run it from the build directory the first time. The launcher lets you point at the data folder if you move it.

## Notes

- OpenApoc requires OpenGL 2.0-capable hardware. That is not the current blocker on macOS; the GL2 backend itself is (see the known issue above).
- Saves are XML inside a ZIP, not compatible with DOSBox saves.
- Use a lawful image that includes the audio tracks. Pirated images often omit them, and the game starts with sound disabled.
- For build errors, the upstream README and Discord are the source of truth: <https://github.com/OpenApoc/OpenApoc>.

## Which should I play?

Use DOSBox Staging if you want the 1997 game as it shipped. Use OpenApoc if you have already finished it and want widescreen, mods, or a smoother frame rate — and can tolerate alpha-state bugs and a currently broken macOS renderer.
