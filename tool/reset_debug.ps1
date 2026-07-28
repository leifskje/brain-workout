# Clears out a stuck Flutter debug session so the next F5 starts clean.
#
# Why this is needed: stopping a hung debug session in VS Code does not always
# kill the `flutter run` process tree. The orphan keeps holding the VM service
# port and the device, so the *next* launch either hangs or never loads. Two
# sessions were once found alive six hours apart, fighting over one emulator.
#
# Leaves alone, deliberately:
#   - the Dart language server and tooling daemon, which VS Code owns; killing
#     them costs you IntelliSense and a reindex for no benefit. Note their exe
#     lives under C:\dev\flutter\..., so matching on "flutter" would hit them.
#   - the emulator, which is usually healthy and takes ~17s to boot. Use
#     -Emulator to shut it down too.
#
# Run:  pwsh -File tool/reset_debug.ps1 [-Deep] [-Emulator]
#   -Deep      also runs `flutter clean` (use when a build looks corrupted)
#   -Emulator  also shuts the AVD down

param(
    [switch]$Deep,
    [switch]$Emulator
)

$ErrorActionPreference = 'Continue'
$package = 'net.skjelten.brain_workout'

Write-Host '== Stopping the app on any attached device =='
$devices = (adb devices) -match '^\S+\s+device$'
if ($devices) {
    foreach ($line in $devices) {
        $serial = ($line -split '\s+')[0]
        adb -s $serial shell am force-stop $package 2>$null
        Write-Host "   force-stopped $package on $serial"
    }
} else {
    Write-Host '   no device attached'
}

Write-Host '== Killing orphaned flutter run / devtools processes =='
# Include only genuine run-session processes; exclude the editor's own servers.
$keep = 'language-server|tooling-daemon'
$hunt = 'flutter_tools|flutter\.snapshot|frontend_server|devtools'

$dartProcs = "Name='dart.exe' OR Name='dartvm.exe' OR Name='dartaotruntime.exe'"
$targets = Get-CimInstance Win32_Process -Filter $dartProcs |
    Where-Object { $_.CommandLine -and
                   $_.CommandLine -notmatch $keep -and
                   $_.CommandLine -match $hunt }

if ($targets) {
    foreach ($p in $targets) {
        try {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop
            Write-Host "   killed $($p.Name) ($($p.ProcessId))"
        } catch {
            Write-Host "   could not kill $($p.ProcessId): $($_.Exception.Message)"
        }
    }
} else {
    Write-Host '   none found'
}

Write-Host '== Stopping the Gradle daemon =='
# Holds file locks on android/build, which makes a rebuild fail confusingly.
if (Test-Path 'android/gradlew.bat') {
    Push-Location android
    try { & ./gradlew.bat --stop 2>$null | Out-Null } catch {}
    Pop-Location
    Write-Host '   gradle daemon asked to stop'
} else {
    Write-Host '   no gradlew found, skipping'
}

if ($Deep) {
    Write-Host '== flutter clean =='
    flutter clean | Out-Null
    Write-Host '   build artifacts removed (next run will be slow)'
}

if ($Emulator) {
    Write-Host '== Shutting the emulator down =='
    foreach ($line in ((adb devices) -match '^emulator-\d+\s+device$')) {
        $serial = ($line -split '\s+')[0]
        adb -s $serial emu kill 2>$null
        Write-Host "   killed $serial"
    }
    # `emu kill` stops the qemu VM but often leaves the launcher process behind,
    # and a leftover launcher stops the next boot from attaching. Sweep them.
    Start-Sleep -Seconds 3
    foreach ($p in (Get-Process -Name emulator -ErrorAction SilentlyContinue)) {
        try {
            Stop-Process -Id $p.Id -Force -ErrorAction Stop
            Write-Host "   killed orphaned launcher $($p.Id)"
        } catch {
            Write-Host "   could not kill launcher $($p.Id)"
        }
    }
}

Write-Host ''
Write-Host 'Survivors (should be the editor servers, and the emulator):'
Get-CimInstance Win32_Process -Filter $dartProcs |
    ForEach-Object {
        $role = if ($_.CommandLine -match 'language-server') { 'language server' }
                elseif ($_.CommandLine -match 'tooling-daemon') { 'tooling daemon' }
                else { 'OTHER - check this' }
        Write-Host "   $($_.ProcessId)  $($_.Name)  $role"
    }
Write-Host ''
Write-Host 'Done. Press F5 for a clean session.'
