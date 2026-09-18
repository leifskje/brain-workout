import 'dart:isolate';

import '../games/snake_arrows/snake_arrows_models.dart';
import 'progress_store.dart';

/// Builds Arrow Maze boards ahead of time, so a slow generation never shows up
/// as a wait.
///
/// This is worth more than any constant-factor work on the generator itself. Board
/// cost grows with area, and the ~400ms budget that pinned the board cap was only a
/// budget because generation sat on the critical path between tapping "Next level"
/// and seeing a board.
///
/// **Warming happens while the level is being played, not while the win dialog is
/// up.** The dialog buys ~1.1s, which was enough when generation was ~400ms and is
/// not enough now: measured across levels 40–70 on desktop JIT, generation is a
/// median of 359ms but a p90 of 1290ms and a max of 1947ms, and a phone is 2–3x
/// slower again. So the budget was blown on a large minority of high levels — and
/// because the cost is deterministic per level but wildly uneven between levels, the
/// player experienced it as "sometimes it hangs". Warming from the level load
/// instead turns a 1.1s budget into however long the player spends on the level,
/// which is minutes.
///
/// Boards are also kept on disk ([ProgressStore.savePrefetchedBoard]), because an
/// in-memory cache only ever helps *sequential* play: first entry into the game, a
/// jump from the level picker, and resuming after the app was killed all started
/// with nothing warmed.
///
/// Three properties make this safe rather than a cache-coherence problem:
///
///  - **Generation is deterministic in the level number.** A prefetched board is
///    *identical* to one generated on the spot, so using it can never change what
///    the player sees — only when they see it.
///  - **Every path degrades to generating on the spot.** A miss, a mismatched level,
///    an isolate failure or an unusable payload all fall through to
///    `SnakeBoard.generate`. Nothing here can prevent a level from opening.
///  - **A stored board carries the generator version that built it**
///    ([SnakeBoard.generatorVersion]), so changing the generator drops the cache
///    rather than serving boards the current build would never produce.
class BoardPrefetch {
  BoardPrefetch._();

  /// The only game cached here: Arrow Maze is the one whose generation is slow
  /// enough to be felt.
  static const _gameId = 'arrow_maze';

  static int? _level;
  static SnakeBoard? _board;
  static Future<void>? _inFlight;

  /// The level the in-flight build is for. Needed because [obtain] has to tell
  /// "a board for the level I want is nearly ready" from "a board for some other
  /// level is being built", and those want opposite behaviour.
  static int? _inFlightLevel;

  /// A warm asked for while another build was in flight, run when that finishes.
  ///
  /// Only the most recent such request is kept: they are all "the board the player
  /// is most likely to want next", and the newest is the best guess. Dropping the
  /// request instead — which is what this used to do — could skip warming a level
  /// *entirely*, which is the one outcome the whole class exists to prevent.
  static int? _queued;

  /// Starts building the board for [level] in a background isolate.
  ///
  /// Fire and forget: callers do not await it. Runs off the UI isolate because
  /// generation is synchronous CPU work — doing it inline would freeze whatever
  /// the player is looking at.
  static void warm(int level) {
    if (has(level)) return; // already in memory
    if (_inFlightLevel == level) return; // already building this one
    if (_hasPersisted(level)) return; // survived a restart; nothing to build
    if (_inFlight != null) {
      _queued = level;
      return;
    }
    _start(level);
  }

  /// Files [board] as the stored board for [level].
  ///
  /// For the level *being played*: the prefetch naturally stores level N+1, so
  /// without this, being killed mid-level and coming back regenerates the very
  /// board that was already on screen.
  static void remember(int level, SnakeBoard board) {
    final store = ProgressStore.instanceOrNull;
    if (store == null) return;
    if (store.hasPrefetchedBoard(_gameId, level, SnakeBoard.generatorVersion)) {
      return;
    }
    store.savePrefetchedBoard(
        _gameId, level, SnakeBoard.generatorVersion, board.toJson());
  }

  static void _start(int level) {
    late final Future<void> mine;
    mine = _run(level).whenComplete(() {
      // A [reset] (or a newer build) while this one was running makes us stale:
      // clearing the fields then would wipe somebody else's in-flight build.
      if (!identical(_inFlight, mine)) return;
      _inFlight = null;
      _inFlightLevel = null;
      final next = _queued;
      _queued = null;
      if (next != null) warm(next);
    });
    _inFlight = mine;
    _inFlightLevel = level;
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
      ProgressStore.instanceOrNull?.savePrefetchedBoard(
          _gameId, level, SnakeBoard.generatorVersion, json);
    } on Object {
      // An isolate that cannot spawn (or any other failure) must not break the
      // game; the caller falls back to generating on the spot. Nothing is
      // cleared here: a board held for *another* level is still good.
    }
  }

  /// Whether a stored board for [level] exists, without rebuilding it.
  static bool _hasPersisted(int level) =>
      ProgressStore.instanceOrNull?.hasPrefetchedBoard(
          _gameId, level, SnakeBoard.generatorVersion) ??
      false;

  /// The stored board for [level] rebuilt, or null if there isn't a usable one.
  static SnakeBoard? _persisted(int level) {
    final json = ProgressStore.instanceOrNull
        ?.loadPrefetchedBoard(_gameId, level, SnakeBoard.generatorVersion);
    if (json == null) return null;
    return SnakeBoard.fromJson(json);
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
  /// Order of preference: the prefetched board; then one stored on disk by an
  /// earlier session (rebuilding it is a JSON decode, not a generation); then an
  /// in-flight warm for this same level, awaited rather than duplicated; then
  /// generate here.
  ///
  /// **That last step is deliberately not moved into an isolate.** It is the
  /// obvious thing to reach for and it makes this path untestable: `Isolate.run`
  /// never completes inside `testWidgets`' fake-async zone, so every widget test
  /// that missed the cache would hang rather than fail (see CLAUDE.md). The
  /// `await` before it yields one turn of the event loop, which is enough for the
  /// spinner to paint — so the work still blocks, but the player is looking at
  /// "setting up the next board" while it does, which is the thing that was
  /// actually wrong.
  /// Returns the board and whether it came from a *finished* prefetch.
  ///
  /// `wasWarm` matters to the caller, not just as trivia: on a warm hit the
  /// board appears in the same frame, so there was no pause and therefore no
  /// queued tap to defend against. Guarding taps anyway just makes the first
  /// 400ms of every level dead, which is a new annoyance in place of the old one.
  static Future<({SnakeBoard board, bool wasWarm})> obtain(int level) async {
    final ready = take(level);
    if (ready != null) return (board: ready, wasWarm: true);

    // Stored by an earlier session. Read before waiting on an in-flight build for
    // the same level: decoding a board is a millisecond, waiting for one can be
    // seconds, and they are the same board either way.
    final stored = _persisted(level);
    if (stored != null) return (board: stored, wasWarm: true);

    if (_inFlightLevel == level) {
      final pending = _inFlight;
      if (pending != null) {
        await pending;
        final warmed = take(level);
        // Not "warm": the player waited for it, so a tap may be queued.
        if (warmed != null) return (board: warmed, wasWarm: false);
      }
    }

    await Future<void>.delayed(Duration.zero);
    return (board: SnakeBoard.generate(level), wasWarm: false);
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

  /// The level currently being built in the background, if any — a test seam so
  /// a widget test can assert that warming *started*, which is all that is
  /// observable inside a fake-async zone (the isolate itself cannot finish there).
  static int? get warmingLevel => _inFlightLevel;

  /// Test seam: drop anything held, in memory and on disk.
  static void reset() {
    _level = null;
    _board = null;
    _inFlight = null;
    _inFlightLevel = null;
    _queued = null;
    ProgressStore.instanceOrNull?.clearPrefetchedBoards(_gameId);
  }

  /// Test seam: whether a board for [level] is ready to be taken.
  static bool has(int level) => _level == level && _board != null;

  /// Test seam: put a board in directly, without an isolate.
  static void seed(int level, SnakeBoard board) {
    _level = level;
    _board = board;
  }
}
