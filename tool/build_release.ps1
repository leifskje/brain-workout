# Builds the Play Store bundle, and refuses to hand you a debug-signed one.
#
# The signing config in android/app/build.gradle.kts falls back to *debug* keys
# when android/key.properties is missing. That is convenient for local release
# builds but dangerous here: the bundle looks fine, uploads, and Play rejects it
# with a message that does not obviously say "wrong key". So this checks first,
# and verifies the certificate afterwards.
#
# Run: pwsh -File tool/build_release.ps1

$ErrorActionPreference = 'Stop'
$bundle = 'build/app/outputs/bundle/release/app-release.aab'

if (-not (Test-Path 'android/key.properties')) {
    Write-Host 'android/key.properties is missing.' -ForegroundColor Red
    Write-Host ''
    Write-Host 'Without it the release build is signed with DEBUG keys and Play'
    Write-Host 'will reject it. Create the upload keystore first:'
    Write-Host ''
    Write-Host '  keytool -genkey -v -keystore $env:USERPROFILE\brain-workout-upload.jks \'
    Write-Host '    -keyalg RSA -keysize 2048 -validity 10000 -alias upload'
    Write-Host ''
    Write-Host 'then write android/key.properties (gitignored, never committed):'
    Write-Host ''
    Write-Host '  storePassword=<yours>'
    Write-Host '  keyPassword=<yours>'
    Write-Host '  keyAlias=upload'
    Write-Host '  storeFile=C:/Users/<you>/brain-workout-upload.jks'
    Write-Host ''
    Write-Host 'Back that .jks up somewhere safe.'
    exit 1
}

Write-Host '== Version ==' -ForegroundColor Cyan
$version = (Select-String -Path pubspec.yaml -Pattern '^version:').Line
Write-Host "   $version"
Write-Host '   the +N build number must increase on every upload, or Play refuses it'

Write-Host '== Gates ==' -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { Write-Host 'analyze failed' -ForegroundColor Red; exit 1 }
flutter test
if ($LASTEXITCODE -ne 0) { Write-Host 'tests failed' -ForegroundColor Red; exit 1 }

Write-Host '== Building the app bundle ==' -ForegroundColor Cyan
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { Write-Host 'build failed' -ForegroundColor Red; exit 1 }

if (-not (Test-Path $bundle)) {
    Write-Host "expected $bundle, but it is not there" -ForegroundColor Red
    exit 1
}

Write-Host '== Verifying the signature ==' -ForegroundColor Cyan
$cert = (& keytool -printcert -jarfile $bundle 2>&1) -join "`n"
if ($cert -match 'CN=Android Debug') {
    Write-Host 'This bundle is DEBUG-signed. Do not upload it.' -ForegroundColor Red
    Write-Host 'key.properties exists but was not picked up — check storeFile path.'
    exit 1
}
$owner = ($cert -split "`n" | Select-String -Pattern '^\s*Owner:').Line
Write-Host "   $($owner.Trim())"
Write-Host '   not debug-signed' -ForegroundColor Green

$mb = (Get-Item $bundle).Length / 1MB
Write-Host ''
Write-Host ("Ready: $bundle  ({0:N1} MB)" -f $mb) -ForegroundColor Green
Write-Host 'Upload at https://play.google.com/console -> Test and release ->'
Write-Host 'Testing -> Internal testing -> Create new release.'
