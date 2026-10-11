# builds swiftify and installs it for the current user in
# %LOCALAPPDATA%\Programs\Swiftify, with a start menu shortcut. untested.
#
#   powershell -ExecutionPolicy Bypass -File scripts\install-windows.ps1 [-QtDir <qt>] [-Tests]
#
#   -QtDir   qt's msvc 64-bit folder, as C:\Qt\6.9.3\msvc2022_64; the newest
#            under C:\Qt otherwise
#   -Tests   build the tests too, and stop if they fail
#
# needs visual studio 2022 (or its build tools) with "desktop development
# with c++", qt 6.9 or newer for msvc 2022 64-bit with qt shader tools, rust
# from rustup, and git. qtkeychain and qcoro are built here, once.
param(
    [string]$QtDir,
    [switch]$Tests
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$build = Join-Path $root 'build'
$depsSources = Join-Path $root 'build-deps\src'
$deps = Join-Path $root 'build-deps\install'
$destination = Join-Path $env:LOCALAPPDATA 'Programs\Swiftify'

function Step([string]$message) { Write-Host "`n==> $message" -ForegroundColor Cyan }
function Fail([string]$message) { Write-Host "`n$message" -ForegroundColor Red; exit 1 }
# a native command, stopping at the first that fails
function Run([string]$command, [string[]]$arguments) {
    & $command @arguments
    if ($LASTEXITCODE -ne 0) { Fail "$command $($arguments -join ' ') failed" }
}

# visual studio's compiler, cmake and ninja, through its developer shell
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) {
    Fail 'Visual Studio 2022 or its Build Tools, with "Desktop development with C++", is needed.'
}
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { Fail 'Visual Studio has no C++ tools: add "Desktop development with C++" in the Visual Studio Installer.' }
Import-Module (Join-Path $vs 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64' | Out-Null
foreach ($tool in 'cmake', 'ninja') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Fail "$tool is missing: add ""C++ CMake tools for Windows"" in the Visual Studio Installer."
    }
}

# qt for msvc 64-bit: the one given, or the newest under C:\Qt
if (-not $QtDir) {
    $QtDir = Get-ChildItem 'C:\Qt' -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d+\.\d+(\.\d+)?$' } |
        Sort-Object { [version]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName 'msvc2022_64' } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1
}
if (-not $QtDir -or -not (Test-Path (Join-Path $QtDir 'lib\cmake\Qt6'))) {
    Fail 'Qt 6.9 or newer for MSVC 2022 64-bit is needed: install it with the Qt online installer, or pass -QtDir.'
}
Write-Host "Qt: $QtDir"

# rust from rustup, which may not be on this shell's path yet
$cargoBin = Join-Path $env:USERPROFILE '.cargo\bin'
if (-not (Get-Command cargo -ErrorAction SilentlyContinue) -and (Test-Path (Join-Path $cargoBin 'cargo.exe'))) {
    $env:PATH = "$cargoBin;$env:PATH"
}
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) { Fail 'Rust is needed: install it from https://rustup.rs, then run this again.' }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail 'Git is needed: install it from https://git-scm.com, then run this again.' }

# qtkeychain and qcoro, built for this qt into build-deps, once
function Dependency([string]$name, [string]$url, [string]$installed, [string[]]$options) {
    if (Test-Path (Join-Path $deps $installed)) { return }
    Step "building $name"
    $source = Join-Path $depsSources $name
    if (-not (Test-Path $source)) { Run git @('clone', '--depth', '1', $url, $source) }
    $objects = Join-Path $source 'build'
    Run cmake (@('-S', $source, '-B', $objects, '-G', 'Ninja', '-DCMAKE_BUILD_TYPE=Release',
                 "-DCMAKE_PREFIX_PATH=$QtDir", "-DCMAKE_INSTALL_PREFIX=$deps") + $options)
    Run cmake @('--build', $objects, '--target', 'install')
}
Dependency 'qtkeychain' 'https://github.com/frankosterfeld/qtkeychain' 'lib\cmake\Qt6Keychain' @(
    '-DBUILD_WITH_QT6=ON', '-DBUILD_TEST_APPLICATION=OFF', '-DBUILD_TRANSLATIONS=OFF')
Dependency 'qcoro' 'https://github.com/qcoro/qcoro' 'lib\cmake\QCoro6' @(
    '-DUSE_QT_VERSION=6', '-DQCORO_WITH_QTDBUS=OFF', '-DQCORO_WITH_QTWEBSOCKETS=OFF',
    '-DQCORO_BUILD_EXAMPLES=OFF', '-DBUILD_TESTING=OFF')

Step 'configuring'
$testing = if ($Tests) { 'ON' } else { 'OFF' }
Run cmake @('-S', $root, '-B', $build, '-G', 'Ninja', '-DCMAKE_BUILD_TYPE=Release', "-DBUILD_TESTING=$testing",
            "-DCMAKE_PREFIX_PATH=$QtDir;$deps")

Step 'building'
Run cmake @('--build', $build)

if ($Tests) {
    Step 'running the tests'
    # the tests find qt's and the dependencies' libraries on the path
    $env:PATH = "$(Join-Path $QtDir 'bin');$(Join-Path $deps 'bin');$env:PATH"
    Run ctest @('--test-dir', $build, '--output-on-failure')
}

Step "installing to $destination"
if (Get-Process swiftify -ErrorAction SilentlyContinue) { Fail 'Quit Swiftify first, then run this again.' }
Run cmake @('--install', $build, '--prefix', $destination)
$exe = Join-Path $destination 'bin\swiftify.exe'
# qt's own libraries, plugins and qml modules beside it
Run (Join-Path $QtDir 'bin\windeployqt.exe') @('--release', '--qmldir', (Join-Path $root 'qml'), $exe)
# and qtkeychain's and qcoro's, which windeployqt does not know about
Get-ChildItem (Join-Path $deps 'bin') -Filter '*.dll' -ErrorAction SilentlyContinue |
    Copy-Item -Destination (Join-Path $destination 'bin') -Force

# a start menu entry
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut(
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Swiftify.lnk'))
$shortcut.TargetPath = $exe
$shortcut.WorkingDirectory = Split-Path $exe
$shortcut.Save()

Write-Host "`ndone: $exe" -ForegroundColor Green
