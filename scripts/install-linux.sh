#!/usr/bin/env bash
# builds swiftify and installs it for you under ~/.local, or for everyone
# under /usr/local.
#
#   scripts/install-linux.sh [--system] [--no-deps] [--tests]
#
#   --system    install under /usr/local (asks for sudo) instead of ~/.local
#   --no-deps   leave the dependencies alone; they are already installed
#   --tests     build the tests too, and stop if they fail
#
# the dependencies are installed on arch (and its derivatives), gentoo and
# fedora. elsewhere install them yourself and run this with --no-deps: qt
# 6.9 or newer (base with d-bus, opengl and wayland, declarative, shader
# tools, wayland), qtkeychain and qcoro for qt 6, libpulse, the alsa,
# openssl and pkg-config development packages, cmake, ninja and rust.
set -euo pipefail

prefix="$HOME/.local"
system=false
# what runs the install and the caches: sudo for a system install
as_root=""
deps=true
tests=false
for argument in "$@"; do
    case "$argument" in
        --system)
            system=true
            prefix=/usr/local
            as_root=sudo
            ;;
        --no-deps) deps=false ;;
        --tests) tests=true ;;
        -h | --help)
            sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "unknown option: $argument (try --help)" >&2
            exit 2
            ;;
    esac
done

root="$(cd "$(dirname "$0")/.." && pwd)"
build="$root/build"

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
fail() {
    printf '\n\033[1;31m%s\033[0m\n' "$*" >&2
    exit 1
}

# which family the distribution belongs to, from os-release
family() {
    local id="" like=""
    if [[ -r /etc/os-release ]]; then
        id=$(. /etc/os-release && echo "${ID:-}")
        like=$(. /etc/os-release && echo "${ID_LIKE:-}")
    fi
    for name in $id $like; do
        case "$name" in
            arch | gentoo | fedora)
                echo "$name"
                return
                ;;
        esac
    done
    echo other
}

if $deps; then
    step "installing the dependencies"
    case "$(family)" in
        arch)
            sudo pacman -S --needed git qt6-base qt6-declarative qt6-shadertools qt6-wayland qtkeychain-qt6 qcoro \
                libpulse alsa-lib openssl cmake ninja rust pkgconf
            ;;
        gentoo)
            # qtbase needs d-bus, opengl and wayland, and qtkeychain the
            # secret service (keyring), or the login cannot be saved
            uses=$'dev-qt/qtbase dbus opengl wayland\ndev-libs/qtkeychain keyring'
            if [[ -d /etc/portage/package.use ]]; then
                [[ -e /etc/portage/package.use/swiftify ]] || echo "$uses" | sudo tee /etc/portage/package.use/swiftify >/dev/null
            elif ! grep -q "dev-libs/qtkeychain" /etc/portage/package.use 2>/dev/null; then
                echo "$uses" | sudo tee -a /etc/portage/package.use >/dev/null
            fi
            sudo emerge --ask --noreplace dev-vcs/git dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtshadertools \
                dev-libs/qtkeychain dev-libs/qcoro media-libs/libpulse media-libs/alsa-lib dev-libs/openssl \
                dev-build/cmake dev-build/ninja virtual/rust virtual/pkgconfig
            ;;
        fedora)
            sudo dnf install git gcc-c++ qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel \
                qt6-qtwayland-devel qtkeychain-qt6-devel qcoro-qt6-devel pulseaudio-libs-devel alsa-lib-devel \
                openssl-devel pkgconf-pkg-config cmake ninja-build rust cargo
            ;;
        *)
            fail "this script knows the packages for arch, gentoo and fedora only. install the dependencies listed in
scripts/install-linux.sh --help yourself, then run it again with --no-deps"
            ;;
    esac
fi
# rustup's cargo, if that is where rust came from
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
command -v cargo >/dev/null 2>&1 || fail "rust is needed: install it with your package manager or from https://rustup.rs"

step "configuring"
cmake -S "$root" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING="$($tests && echo ON || echo OFF)" -DCMAKE_INSTALL_PREFIX="$prefix"

step "building"
cmake --build "$build"

if $tests; then
    step "running the tests"
    ctest --test-dir "$build" --output-on-failure || fail "the tests failed; nothing was installed"
fi

step "installing under $prefix"
$as_root cmake --install "$build"

# so launchers find the new entry and its icon straight away
applications="$prefix/share/applications"
icons="$prefix/share/icons/hicolor"
if command -v update-desktop-database >/dev/null 2>&1; then
    $as_root update-desktop-database "$applications" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1 && [[ -d "$icons" ]]; then
    $as_root gtk-update-icon-cache -q -t "$icons" >/dev/null 2>&1 || true
fi

printf '\n\033[1;32mdone:\033[0m %s/bin/swiftify\n' "$prefix"
if ! $system && [[ ":$PATH:" != *":$prefix/bin:"* ]]; then
    echo "add $prefix/bin to your PATH to run swiftify from a terminal or a keybind"
fi
