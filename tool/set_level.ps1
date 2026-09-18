# Jumps the unlocked level for one game, or all of them, on an attached device.
#
# Why this exists: the level picker only shows levels up to `highest_level_<game>`,
# so testing a late-game change means playing there — which is not a test, it is an
# afternoon. The emulator's progress is separate from the phone's anyway, so it
# starts near zero exactly when a late board is what needs looking at.
#
# Only ever touches `highest_level_*`. Stars, saved boards, times and settings are
# left alone, and `ProgressStore.recordReached` only ever raises the value, so
# nothing here can lose progress.
#
# Debug builds only: `run-as` needs a debuggable package, which is what
# `flutter run` / F5 installs.
#
# Run:  pwsh -File tool/set_level.ps1 -Level 100 [-Game arrow_escape] [-Serial emulator-5554]
#       pwsh -File tool/set_level.ps1 -Show

param(
    [int]$Level = 100,
    [string]$Game = 'all',
    [string]$Serial,
    [switch]$Show
)

$ErrorActionPreference = 'Stop'
$package = 'net.skjelten.brain_workout'
$prefs = 'shared_prefs/FlutterSharedPreferences.xml'

$games = @(
    'arrow_escape', 'arrow_maze', 'wordle', 'number_cross', 'word_search',
    'mini_sudoku', 'merge', 'memory_match', 'word_scramble', 'crack_code',
    'trail', 'simon', 'nonogram', 'what_next'
)

if ($Game -ne 'all' -and $games -notcontains $Game) {
    throw "Unknown game '$Game'. One of: all, $($games -join ', ')"
}

$adb = if ($Serial) { @('-s', $Serial) } else { @() }

$attached = (& adb @adb devices) -match '^\S+\s+device$'
if (-not $attached) { throw 'No device attached. Start the emulator first.' }

# The app holds prefs in memory and rewrites the file on exit, so a live process
# would simply undo this.
& adb @adb shell am force-stop $package | Out-Null

$local = Join-Path ([System.IO.Path]::GetTempPath()) 'FlutterSharedPreferences.xml'
& adb @adb shell "run-as $package cat $prefs" > $local
if (-not (Test-Path $local) -or (Get-Item $local).Length -eq 0) {
    throw "Could not read prefs. Is a debug build installed? (run-as needs one)"
}

[xml]$xml = Get-Content $local -Raw

if ($Show) {
    Write-Host 'Unlocked levels:'
    foreach ($g in $games) {
        $node = $xml.map.long | Where-Object { $_.name -eq "flutter.highest_level_$g" }
        $value = if ($node) { $node.value } else { '-' }
        Write-Host ("   {0,-16} {1}" -f $g, $value)
    }
    return
}

$targets = if ($Game -eq 'all') { $games } else { @($Game) }
foreach ($g in $targets) {
    $key = "flutter.highest_level_$g"
    $node = $xml.map.long | Where-Object { $_.name -eq $key }
    if ($node) {
        $was = $node.value
        $node.value = "$Level"
    } else {
        $node = $xml.CreateElement('long')
        $node.SetAttribute('name', $key)
        $node.SetAttribute('value', "$Level")
        [void]$xml.map.AppendChild($node)
        $was = '-'
    }
    Write-Host ("   {0,-16} {1} -> {2}" -f $g, $was, $Level)
}

$xml.Save($local)

# Pushed via /data/local/tmp rather than piped into `run-as sh -c 'cat >'`:
# adb's shell mangles line endings on stdin, which silently corrupts the XML and
# costs the app every stored preference, not just the levels.
$staged = "/data/local/tmp/bw_prefs.xml"
& adb @adb push $local $staged | Out-Null
& adb @adb shell "run-as $package cp $staged $prefs"
& adb @adb shell "rm -f $staged"

Write-Host ''
Write-Host "Done. Start the app (F5) — the level picker will show them."
