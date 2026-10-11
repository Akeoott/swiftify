# Swiftify

a spotify player for desktop, built with Qt Quick on top of a Rust core that
wraps [librespot](https://github.com/librespot-org/librespot). it follows
Material 3 Expressive (heavy inspo from end4) and has an immersive player,
synced lyrics, visualizers, an equalizer, and local files with local playlists
where u can edit the tracks metadata.

runs on linux (made for wayland and hyprland) and macos. haven't tested winslop though...

- [Before you start](#before-you-start)
- [Download](#download)
- [Building from source](#building-from-source)
  - [Build requirements](#build-requirements)
  - [macOS](#macos)
  - [Linux](#linux)
  - [Windows](#windows-untested)
- [Command line](#command-line)

## Before you start

- **spotify premium.** playback goes through librespot, and that only works with premium.
- **a spotify client id.** your library, playlists and search come from the spotify
  web api through your own developer app. the first launch walks u through it:
  make an app in the [spotify developer dashboard](https://developer.spotify.com/dashboard),
  add `http://127.0.0.1:8898/login` as a redirect uri, and paste the apps client id
  into swiftify. u dont need the client secret.

## Download

grab the latest build from [releases](https://github.com/shredos67/swiftify-qt/releases), no building needed.

| platform | file |
|---|---|
| macos (apple silicon) | `swiftify-macos-arm64.zip` |
| windows (x64 / arm64) | `swiftify-windows-x64.zip` / `swiftify-windows-arm64.zip` |
| linux (x64 / arm64) | `swiftify-linux-x64.AppImage` / `swiftify-linux-arm64.AppImage`, or the `.tar.gz` |

**macos:** unzip, drag `Swiftify Qt.app` into applications. macos blocks the first launch, so clear the quarantine flag, thanks apple :)

```sh
xattr -dr com.apple.quarantine "/Applications/Swiftify Qt.app"
```

**windows:** unzip and run `swiftify.exe`. dont move the exe out of its folder, it loads the dlls next to it. if u want it somewhere else, move the whole folder and make a shortcut to the exe. on arm64 u also need the [visual c++ redistributable (arm64)](https://aka.ms/vs/17/release/vc_redist.arm64.exe), if it complains about a missing MSVCP140.dll thats why.

**linux:** make the appimage executable, then run it:

```sh
chmod +x swiftify-linux-*.AppImage
./swiftify-linux-*.AppImage
```

if it complains about fuse, install `fuse2` (arch) or `libfuse2` (debian/ubuntu), or grab the tar.gz instead, it comes with an INSTALL.txt. the builds want a pretty recent distro (glibc 2.43, so fedora 44, arch, that kinda thing). on anything older, build it urself.

## Building from source

### Build requirements

- Qt 6.9 or newer: Qt Base, Qt Declarative and Qt Shader Tools
- QtKeychain and QCoro 0.10 or newer, both built for Qt 6
- CMake 3.24 or newer, Ninja, and a C++20 compiler
- Rust (stable, from [rustup](https://rustup.rs))

the first cmake run needs internet: it pulls [Corrosion](https://github.com/corrosion-rs/corrosion)
(which builds the rust core as part of the cmake build) and two fonts, Material Symbols
Rounded and Google Sans Flex, each checked against a pinned hash.

the commands below skip the tests with `-DBUILD_TESTING=OFF`. drop that and run
`ctest --test-dir build` if u want them.

### macOS

u need [homebrew](https://brew.sh) and apple's command line tools (`xcode-select --install`, or full xcode). then:

```sh
brew install qtbase qtdeclarative qtshadertools qtkeychain qcoro6 cmake ninja
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

git clone https://github.com/shredos67/swiftify-qt.git
cd swiftify-qt
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
cmake --build build
ditto build/swiftify.app "/Applications/Swiftify Qt.app"
```

it gets copied as `Swiftify Qt.app` on purpose: the mac disk ignores case, so `swiftify.app`
would overwrite the native swiftify app. it's signed ad hoc, so no developer account needed.
with full xcode installed the icon gets compiled with `actool` and picks up macos 26's glass,
dark and tinted looks; with just the command line tools it's built from the PNGs.

### Linux

on arch:

```sh
sudo pacman -S --needed git qt6-base qt6-declarative qt6-shadertools qt6-wayland qtkeychain-qt6 qcoro libpulse alsa-lib openssl cmake ninja rust pkgconf

git clone https://github.com/shredos67/swiftify-qt.git
cd swiftify-qt
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build
cmake --install build
```

on gentoo, add these USE flags to `/etc/portage/package.use/swiftify` first:

```
dev-qt/qtbase dbus opengl wayland
dev-libs/qtkeychain keyring
```

then:

```sh
sudo emerge --ask --noreplace dev-vcs/git dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtshadertools dev-libs/qtkeychain dev-libs/qcoro media-libs/libpulse media-libs/alsa-lib dev-libs/openssl dev-build/cmake dev-build/ninja virtual/rust virtual/pkgconfig

git clone https://github.com/shredos67/swiftify-qt.git
cd swiftify-qt
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build
cmake --install build
```

anywhere else, install the same reqs (Qt 6.9+ with D-Bus, OpenGL and Wayland, QtKeychain
and QCoro for Qt 6, libpulse, plus the ALSA, OpenSSL and pkg-config dev packages), then
run the last five lines above.

`cmake --install` drops `swiftify` in `~/.local/bin` (make sure that's on your `PATH`)
and the desktop entry, icons and fonts in `~/.local/share`. on arch u can build a
proper package instead, which installs to `/usr`:

```sh
git clone https://github.com/shredos67/swiftify-qt.git
cd swiftify-qt/packaging/arch
makepkg -si
```

ur login gets saved in the secret service through QtKeychain, so u need something
providing one: gnome-keyring, kwallet or keepassxc.

on linux it also hooks into MPRIS (media keys, `playerctl`, shell media widgets),
logind (pauses before the machine sleeps), pipewire/pulseaudio device changes, and
the tray. `-DSWIFTIFY_DESKTOP_INTEGRATION=OFF` turns those off.

### Windows (untested)

install visual studio 2022 (or just its build tools) with *Desktop development with C++*,
Qt 6.9+ for *MSVC 2022 64-bit* with *Qt Shader Tools* from the qt online installer,
rust from [rustup](https://rustup.rs), and git. then open an
*x64 Native Tools Command Prompt for VS 2022*, set `QT` to wherever ur qt is, and paste:

```bat
set QT=C:\Qt\6.11.2\msvc2022_64
cd /d %USERPROFILE%

git clone https://github.com/frankosterfeld/qtkeychain
cmake -S qtkeychain -B qtkeychain\build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_WITH_QT6=ON -DBUILD_TEST_APPLICATION=OFF -DBUILD_TRANSLATIONS=OFF -DCMAKE_PREFIX_PATH=%QT% -DCMAKE_INSTALL_PREFIX=C:\deps
cmake --build qtkeychain\build --target install

git clone https://github.com/qcoro/qcoro
cmake -S qcoro -B qcoro\build -G Ninja -DCMAKE_BUILD_TYPE=Release -DUSE_QT_VERSION=6 -DQCORO_WITH_QTDBUS=OFF -DQCORO_WITH_QTWEBSOCKETS=OFF -DQCORO_BUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DCMAKE_PREFIX_PATH=%QT% -DCMAKE_INSTALL_PREFIX=C:\deps
cmake --build qcoro\build --target install

git clone https://github.com/shredos67/swiftify-qt.git
cd swiftify-qt
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_PREFIX_PATH="%QT%;C:\deps"
cmake --build build
cmake --install build --prefix "%LOCALAPPDATA%\Programs\Swiftify"
%QT%\bin\windeployqt --release --qmldir qml "%LOCALAPPDATA%\Programs\Swiftify\bin\swiftify.exe"
copy C:\deps\bin\*.dll "%LOCALAPPDATA%\Programs\Swiftify\bin\"
```

that builds qtkeychain and qcoro into `C:\deps`, then swiftify, installs it to
`%LOCALAPPDATA%\Programs\Swiftify` and copies in all the dlls it needs. run
`swiftify.exe` from there or make a shortcut to it.

## Command line

only one swiftify runs at a time. launching it again just passes the command to the one
that's already running, so these work great as keybinds:

| flag | |
|---|---|
| `--immersive` | open the immersive player |
| `--play-pause` | play or pause |
| `--next` | next song |
| `--previous` | previous song |

on hyprland for example:

```ini
bind = SUPER SHIFT, M, exec, swiftify --immersive
bind = , XF86AudioPlay, exec, swiftify --play-pause
```
