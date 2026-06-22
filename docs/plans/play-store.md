# Play Store publishing checklist

Goal: internal-testing track first (mother as tester), production later.

## Code side (done)

- [x] **Release signing wiring** — `android/app/build.gradle.kts` loads
  `android/key.properties` (gitignored, machine-local) and signs release
  builds with the upload keystore; falls back to debug signing when absent.
- [x] **Package visibility for the support link** — `https` VIEW intent in
  the manifest `<queries>` so url_launcher resolves a browser on Android 11+.
- [x] **Privacy policy** text — `PRIVACY.md` (truthful: no data collected,
  everything on-device). Needs a public URL — see below.
- [x] applicationId `net.skjelten.brain_workout` (permanent once uploaded),
  adaptive launcher icons, localized app label, `version: 1.0.0+1`.

## One-time owner tasks

- [ ] **Create the upload keystore** (pick your own passwords; back the file
  up somewhere safe — losing it is recoverable with Play App Signing but
  annoying):
  ```powershell
  keytool -genkey -v -keystore $env:USERPROFILE\brain-workout-upload.jks `
    -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] **Create `android/key.properties`** (stays local, never committed):
  ```properties
  storePassword=<password>
  keyPassword=<password>
  keyAlias=upload
  storeFile=C:/Users/<you>/brain-workout-upload.jks
  ```
- [ ] **Build the bundle:** `flutter build appbundle --release`
  → `build/app/outputs/bundle/release/app-release.aab`
- [ ] **Publish the privacy policy at a public URL** — easiest: GitHub repo →
  Settings → Pages (serve from main branch) and link `PRIVACY.md`, or any
  public page. Paste the URL in Play Console → App content → Privacy policy.

## Play Console tasks (console.play.google.com)

- [ ] Create app: name **Hjernetrim** (or Brain Workout), default language
  Norwegian, free, app (not game category-wise it IS a game — choose Game →
  Puzzle or Casual).
- [ ] **Store listing:** short + full description (write both nb and en
  translations — ask Claude for drafts), screenshots (min 2 phone screenshots
  — take them on the emulator at your side), app icon 512×512 PNG, feature
  graphic 1024×500.
- [ ] **App content forms:**
  - Privacy policy URL (from above).
  - Ads: **no ads**.
  - App access: **all functionality available without restrictions** (no login).
  - Content rating questionnaire (IARC): no violence/etc. → rated for everyone.
  - Target audience: **13+ / adults** (do NOT tick under-13 — that opts into
    the much stricter Families policy; the app is aimed at elderly users).
  - Data safety: **no data collected, no data shared** (matches PRIVACY.md).
  - Government app / news app / COVID app: no.
- [ ] **Internal testing track:** upload the .aab, add tester email addresses
  (your own + your mother's Google account), share the opt-in link with her.
- [ ] After it works for her: promote the same build to **production**
  (expect a review wait, typically a few days for a first app).

## Per-release routine (later)

1. Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+2` — the `+N` versionCode
   must increase every upload).
2. `/test` green → `flutter build appbundle --release` → upload to the track.
