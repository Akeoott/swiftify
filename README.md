# Swiftify

A Spotify player for the desktop, built with Qt Quick on top of a Rust core
that wraps [librespot](https://github.com/librespot-org/librespot). It follows
Material 3 Expressive and has an immersive player, synced lyrics,
visualizers, an equalizer, and local files with local playlists.

It runs on Linux (made for Wayland and Hyprland) and macOS. Windows builds
are untested so far.

## Before you start

- **Spotify Premium.** Playback goes through librespot, which needs a
  Premium account.
- **Your own Spotify Client ID.** Your library, playlists and search come
  from the Spotify Web API through a developer app of your own. The first
  launch walks you through it: create an app in the
  [Spotify Developer Dashboard](https://developer.spotify.com/dashboard), add
  `http://127.0.0.1:8898/login` as a redirect URI, and paste the app's
  Client ID into Swiftify. The Client Secret is not needed.

## What every build needs

- Qt 6.9 or newer: Qt Base, Qt Declarative and Qt Shader Tools
- QtKeychain and QCoro 0.10 or newer, both built for Qt 6
- CMake 3.24 or newer, Ninja, and a C++20 compiler
- Rust (stable, from [rustup](https://rustup.rs))

The configure step needs network access: it fetches
[Corrosion](https://github.com/corrosion-rs/corrosion), which builds the
Rust core inside the CMake build, and two fonts (Material Symbols Rounded and
Google Sans Flex), each checked against a pinned hash.

The tests build by default. The commands below turn them off with
`-DBUILD_TESTING=OFF`; leave that out and run `ctest --test-dir build` to
run them.

## macOS

Install the tools, then build:

```sh
xcode-select --install
brew install qtbase qtdeclarative qtshadertools qtkeychain qcoro6 cmake ninja
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
cmake --build build
```

This makes `build/swiftify.app`, signed ad hoc so it opens without a
developer account. With the full Xcode installed, the app icon is compiled
with `actool` and gets macOS 26's glass, dark and tinted looks; with only the
command line tools it is made from the PNGs.

**Where it goes:** `/Applications` (or `~/Applications`). Copy it under a
name of its own: the disk ignores case, so `swiftify.app` would replace the
native Swiftify app if you have it.

```sh
ditto build/swiftify.app "/Applications/Swiftify Qt.app"
```

## Linux

Install the dependencies. On Arch:

```sh
sudo pacman -S --needed qt6-base qt6-declarative qt6-shadertools qt6-wayland qtkeychain-qt6 qcoro libpulse alsa-lib openssl cmake ninja rust pkgconf
```

On Gentoo, with these USE flags in `/etc/portage/package.use/swiftify`:

```
dev-qt/qtbase dbus opengl wayland
dev-libs/qtkeychain keyring
```

```sh
sudo emerge --ask --noreplace dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtshadertools dev-libs/qtkeychain dev-libs/qcoro media-libs/libpulse media-libs/alsa-lib dev-libs/openssl dev-build/cmake dev-build/ninja virtual/rust virtual/pkgconfig
```

Elsewhere you need the same pieces: Qt 6 with D-Bus, OpenGL and Wayland,
QtKeychain and QCoro for Qt 6, libpulse, and the ALSA, OpenSSL and
pkg-config development packages.

Then build and install into your home:

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build
cmake --install build
```

**Where it goes:** `cmake --install` puts `swiftify` in `~/.local/bin`
(which has to be on your `PATH`), the desktop entry in
`~/.local/share/applications`, the icons under `~/.local/share/icons` and the
fonts in `~/.local/share/swiftify/fonts`. For everyone on the machine,
configure with `-DCMAKE_INSTALL_PREFIX=/usr/local` and run
`sudo cmake --install build`. On Arch you can build a package instead:
`cd packaging/arch && makepkg -si` installs it under `/usr`.

The login is saved through QtKeychain in the Secret Service, so something
has to provide one: gnome-keyring, KWallet or KeePassXC.

The Linux build also hooks into MPRIS (media keys, `playerctl` and shell
media widgets), logind (it pauses before the machine sleeps),
PipeWire/PulseAudio device changes, and the tray.
`-DSWIFTIFY_DESKTOP_INTEGRATION=OFF` leaves those out.

## Windows (untested)

Swiftify has not been built on Windows yet. These are the expected steps.

Install Visual Studio 2022 (or its Build Tools) with *Desktop development
with C++*, Qt 6.9 or newer for *MSVC 2022 64-bit* with *Qt Shader Tools* from
the Qt online installer, Rust from rustup (its default MSVC toolchain), and
Git. CMake and Ninja come with Visual Studio.

Open an *x64 Native Tools Command Prompt for VS 2022*. Set `QT` to your Qt
install, then build QtKeychain and QCoro into `C:\deps`:

```bat
set QT=C:\Qt\6.9.3\msvc2022_64

git clone https://github.com/frankosterfeld/qtkeychain
cmake -S qtkeychain -B qtkeychain\build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_WITH_QT6=ON -DBUILD_TEST_APPLICATION=OFF -DBUILD_TRANSLATIONS=OFF -DCMAKE_PREFIX_PATH=%QT% -DCMAKE_INSTALL_PREFIX=C:\deps
cmake --build qtkeychain\build --target install

git clone https://github.com/qcoro/qcoro
cmake -S qcoro -B qcoro\build -G Ninja -DCMAKE_BUILD_TYPE=Release -DUSE_QT_VERSION=6 -DQCORO_WITH_QTDBUS=OFF -DQCORO_WITH_QTWEBSOCKETS=OFF -DQCORO_BUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DCMAKE_PREFIX_PATH=%QT% -DCMAKE_INSTALL_PREFIX=C:\deps
cmake --build qcoro\build --target install
```

Then build Swiftify from this folder:

```bat
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_PREFIX_PATH="%QT%;C:\deps"
cmake --build build
```

**Where it goes:** your user's Programs folder. Install it there, then
gather Qt's libraries and plugins next to it with `windeployqt`, and copy in
QtKeychain's and QCoro's DLLs, which `windeployqt` does not know about:

```bat
cmake --install build --prefix "%LOCALAPPDATA%\Programs\Swiftify"
%QT%\bin\windeployqt --release --qmldir qml "%LOCALAPPDATA%\Programs\Swiftify\bin\swiftify.exe"
copy C:\deps\bin\*.dll "%LOCALAPPDATA%\Programs\Swiftify\bin\"
```

Start it from `%LOCALAPPDATA%\Programs\Swiftify\bin\swiftify.exe`, or pin
that to Start. The fonts are installed to `...\Swiftify\share\swiftify\fonts`,
where the app looks for them.

## Command line

Only one Swiftify runs at a time. Launching it again hands its command to
the running one, which makes these good for keyboard shortcuts:

| Flag | |
|---|---|
| `--immersive` | open the immersive player |
| `--play-pause` | play or pause |
| `--next` | next song |
| `--previous` | previous song |

On Hyprland, for example:

```ini
bind = SUPER SHIFT, M, exec, swiftify --immersive
bind = , XF86AudioPlay, exec, swiftify --play-pause
```

## What's where

| Path | |
|---|---|
| `src` | the C++ side: settings, the Spotify session and library, playback, rendering, system integration |
| `qml` | the interface |
| `shaders` | GLSL, compiled to `.qsb` at build time |
| `spotify-core` | the Rust core: librespot, audio output, the spectrum analyser, local files |
| `third_party` | material-color-utilities and rounded-polygon-qmljs (both Apache-2.0) |
| `tools/shape_atlas` | draws Material 3's shapes into the atlas the app reads, at build time |
| `packaging` | the desktop entry, icons, the macOS Info.plist and an Arch PKGBUILD |
| `tests` | Qt Test suites |
