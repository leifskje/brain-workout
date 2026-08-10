import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-game progress across app launches: furthest level reached,
/// stars earned per level, the daily-workout set, and the day streak.
///
/// Call [init] once at startup (see `main`) before using [instance].
class ProgressStore {
  ProgressStore._(this._prefs);

  static ProgressStore? _instance;
  final SharedPreferences _prefs;

  static ProgressStore get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('ProgressStore.init() must be awaited before use.');
    }
    return i;
  }

  static Future<void> init() async {
    _instance = ProgressStore._(await SharedPreferences.getInstance());
  }

  // ---------------------------------------------------------------- levels ---

  String _levelKey(String gameId) => 'highest_level_$gameId';

  /// The furthest level the player has reached for [gameId] (always >= 1).
  int highestLevel(String gameId) => _prefs.getInt(_levelKey(gameId)) ?? 1;

  /// Records that the player reached [level]. Only ever raises the stored
  /// value, so replaying earlier levels never lowers progress.
  void recordReached(String gameId, int level) {
    if (level > highestLevel(gameId)) {
      _prefs.setInt(_levelKey(gameId), level);
    }
  }

  // ----------------------------------------------------------------- stars ---

  String _starsKey(String gameId, int level) => 'stars_${gameId}_$level';

  /// Stars earned on [gameId] level [level] (0 = not yet cleared, else 1–3).
  int stars(String gameId, int level) =>
      _prefs.getInt(_starsKey(gameId, level)) ?? 0;

  /// Records [earned] stars for a level; keeps the best result.
  void recordStars(String gameId, int level, int earned) {
    if (earned > stars(gameId, level)) {
      _prefs.setInt(_starsKey(gameId, level), earned);
    }
  }

  /// Total stars earned across all levels of [gameId].
  int totalStars(String gameId) {
    var total = 0;
    for (var level = 1; level <= highestLevel(gameId); level++) {
      total += stars(gameId, level);
    }
    return total;
  }

  // ------------------------------------------------------------ last played ---

  String _openedKey(String gameId) => 'last_opened_$gameId';

  /// Call when the player opens a game from the home screen — drives the
  /// "Continue" row.
  void recordOpened(String gameId) =>
      _prefs.setInt(_openedKey(gameId), DateTime.now().millisecondsSinceEpoch);

  /// When the game was last opened (epoch millis; 0 = never).
  int lastOpened(String gameId) => _prefs.getInt(_openedKey(gameId)) ?? 0;

  // ---------------------------------------------------------- word of the day ---

  String _dailyKey(String language) => 'daily_word_$language';

  /// Records that today's word puzzle is finished, keeping the score rows so the
  /// result and its shareable grid can be shown again without replaying.
  ///
  /// [rows] is one string per guess of the characters `c`/`p`/`a` — compact, and
  /// it survives a format change more gracefully than serialised enums would.
  void recordDailyWord(String language, int puzzleNumber,
      {required bool solved, required List<String> rows}) {
    _prefs.setString(
        _dailyKey(language),
        jsonEncode({
          'puzzle': puzzleNumber,
          'solved': solved,
          'rows': rows,
        }));
  }

  /// Today's finished daily result for [language], or null if it hasn't been
  /// played yet. Keyed on [puzzleNumber] rather than a stored date string, so
  /// yesterday's result can never be mistaken for today's.
  ({bool solved, List<String> rows})? dailyWordResult(
      String language, int puzzleNumber) {
    final raw = _prefs.getString(_dailyKey(language));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['puzzle'] != puzzleNumber) return null;
      final rows = decoded['rows'];
      final solved = decoded['solved'];
      if (rows is! List || solved is! bool) return null;
      return (solved: solved, rows: [for (final r in rows) '$r']);
    } on FormatException {
      return null;
    }
  }

  // ------------------------------------------------------- personal records ---

  String _bestKey(String gameId, int level) => 'best_${gameId}_$level';

  /// The player's best result for [gameId] at [level], or null if never finished.
  ///
  /// Stored per level rather than per game: "fewest moves" only means something
  /// against the same board, and a 5x5 Picture Logic and a 12x12 are not
  /// comparable. Deliberately *local only* — this is save data, not analytics;
  /// nothing about it leaves the phone.
  int? bestResult(String gameId, int level) =>
      _prefs.getInt(_bestKey(gameId, level));

  /// Files [value] as a completed result and reports whether it beat the previous
  /// best.
  ///
  /// Returns false on a first completion. There is no record to beat the first
  /// time, and congratulating someone for setting one by simply finishing would
  /// make the message meaningless the one time it matters.
  bool recordBest(String gameId, int level, int value,
      {required bool lowerIsBetter}) {
    final key = _bestKey(gameId, level);
    final previous = _prefs.getInt(key);
    if (previous == null) {
      _prefs.setInt(key, value);
      return false;
    }
    final beaten = lowerIsBetter ? value < previous : value > previous;
    if (beaten) _prefs.setInt(key, value);
    return beaten;
  }

  // ------------------------------------------------------- saved board state ---

  // Bump when a game's saved shape changes incompatibly. Old saves are then
  // dropped instead of being fed to a parser that no longer understands them —
  // a half-restored board is worse than a fresh one, and an exception on resume
  // is worst of all.
  static const _saveVersion = 1;

  String _boardKey(String gameId) => 'board_$gameId';

  /// Stores the in-progress board for [gameId] at [level].
  ///
  /// One slot per game, not per level: the player is in the middle of exactly one
  /// board, and keeping every level's abandoned attempt around would grow without
  /// bound. The level is recorded *inside* the slot so [loadBoard] can refuse a
  /// save belonging to a different level — otherwise picking level 3 from the
  /// picker would resurrect your half-finished level 20.
  void saveBoard(String gameId, int level, Map<String, dynamic> state) {
    _prefs.setString(
        _boardKey(gameId),
        jsonEncode({
          'v': _saveVersion,
          'level': level,
          'state': state,
        }));
  }

  /// The saved board for [gameId] at [level], or null if there isn't a usable
  /// one. Returns null rather than throwing on anything unexpected — a corrupt
  /// or stale save must never be able to stop a game from opening.
  Map<String, dynamic>? loadBoard(String gameId, int level) {
    final raw = _prefs.getString(_boardKey(gameId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['v'] != _saveVersion) return null;
      if (decoded['level'] != level) return null;
      final state = decoded['state'];
      return state is Map<String, dynamic> ? state : null;
    } on FormatException {
      return null;
    }
  }

  /// Whether a resumable board exists for [gameId] at [level].
  bool hasSavedBoard(String gameId, int level) =>
      loadBoard(gameId, level) != null;

  /// Drops the saved board — call on win, on restart, and on giving up.
  void clearBoard(String gameId) => _prefs.remove(_boardKey(gameId));

  // ------------------------------------------------------------- how to play ---

  /// Whether the first-time "how to play" sheet was already shown for a game.
  bool helpSeen(String gameId) => _prefs.getBool('help_seen_$gameId') ?? false;

  void markHelpSeen(String gameId) =>
      _prefs.setBool('help_seen_$gameId', true);

  // ----------------------------------------------------------- app language ---

  /// The chosen app language ('en', 'nb'), or null to follow the phone.
  String? get appLanguageId => _prefs.getString('app_lang');

  void setAppLanguageId(String? id) {
    if (id == null) {
      _prefs.remove('app_lang');
    } else {
      _prefs.setString('app_lang', id);
    }
  }

  // -------------------------------------------------------- wordle language ---

  /// The chosen Word language, or null to fall back to the app locale.
  String? get wordleLanguageId => _prefs.getString('wordle_lang');
  void setWordleLanguageId(String id) => _prefs.setString('wordle_lang', id);

  // ------------------------------------------------- daily workout & streak ---

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get bestStreak => _prefs.getInt('streak_best') ?? 0;

  /// The current streak, but only if it is still alive (last credited today or
  /// yesterday). A lapsed streak shows as 0 until the next play restarts it.
  int get currentStreak {
    final last = _prefs.getString('streak_lastDate');
    if (last == null) return 0;
    final now = DateTime.now();
    final today = _dateString(now);
    final yesterday = _dateString(now.subtract(const Duration(days: 1)));
    if (last == today || last == yesterday) {
      return _prefs.getInt('streak_current') ?? 0;
    }
    return 0;
  }

  /// How many levels make up a daily workout (any games count toward it).
  static const int dailyGoal = 3;

  /// Levels completed today, toward the daily-workout goal.
  int get dailyCount {
    final today = _dateString(DateTime.now());
    if (_prefs.getString('daily_date') != today) return 0;
    return _prefs.getInt('daily_count') ?? 0;
  }

  bool get dailyWorkoutComplete => dailyCount >= dailyGoal;

  /// Call when the player completes a level (in any game). Counts toward
  /// today's workout goal and credits the day streak (streak once per day).
  /// [gameId] is accepted for future per-game stats.
  void registerPlay(String gameId) {
    final now = DateTime.now();
    final today = _dateString(now);

    // Daily count — reset when the calendar day changes.
    final isNewDay = _prefs.getString('daily_date') != today;
    if (isNewDay) _prefs.setString('daily_date', today);
    final count = isNewDay ? 0 : (_prefs.getInt('daily_count') ?? 0);
    _prefs.setInt('daily_count', count + 1);

    // Streak — credit once per day.
    final lastDate = _prefs.getString('streak_lastDate');
    if (lastDate != today) {
      final yesterday = _dateString(now.subtract(const Duration(days: 1)));
      final prior = _prefs.getInt('streak_current') ?? 0;
      final next = (lastDate == yesterday) ? prior + 1 : 1;
      _prefs.setInt('streak_current', next);
      _prefs.setString('streak_lastDate', today);
      if (next > bestStreak) _prefs.setInt('streak_best', next);
    }
  }
}
