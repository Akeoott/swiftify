#!/usr/bin/env bash
# builds swiftify and installs it as "Swiftify Qt.app" in /Applications.
#
#   scripts/install-macos.sh [--to DIR] [--no-deps] [--tests]
#
#   --to DIR    install into DIR instead of /Applications (~/Applications, say)
#   --no-deps   leave the dependencies alone; they are already installed
#   --tests     build the tests too, and stop if they fail
#
# needs homebrew and apple's command line tools (or xcode). the app goes in
# under a name of its own: the disk ignores case, so "swiftify.app" would
# replace the native swiftify app.
set -euo pipefail

destination=/Applications
deps=true
tests=false
while (($#)); do
    case "$1" in
        --to)
            [[ $# -ge 2 ]] || { echo "--to needs a folder" >&2; exit 2; }
            destination=$2
            shift
            ;;
        --no-deps) deps=false ;;
        --tests) tests=true ;;
        -h | --help)
            sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "unknown option: $1 (try --help)" >&2
            exit 2
            ;;
    esac
    shift
done

root="$(cd "$(dirname "$0")/.." && pwd)"
build="$root/build"
app="$destination/Swiftify Qt.app"
# the copy being replaced, by its full path: another copy elsewhere is left be
binary="$app/Contents/MacOS/swiftify"

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
fail() {
    printf '\n\033[1;31m%s\033[0m\n' "$*" >&2
    exit 1
}

if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    fail "install the command line tools from the dialog that opened, then run this again"
fi
command -v brew >/dev/null 2>&1 || fail "homebrew is needed: install it from https://brew.sh, then run this again"

if $deps; then
    step "installing the dependencies"
    brew install qtbase qtdeclarative qtshadertools qtkeychain qcoro6 cmake ninja
    if ! command -v cargo >/dev/null 2>&1 && [[ ! -x "$HOME/.cargo/bin/cargo" ]]; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
fi
# rustup's cargo, in this shell too
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
command -v cargo >/dev/null 2>&1 || fail "rust is needed: install it from https://rustup.rs, then run this again"

step "configuring"
cmake -S "$root" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING="$($tests && echo ON || echo OFF)" -DCMAKE_PREFIX_PATH="$(brew --prefix)"

step "building"
# the build signs the bundle. a checkout in an icloud-synced folder can have
# finder information put back on it between the build clearing it and
# signing it; a second go goes through
signed=false
for attempt in 1 2 3; do
    if cmake --build "$build" && codesign -v "$build/swiftify.app" 2>/dev/null; then
        signed=true
        break
    fi
    echo "the app did not sign (attempt $attempt); building again"
    touch "$build/swiftify.app/Contents/MacOS/swiftify" 2>/dev/null || true
done
$signed || fail "the app would not build or sign"

if $tests; then
    step "running the tests"
    ctest --test-dir "$build" --output-on-failure || fail "the tests failed; nothing was installed"
fi

step "installing to $app"
mkdir -p "$destination"
# quit a running copy as its menu would (it takes a terminate as a quit),
# so it saves what it has
if pgrep -f "$binary" >/dev/null; then
    pkill -TERM -f "$binary" || true
    for _ in $(seq 1 40); do
        pgrep -f "$binary" >/dev/null || break
        sleep 0.25
    done
    pgrep -f "$binary" >/dev/null && fail "quit Swiftify Qt first, then run this again"
fi
rm -rf "$app"
ditto "$build/swiftify.app" "$app"
# so finder and the dock show its icon at once
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app" || true

printf '\n\033[1;32mdone:\033[0m %s\n' "$app"
