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

| Config | Notes |
|---|---|
| Brain Workout (Android) | The one you want. Boots `pixel_api35` itself |
| Brain Workout (Android, profile mode) | Release-ish timings; no hot reload |
| Brain Workout (pick device) | Prompts — use for a phone over USB, or a web check |

F5 needs no setup. The Android configs pin the emulator with **`emulatorId`**,
which starts it if it isn't running and, per the Dart extension's docs,
"overrides anything in `deviceId` or selected in the status bar" — so the device
shown in the status bar can't hijack the launch. They also run
[`tool/boot_emulator.ps1`](tool/boot_emulator.ps1) as a `preLaunchTask`, because
the extension only waits for the emulator to *connect* while the script waits for
`sys.boot_completed`; it no-ops in ~0.5s when a device is already attached.

#### When the debugger hangs

Stopping a hung session with ■ does **not** reliably kill the `flutter run`
process tree. The orphan keeps holding the VM service port and the device, so the
next F5 hangs or never loads — and orphans accumulate. Two full sessions were once
found alive six hours apart, fighting over one emulator.

**Ctrl+Shift+P → Tasks: Run Task → Reset debug session**, or
`pwsh -File tool/reset_debug.ps1`. It force-stops the app, kills the orphaned
run/devtools processes, and stops the Gradle daemon. It deliberately leaves the
emulator running (healthy, and ~17s to boot) and leaves VS Code's Dart language
server and tooling daemon alone — killing those just costs you IntelliSense and a
reindex. Note their executable lives under `C:\dev\flutter\...`, so anything
matching on "flutter" would kill them by mistake.

Flags: `-Deep` also runs `flutter clean` (for a corrupted build), `-Emulator`
also shuts the AVD down.

#### Blank screen on the emulator (Impeller)

The app starts, the debugger attaches, logcat says `Fully drawn` with **no Dart
error** — and the screen stays empty. That is Impeller, which is now the default
renderer on Android and paints nothing on this x86_64 AVD. The tells in logcat:

```
I flutter : Using the Impeller rendering backend (OpenGLES)
D FlutterRenderer: Width is zero. 0,0
W HWUI    : Failed to initialize 101010-2 format
```

The Android debug configs therefore pass `--no-enable-impeller`, falling back to
Skia. Note the flag is hidden from `flutter run --help` — it only appears under
`flutter run --help --verbose`, so it looks unsupported when it isn't.

This is a *debug-run* workaround only, and emulator-specific; real devices render
Impeller fine. To turn it off app-wide instead (release builds included), add to
`android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data android:name="io.flutter.embedding.android.EnableImpeller"
           android:value="false" />
```

Two traps worth knowing, both of which cost an evening:

- **VS Code remembers the last-used configuration per workspace**, so F5 does not
  necessarily run the first one in the file. If F5 launches the wrong thing, pick
  the config you want once in the dropdown and it sticks.
- **`"deviceId": "android"` looks right and never works.** `deviceId` is matched
  against device *ids and names*, and a booted AVD is `emulator-5554` /
  `sdk gphone64 x86 64` — neither contains "android". Use `emulatorId` for an AVD,
  or a real id like `emulator-5554`.

There is deliberately no desktop config. This is an Android app; use
`flutter run -d windows` from the terminal for the rare desktop check.

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
