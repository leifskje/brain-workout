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
