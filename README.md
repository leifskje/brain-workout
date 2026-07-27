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

### From VS Code (the play button)

`.vscode/launch.json` is checked in, so with any Dart file open press **F5** —
or pick a config in the **Run and Debug** panel:

| Config | Device | Notes |
|---|---|---|
| Brain Workout (Android) | `android` | **Default on F5.** Boots the emulator itself |
| Brain Workout (Windows desktop) | `windows` | No emulator, starts in seconds |
| Brain Workout (Chrome) | `chrome` | Works on any machine, incl. Windows ARM |
| Brain Workout (pick device) | — | Prompts for the device |
| Brain Workout (Android, profile mode) | `android` | Release-ish timings; no hot reload |

F5 needs no setup: the Android configs run
[`tool/boot_emulator.ps1`](tool/boot_emulator.ps1) as a `preLaunchTask`, which
starts `pixel_api35` and waits for `sys.boot_completed`. If the emulator is
already up, or a phone is attached over USB, it exits in well under a second.

`.vscode/tasks.json` adds tasks (**Ctrl+Shift+P → Tasks: Run Task**): *Boot
Android emulator* — also the default build task, **Ctrl+Shift+B**, for booting
the emulator ahead of time — plus *Analyze*, *Test*, and *Regenerate
localizations*.

Breakpoints work in the editor gutter, and
**Ctrl+Shift+P → Flutter: Open DevTools** opens the widget inspector.

#### Getting new code onto the running device

| | How | Keeps app state? | Use for |
|---|---|---|---|
| **Hot reload** | **Ctrl+S** (or ⚡ in the debug toolbar / Ctrl+F5) | Yes — you stay on the same screen | Almost everything: widgets, painters, layout, logic |
| **Hot restart** | ⟳ in the debug toolbar (Ctrl+Shift+F5) | No — restarts at the home screen | `main()`, `initState`, globals, enum/type changes |
| **Full rebuild** | Stop (■) then F5 | No | `pubspec.yaml`, new assets, `.arb` files, anything under `android/` |

Hot reload only fires on a *manual* save (`dart.flutterHotReloadOnSave` defaults
to `manual`). If you ever turn on `files.autoSave`, set that to `all` too.

### From the terminal

```powershell
flutter emulators --launch pixel_api35   # or any AVD / a phone over USB
flutter run                              # Android
flutter run -d windows                   # quick desktop check
flutter run -d chrome                    # web, zero extra dependencies
flutter build apk --debug                # debug APK
```

While `flutter run` is active, press `r` to hot-reload and `R` to hot-restart.

## Notes for Windows on ARM (e.g. Surface Pro)

Tested on an ARM Surface — expect these differences:

- **The Android emulator is not available on Windows ARM hosts.** The AVD
  flow ends with a "no emulator" message; this is a platform gap, not a
  setup mistake. Don't burn time on it.
- Test on a **physical Android phone instead**: enable Developer options +
  USB debugging on the phone, plug it in (or use wireless debugging /
  `adb pair`), and `flutter run` picks it up. For quick UI checks with no
  device at hand, `flutter run -d chrome` works everywhere.
- Flutter's setup flow will likely install **Android Studio** — that's fine;
  it's just the SDK provider. You don't have to use the IDE: install the
  Flutter extension in VS Code and point it at the SDK
  (`%LOCALAPPDATA%\Android\Sdk`) and you have the same editor setup as the
  dev machine.
- Flutter stable and Microsoft OpenJDK 17 both run natively on Windows
  arm64. `flutter run -d windows` additionally needs the Visual Studio C++
  ARM64 components.

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
