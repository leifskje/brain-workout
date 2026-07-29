# Play Store publishing checklist

Goal: internal-testing track first (mother as tester), production later.

## Read this before planning around production

The developer account is a **personal** account created after 13 Nov 2023, which
means production is gated: you must first run a **closed** test with **12 testers
opted in for 14 consecutive days**. Internal testing does **not** count toward it,
and the 14 days only start once 12 distinct Google accounts have opted in on real
devices — emulators and duplicate accounts do not count.
([Play Console Help](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en))

So, with two or three testers:

- **Internal testing** — up to 100 testers, no requirements, works immediately.
  This is the right track, and it replaces emailing APKs: testers get updates
  through the Play Store automatically.
- **Production** — blocked until you find 12 testers. Worth knowing now rather
  than discovering it later.

## Helper scripts

- `python tool/build_store_graphics.py` — regenerates `store/icon_512.png` and
  `store/feature_1024x500.png` from the launcher icon. Play needs the store icon
  at *exactly* 512×512 with no transparency, so the 1024×1024 source cannot be
  uploaded as-is.
- `dart run tool/check_store_listing.dart` — checks the copy in
  [store-listing.md](store-listing.md) against Play's field limits (name 30,
  short 80, full 4000).
- `pwsh -File tool/build_release.ps1` — gates, builds the bundle, and **verifies
  it is not debug-signed**. The signing config silently falls back to debug keys
  when `android/key.properties` is absent, which produces a bundle that looks
  fine and gets rejected, so the script refuses to build without it.
- `python tool/prepare_screenshots.py store/raw store/screenshots` — makes raw
  emulator captures Play-valid. **This matters:** Play rejects a screenshot whose
  long side exceeds twice the short side, and the pixel_api35 emulator is
  1080×2400 (ratio 2.22), so raw captures fail. The script *pads* to 1350×2400
  (9:16) rather than cropping, because cropping would cut 480px off the board.
  Padding colour is sampled from the image so it blends in.

## Privacy policy URL (GitHub Pages)

`docs/index.md` and `docs/privacy.md` exist for this. After pushing, enable Pages
once: repo **Settings → Pages → Deploy from a branch → `main` → `/docs` → Save**.
The policy then lives at
`https://leifskje.github.io/brain-workout/privacy` — paste that into Play Console
→ App content → Privacy policy.

Note both files carry YAML front matter. Jekyll only converts Markdown to HTML
when a file has it; without front matter the page is served as raw text.

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
