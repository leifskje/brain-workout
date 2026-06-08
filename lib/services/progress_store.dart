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

  /// Game ids the player has completed *today* (for the daily-workout goal).
  Set<String> dailyDone() {
    final today = _dateString(DateTime.now());
    if (_prefs.getString('daily_date') != today) return <String>{};
    return (_prefs.getStringList('daily_done') ?? const <String>[]).toSet();
  }

  /// Call when the player completes a level in [gameId]. Adds it to today's
  /// workout set and credits the day streak (each at most once per day).
  void registerPlay(String gameId) {
    final now = DateTime.now();
    final today = _dateString(now);

    // Daily-workout set — reset when the calendar day changes.
    if (_prefs.getString('daily_date') != today) {
      _prefs.setString('daily_date', today);
      _prefs.setStringList('daily_done', const <String>[]);
    }
    final done = (_prefs.getStringList('daily_done') ?? <String>[]).toSet()
      ..add(gameId);
    _prefs.setStringList('daily_done', done.toList());

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
