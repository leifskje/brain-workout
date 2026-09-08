import 'dart:isolate';

import '../games/snake_arrows/snake_arrows_models.dart';

/// Builds the *next* Arrow Maze board while the player is still looking at the
/// win dialog, so a slow generation never shows up as a wait.
///
/// This is worth more than any constant-factor work on the generator itself. Board
/// cost grows with area, and the ~400ms budget that pinned the board cap was only a
/// budget because generation sat on the critical path between tapping "Next level"
/// and seeing a board. Off that path, a second of work is invisible: the win dialog
/// alone takes ~1.1s to play out before the player can even choose.
///
/// Two properties make this safe rather than a cache-coherence problem:
///
///  - **Generation is deterministic in the level number.** A prefetched board is
///    *identical* to one generated on the spot, so using it can never change what
///    the player sees — only when they see it.
///  - **Every path degrades to generating on the spot.** A miss, a mismatched level,
///    an isolate failure or an unusable payload all fall through to
///    `SnakeBoard.generate`. Nothing here can prevent a level from opening.
class BoardPrefetch {
  BoardPrefetch._();

  static int? _level;
  static SnakeBoard? _board;
  static Future<void>? _inFlight;

  /// The level the in-flight build is for. Needed because [obtain] has to tell
  /// "a board for the level I want is nearly ready" from "a board for some other
  /// level is being built", and those want opposite behaviour.
  static int? _inFlightLevel;

  /// Starts building the board for [level] in a background isolate.
  ///
  /// Fire and forget: callers do not await it. Runs off the UI isolate because
  /// generation is synchronous CPU work — doing it inline would freeze the very
  /// celebration it is meant to hide behind.
  static void warm(int level) {
    if (_level == level && _board != null) return; // already have it
    if (_inFlightLevel == level) return; // already building this one
    if (_inFlight != null) return; // busy with another level; obtain() copes
    _level = null;
    _board = null;
    _inFlightLevel = level;
    _inFlight = _run(level).whenComplete(() {
      _inFlight = null;
      _inFlightLevel = null;
    });
  }

  static Future<void> _run(int level) async {
    try {
      // Only the level number crosses into the isolate, and only plain lists come
      // back — an object graph is not reliably sendable.
      final json = await Isolate.run(() => SnakeBoard.generate(level).toJson());
      final board = SnakeBoard.fromJson(json);
      if (board == null) return;
      _level = level;
      _board = board;
    } on Object {
      // An isolate that cannot spawn (or any other failure) must not break the
      // game; the caller falls back to generating on the spot.
      _level = null;
      _board = null;
    }
  }

  /// The board for [level], with the caller's spinner given a chance to paint
  /// first.
  ///
  /// This is what callers should use. [take] alone was the bug: it returns null
  /// whenever the prefetch has not finished, and the caller then generated
  /// synchronously with nothing on screen to explain the pause — 144-271ms at
  /// the upper levels. A player who taps "Next level" before the ~1.1s dialog
  /// has played out reads that as a hang, taps again, and the second tap lands
  /// on the board that has meanwhile appeared and fires whatever arrow is under
  /// their finger. Reported from a live build.
  ///
  /// Order of preference: the prefetched board; then an in-flight warm for this
  /// same level, awaited rather than duplicated; then generate here.
  ///
  /// **That last step is deliberately not moved into an isolate.** It is the
  /// obvious thing to reach for and it makes this path untestable: `Isolate.run`
  /// never completes inside `testWidgets`' fake-async zone, so every widget test
  /// that missed the cache would hang rather than fail (see CLAUDE.md). The
  /// `await` before it yields one turn of the event loop, which is enough for the
  /// spinner to paint — so the work still blocks, but the player is looking at
  /// "setting up the next board" while it does, which is the thing that was
  /// actually wrong.
  static Future<SnakeBoard> obtain(int level) async {
    final ready = take(level);
    if (ready != null) return ready;

    if (_inFlightLevel == level) {
      final pending = _inFlight;
      if (pending != null) {
        await pending;
        final warmed = take(level);
        if (warmed != null) return warmed;
      }
    }

    await Future<void>.delayed(Duration.zero);
    return SnakeBoard.generate(level);
  }

  /// The prefetched board for [level] if one is ready, else null.
  ///
  /// Consumed on read: a board is handed out once, because the screen mutates it as
  /// the player clears arrows and a second caller must not receive that state.
  static SnakeBoard? take(int level) {
    if (_level != level) return null;
    final board = _board;
    _level = null;
    _board = null;
    return board;
  }

  /// The in-flight build, if any — a test seam so a test can await the isolate
  /// instead of guessing at a delay.
  static Future<void>? get pending => _inFlight;

  /// Test seam: drop anything held.
  static void reset() {
    _level = null;
    _board = null;
    _inFlightLevel = null;
  }

  /// Test seam: whether a board for [level] is ready to be taken.
  static bool has(int level) => _level == level && _board != null;

  /// Test seam: put a board in directly, without an isolate.
  static void seed(int level, SnakeBoard board) {
    _level = level;
    _board = board;
  }
}
