# Swiftify

A Spotify player for desktop, built with Qt Quick on top of a Rust core
that wraps [librespot](https://github.com/librespot-org/librespot). It follows
Material 3 Expressive (heavy inspo from end4) and has an immersive player, synced lyrics,
visualizers, an equalizer, and local files with local playlists where you can change the tracks metadata.

It runs on Linux (made for Wayland and Hyprland) and macOS. Haven't tested winslop though...

## Before you start

- **Spotify Premium.** Playback goes through librespot, which needs a
  Premium account.
- **Spotify Client ID.** library, playlists and search come
  from the Spotify Web API through a developer app of your own. The first
  launch walks you through it: create an app in the
  [Spotify Developer Dashboard](https://developer.spotify.com/dashboard), add
  `http://127.0.0.1:8898/login` as a redirect URI, and paste the apps
  Client ID into Swiftify. The Client Secret is not needed.

## Build requirements

- Qt 6.9 or newer: Qt Base, Qt Declarative and Qt Shader Tools
- QtKeychain and QCoro 0.10 or newer, both built for Qt 6
- CMake 3.24 or newer, Ninja, and a C++20 compiler
- Rust (stable, from [rustup](https://rustup.rs))

The configure step needs network access: it fetches
[Corrosion](https://github.com/corrosion-rs/corrosion), which builds the
Rust core inside the CMake build, and two fonts (Material Symbols Rounded and
Google Sans Flex), each are checked against a pinned hash.

The install scripts below leave the tests out; give them `--tests`
(`-Tests` on Windows) to build and run the tests before installing.

## macOS

You need [Homebrew](https://brew.sh) and Apple's command line tools
(`xcode-select --install`, or the full Xcode). Then:

```sh
git clone https://github.com/shredos67/swiftify-qt.git
cd swiftify-qt
./scripts/install-macos.sh
```

The script installs the dependencies with Homebrew (and Rust with rustup if
it's missing), builds the app and installs it as
`/Applications/Swiftify Qt.app`. It goes in under that name because the disk
ignores case, so `swiftify.app` would replace the native Swiftify app.
`--to ~/Applications` installs it there instead, and `--no-deps` skips the
dependencies.

The app is signed ad hoc, so it opens without a developer account. With the
full Xcode installed, the app icon is compiled with `actool` and gets macOS
26's glass, dark and tinted looks; with only the command line tools it is
made from the PNGs.

## Linux

```sh
git clone https://github.com/shredos67/swiftify-qt.git
cd swiftify-qt
./scripts/install-linux.sh
```

The script installs the dependencies on Arch (and its derivatives), Gentoo
(with the USE flags QtBase and QtKeychain need) and Fedora, builds Swiftify
and installs it under `~/.local`: `swiftify` in `~/.local/bin` (which has to
be on your `PATH`), and the desktop entry, icons and fonts in
`~/.local/share`. `--system` installs it under `/usr/local` for everyone
instead.

Elsewhere you need the same reqs: Qt 6.9 or newer with D-Bus, OpenGL and
Wayland, QtKeychain and QCoro for Qt 6, libpulse, and the ALSA, OpenSSL and
pkg-config development packages. Install those yourself, then run the script
with `--no-deps`.

On Arch you can build a package instead, which installs under `/usr`:

```sh
git clone https://github.com/shredos67/swiftify-qt.git
cd swiftify-qt/packaging/arch
makepkg -si
```

The login is saved through QtKeychain in the Secret Service, so something
has to provide one: gnome-keyring, KWallet or KeePassXC.

The Linux build also hooks into MPRIS (media keys, `playerctl` and shell
media widgets), logind (it pauses before the machine sleeps),
PipeWire/PulseAudio device changes, and the tray.
`-DSWIFTIFY_DESKTOP_INTEGRATION=OFF` leaves those out.

## Windows (untested)

Swiftify has not been built on Windows yet; the script is the expected route.

Install Visual Studio 2022 (or its Build Tools) with *Desktop development
with C++*, Qt 6.9 or newer for *MSVC 2022 64-bit* with *Qt Shader Tools* from
the Qt online installer, Rust from [rustup](https://rustup.rs), and Git.
Then, in PowerShell:

```powershell
git clone https://github.com/shredos67/swiftify-qt.git
cd swiftify-qt
powershell -ExecutionPolicy Bypass -File scripts\install-windows.ps1
```

The script finds Visual Studio and the newest Qt under `C:\Qt` (`-QtDir`
points it at another), builds QtKeychain and QCoro once, then Swiftify, and
installs it to `%LOCALAPPDATA%\Programs\Swiftify` with a Start menu entry.
Quit Swiftify before running it again to update.

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
