# Brain Workout (Hjernetrim)

A Flutter app of small brain-training mini-games aimed at elderly users.
Eight games (word, number, memory, and logic puzzles), levels with stars, a
daily-workout streak, and full English + Norwegian (Bokmål) localization —
the UI follows the phone language, with an in-app override.

Primary target is Android; Windows desktop and web also build.

## Prerequisites

| Tool | Notes |
|---|---|
| Flutter SDK (stable) | https://docs.flutter.dev/get-started/install — repo developed on 3.44.x |
| JDK 17 | Only for Android builds. [Microsoft OpenJDK 17](https://learn.microsoft.com/java/openjdk/download) works well; set `JAVA_HOME` |
| Android SDK | Either via Android Studio, or command-line tools only (this repo was set up without Android Studio: `cmdline-tools`, `platform-tools`, `platforms;android-35`, `build-tools`, `emulator`) |
| VS Code + Flutter extension | Or any editor you like |
| Visual Studio C++ workload | Only if you want `flutter run -d windows` |

## Setup on a fresh machine

```powershell
git clone https://github.com/leifskje/brain-workout.git
cd brain-workout

# Per-clone git config (not cloned automatically):
git config core.hooksPath .githooks   # pre-commit runs `flutter analyze`

flutter pub get        # also regenerates lib/l10n/generated via gen-l10n
flutter doctor         # fix anything red; `flutter doctor --android-licenses`
flutter test           # should be all green
```

`JAVA_HOME` must point at the JDK 17 install for Android builds (set it as a
user environment variable, or in `.claude/settings.local.json` if you use
Claude Code — that file is gitignored and machine-local).

## Run

```powershell
flutter emulators --launch pixel_api35   # or any AVD / a phone over USB
flutter run                              # Android
flutter run -d windows                   # quick desktop check
flutter run -d chrome                    # web, zero extra dependencies
flutter build apk --debug                # debug APK
```

While `flutter run` is active, press `r` to hot-reload and `R` to hot-restart.

## Notes for Windows on ARM (e.g. Surface Pro)

- Flutter's stable channel supports Windows arm64 hosts; Microsoft OpenJDK 17
  has native ARM64 builds.
- The Android emulator needs **arm64-v8a system images** on an ARM host —
  x86_64 images (like the `pixel_api35` AVD used on the dev machine) won't
  run. Create an AVD with e.g. `system-images;android-35;google_apis;arm64-v8a`.
- If the emulator is troublesome, the easy paths are a physical phone over
  USB (`flutter run` picks it up) or `flutter run -d chrome`.
- `flutter run -d windows` on ARM needs the Visual Studio C++ ARM64
  components.

## Development

- **[CLAUDE.md](CLAUDE.md)** — project guide: structure, conventions
  (guaranteed-solvable generators, AnimationController/`mounted` rules,
  elderly-friendly UX), commands, and the AI-agent workflow.
- **[docs/plans/](docs/plans/)** — roadmap + a design doc per game.
- All UI strings live in `lib/l10n/app_en.arb` + `app_nb.arb`; run
  `flutter gen-l10n` after editing.
- `tool/` has board text-dump and game-preview entrypoints for inspection.
- Tests: `flutter test` (or the `/test` command in Claude Code). The
  pre-commit hook runs `flutter analyze`.
