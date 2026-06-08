import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-game progress (the furthest level reached) across app launches.
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

  String _key(String gameId) => 'highest_level_$gameId';

  /// The furthest level the player has reached for [gameId] (always >= 1).
  int highestLevel(String gameId) => _prefs.getInt(_key(gameId)) ?? 1;

  /// Records that the player reached [level]. Only ever raises the stored
  /// value, so replaying earlier levels never lowers progress.
  void recordReached(String gameId, int level) {
    if (level > highestLevel(gameId)) {
      _prefs.setInt(_key(gameId), level);
    }
  }
}
