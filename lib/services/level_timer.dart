import 'package:flutter/widgets.dart';

/// A stopwatch for one level, counting only the time the player was actually
/// looking at the board.
///
/// **Foreground-active time, never wall clock.** This audience puts the phone
/// down mid-level — a call, the doorbell, tea. Wall-clock timing would record
/// hours and poison the personal best for good, and a "best" that can be ruined
/// by answering the phone is worse than no best at all. So the clock stops on
/// `paused`/`hidden` and resumes on `resumed`.
///
/// **Nothing here is time pressure.** The value is recorded silently and shown
/// on the win dialog and the stats screen; whether it appears *during* play is a
/// setting, off by default. Nothing counts down, and being slow can never cost
/// the player anything. See the top of CLAUDE.md.
///
/// Not a `Ticker`: the value is read at a win and, if the setting is on, once a
/// second by the screen. Driving a 60Hz animation to move a seconds display
/// would be waste.
class LevelTimer {
  Duration _banked = Duration.zero;
  DateTime? _runningSince;

  /// Total active time so far.
  Duration get elapsed {
    final since = _runningSince;
    if (since == null) return _banked;
    return _banked + DateTime.now().difference(since);
  }

  bool get isRunning => _runningSince != null;

  /// Starts a fresh level. [from] restores time carried by a resumed board —
  /// without it a resumed level reports only the time since it was reopened,
  /// which is not a number that means anything.
  void start({Duration from = Duration.zero}) {
    _banked = from;
    _runningSince = DateTime.now();
  }

  /// Banks the time so far and stops counting. Idempotent.
  void pause() {
    final since = _runningSince;
    if (since == null) return;
    _banked += DateTime.now().difference(since);
    _runningSince = null;
  }

  void resume() {
    _runningSince ??= DateTime.now();
  }

  void stop() => pause();

  /// Follows the app lifecycle. Call from the game's
  /// `didChangeAppLifecycleState`, which the autosave mixin already requires the
  /// screen to implement.
  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        pause();
      case AppLifecycleState.resumed:
        resume();
      case AppLifecycleState.inactive:
        // Deliberately ignored. `inactive` fires for transient things like the
        // notification shade being pulled down, and on iOS during a normal
        // rotation; pausing on it would make the clock stutter for no reason.
        break;
    }
  }
}

/// Formats a level time for display: "1:58", or "12:04", or "1:02:33".
///
/// Minutes and seconds rather than a decimal — this is read aloud by people who
/// do not think in 118 seconds.
String formatLevelTime(Duration d) {
  final total = d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final mm = h > 0 ? m.toString().padLeft(2, '0') : m.toString();
  return h > 0
      ? '$h:$mm:${s.toString().padLeft(2, '0')}'
      : '$mm:${s.toString().padLeft(2, '0')}';
}
