# Boots the Android AVD if no emulator is already attached, then waits until
# Android has finished booting so `flutter run -d android` can find it.
#
# Wired up as the preLaunchTask for the "Brain Workout (Android)" debug configs
# in .vscode/launch.json, and as the default build task (Ctrl+Shift+B) in
# .vscode/tasks.json. Safe to run when the emulator is already up — it exits
# immediately in that case.

param(
    [string]$Avd = 'pixel_api35',
    [int]$TimeoutSeconds = 240,
    # Cold boot, skipping the quick-boot snapshot. `flutter emulators --launch`
    # resumes from that snapshot, so a corrupted graphics state survives being
    # killed and relaunched — the app then renders a blank screen with no Dart
    # error, under either renderer, and logcat says "Width is zero". Reach for
    # this when restarting the emulator normally has changed nothing.
    [switch]$Cold
)

$ErrorActionPreference = 'Stop'

function Test-EmulatorOnline {
    # `adb devices` lists a booted AVD as "emulator-5554<TAB>device". A device
    # still starting shows up as "offline" and must not count as ready.
    return [bool](adb devices | Select-String -Pattern '^emulator-\d+\s+device\s*$' -Quiet)
}

if (Test-EmulatorOnline) {
    Write-Host 'Android emulator already running.'
    exit 0
}

if ($Cold) {
    # Straight to the SDK emulator binary: the flutter wrapper gives no way to
    # skip the snapshot.
    $exe = Join-Path $env:LOCALAPPDATA 'Android\Sdk\emulator\emulator.exe'
    if (-not (Test-Path $exe)) {
        Write-Warning "emulator.exe not found at $exe"
        exit 1
    }
    Write-Host "Cold-booting $Avd (ignoring the quick-boot snapshot) ..."
    Start-Process -FilePath $exe `
        -ArgumentList '-avd', $Avd, '-no-snapshot-load' -WindowStyle Normal
} else {
    Write-Host "Booting $Avd ..."
    Start-Process -FilePath (Get-Command flutter).Source `
        -ArgumentList 'emulators', '--launch', $Avd -WindowStyle Hidden
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 3
    if (-not (Test-EmulatorOnline)) { continue }

    # Device is attached; the launcher can still be minutes from ready.
    while ((Get-Date) -lt $deadline) {
        $booted = (adb shell getprop sys.boot_completed 2>$null | Out-String).Trim()
        if ($booted -eq '1') {
            Write-Host 'Android emulator ready.'
            exit 0
        }
        Start-Sleep -Seconds 2
    }
}

Write-Warning "$Avd did not become ready within $TimeoutSeconds s. Start it manually (flutter emulators --launch $Avd) or debug on Windows desktop instead."
exit 1
