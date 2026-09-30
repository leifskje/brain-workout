import 'dart:isolate';

import '../games/arrow_escape/arrow_escape_models.dart';
import '../games/arrow_pictures/arrow_pictures_models.dart';
import '../games/snake_arrows/snake_arrows_models.dart';
import 'progress_store.dart';

/// Arrow Maze's boards, prefetched.
final arrowMazePrefetch = BoardPrefetch<SnakeBoard>(
  gameId: 'arrow_maze',
  generatorVersion: SnakeBoard.generatorVersion,
  generate: SnakeBoard.generate,
  toJson: _snakeToJson,
  fromJson: SnakeBoard.fromJson,
);

Map<String, dynamic> _snakeToJson(SnakeBoard b) => b.toJson();

/// Arrow Pictures' boards, prefetched.
final arrowPicturesPrefetch = BoardPrefetch<ArrowBoard>(
  gameId: 'arrow_pictures',
  generatorVersion: pictureGeneratorVersion,
  generate: generatePictureBoard,
  toJson: _arrowToJson,
  fromJson: ArrowBoard.fromJson,
);

Map<String, dynamic> _arrowToJson(ArrowBoard b) => b.toJson();

/// Arrow Pictures' long-arrow boards. A cache id of its own: the two kinds of
/// board share a game id for progress, but not a board format.
final arrowPicturesLongPrefetch = BoardPrefetch<SnakeBoard>(
  gameId: 'arrow_pictures_long',
  generatorVersion: pictureGeneratorVersion,
  generate: generateLongPictureBoard,
  toJson: _snakeToJson,
  fromJson: SnakeBoard.fromJson,
);

/// Warms whichever kind of board Arrow Pictures [level] uses.
void warmPictureLevel(int level) =>
    pictureArrowsForLevel(level) == PictureArrows.long
        ? arrowPicturesLongPrefetch.warm(level)
        : arrowPicturesPrefetch.warm(level);

/// Builds a game's boards ahead of time, so a slow generation never shows up
/// as a wait. One instance per game; written for Arrow Maze and generalised
/// when picture boards needed the same thing.
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
///    [generate]. Nothing here can prevent a level from opening.
///  - **A stored board carries the generator version that built it**
///    ([generatorVersion]), so changing the generator drops the cache rather
///    than serving boards the current build would never produce.
class BoardPrefetch<B> {
  BoardPrefetch({
    required this.gameId,
    required this.generatorVersion,
    required this.generate,
    required this.toJson,
    required this.fromJson,
  });

  final String gameId;
  final int generatorVersion;

  /// Runs inside a background isolate, so it must be a static or top-level
  /// function: a closure capturing this object would drag its futures along.
  final B Function(int level) generate;

  /// Must not serialise play state (which arrows have left), or a cached board
  /// comes back half-cleared. See the note on `SnakeBoard.toJson`.
  final Map<String, dynamic> Function(B board) toJson;
  final B? Function(Map<String, dynamic> json) fromJson;

  int? _level;
  B? _board;
  Future<void>? _inFlight;

  /// The level the in-flight build is for. Needed because [obtain] has to tell
  /// "a board for the level I want is nearly ready" from "a board for some other
  /// level is being built", and those want opposite behaviour.
  int? _inFlightLevel;

  /// A warm asked for while another build was in flight, run when that finishes.
  ///
  /// Only the most recent such request is kept: they are all "the board the player
  /// is most likely to want next", and the newest is the best guess. Dropping the
  /// request instead — which is what this used to do — could skip warming a level
  /// *entirely*, which is the one outcome the whole class exists to prevent.
  int? _queued;

  /// Starts building the board for [level] in a background isolate.
  ///
  /// Fire and forget: callers do not await it. Runs off the UI isolate because
  /// generation is synchronous CPU work — doing it inline would freeze whatever
  /// the player is looking at.
  void warm(int level) {
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
  void remember(int level, B board) {
    final store = ProgressStore.instanceOrNull;
    if (store == null) return;
    if (store.hasPrefetchedBoard(gameId, level, generatorVersion)) return;
    store.savePrefetchedBoard(gameId, level, generatorVersion, toJson(board));
  }

  void _start(int level) {
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

  Future<void> _run(int level) async {
    try {
      // Only the level number crosses into the isolate, and only plain lists come
      // back — an object graph is not reliably sendable. Locals, not fields, so
      // the closure does not capture `this`.
      final generate = this.generate;
      final toJson = this.toJson;
      final json = await Isolate.run(() => toJson(generate(level)));
      final board = fromJson(json);
      if (board == null) return;
      _level = level;
      _board = board;
      ProgressStore.instanceOrNull
          ?.savePrefetchedBoard(gameId, level, generatorVersion, json);
    } on Object {
      // An isolate that cannot spawn (or any other failure) must not break the
      // game; the caller falls back to generating on the spot. Nothing is
      // cleared here: a board held for *another* level is still good.
    }
  }

  /// Whether a stored board for [level] exists, without rebuilding it.
  bool _hasPersisted(int level) =>
      ProgressStore.instanceOrNull
          ?.hasPrefetchedBoard(gameId, level, generatorVersion) ??
      false;

  /// The stored board for [level] rebuilt, or null if there isn't a usable one.
  B? _persisted(int level) {
    final json = ProgressStore.instanceOrNull
        ?.loadPrefetchedBoard(gameId, level, generatorVersion);
    if (json == null) return null;
    return fromJson(json);
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
  Future<({B board, bool wasWarm})> obtain(int level) async {
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
    return (board: generate(level), wasWarm: false);
  }

  /// The prefetched board for [level] if one is ready, else null.
  ///
  /// Consumed on read: a board is handed out once, because the screen mutates it as
  /// the player clears arrows and a second caller must not receive that state.
  B? take(int level) {
    if (_level != level) return null;
    final board = _board;
    _level = null;
    _board = null;
    return board;
  }

  /// The in-flight build, if any — a test seam so a test can await the isolate
  /// instead of guessing at a delay.
  Future<void>? get pending => _inFlight;

  /// The level currently being built in the background, if any — a test seam so
  /// a widget test can assert that warming *started*, which is all that is
  /// observable inside a fake-async zone (the isolate itself cannot finish there).
  int? get warmingLevel => _inFlightLevel;

  /// Test seam: drop anything held, in memory and on disk.
  void reset() {
    _level = null;
    _board = null;
    _inFlight = null;
    _inFlightLevel = null;
    _queued = null;
    ProgressStore.instanceOrNull?.clearPrefetchedBoards(gameId);
  }

  /// Test seam: whether a board for [level] is ready to be taken.
  bool has(int level) => _level == level && _board != null;

  /// Test seam: put a board in directly, without an isolate.
  void seed(int level, B board) {
    _level = level;
    _board = board;
  }
}
