# OpenApoc on macOS

[OpenApoc](https://github.com/OpenApoc/OpenApoc) is an open-source C++/SDL2 reimplementation of the X-COM: Apocalypse engine. It adds widescreen resolutions, 60 fps, mod support, and XML save editing. It still requires the original game data and is alpha: expect bugs and missing features.

There are no prebuilt macOS packages. You build it with CMake and Homebrew dependencies. The upstream instructions were tested on macOS Sequoia 15.6; this page tracks them and adds the BIN/CUE conversion step.

## Build

```sh
git clone https://github.com/OpenApoc/OpenApoc.git
cd OpenApoc
git submodule update --init --recursive

brew install cmake boost pkg-config sdl2 qt@6 libvorbis
echo 'export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"' >> ~/.zprofile
export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"
```

The build expects the original disc image at `data/cd.iso`. If you have a BIN/CUE pair:

```sh
brew install bchunk
bchunk XCOM.BIN XCOM.cue cd
cp cd01.iso data/cd.iso   # data track only; audio tracks are not needed for the build
```

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

- Requires OpenGL 2.0 support; every Apple Silicon Mac qualifies.
- Saves are XML inside a ZIP, not compatible with DOSBox saves.
- The upstream project recommends buying the game and using a legitimate image with all music files. Pirated images missing music cause crashes and map problems.
- For build errors, the upstream README and Discord are the source of truth: <https://github.com/OpenApoc/OpenApoc>.

## Which should I play?

Use DOSBox Staging if you want the 1997 game as it shipped. Use OpenApoc if you have already finished it and want widescreen, mods, or a smoother frame rate — and can tolerate alpha-state bugs.
