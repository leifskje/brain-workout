import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The full 3-8 letter word list for a language, used to tell a *near miss*
/// from a mistake.
///
/// Word Scramble needs this because roughly 60% of its puzzles spell more than
/// one real word — LAKE/LEAK, MELK/KLEM. Someone who spells the other word has
/// done nothing wrong, so they shouldn't lose a heart for it; they just haven't
/// found the word the category asks for.
///
/// Separate from Wordle's `WordRepository`, which serves 5-letter *answers*.
/// This list is far larger and deliberately exhaustive — inflections, archaisms
/// and obscurities included — because its only job is answering "is that a
/// word?", never "is that a good puzzle?".
class Dictionary {
  Dictionary._(this._words);

  final Set<String> _words;

  static final Map<String, Dictionary> _cache = {};
  static final Map<String, Future<Dictionary>> _loading = {};

  /// Loads (and caches) the list for [language], falling back to English.
  /// Concurrent calls share one load rather than parsing the asset twice.
  static Future<Dictionary> forLanguage(String language) {
    final cached = _cache[language];
    if (cached != null) return Future.value(cached);
    return _loading[language] ??= _load(language);
  }

  static Future<Dictionary> _load(String language) async {
    final asset = 'assets/words/${language}_all.txt';
    String text;
    try {
      text = await rootBundle.loadString(asset);
    } on Exception {
      text = await rootBundle.loadString('assets/words/en_all.txt');
    }
    final words = <String>{
      for (final line in const LineSplitter().convert(text))
        if (line.trim().isNotEmpty) line.trim().toUpperCase(),
    };
    final dict = Dictionary._(words);
    _cache[language] = dict;
    _loading.remove(language);
    return dict;
  }

  /// Already-loaded list for [language], or null if it hasn't loaded yet. Lets
  /// the UI treat a not-yet-loaded dictionary as "can't tell" rather than block.
  static Dictionary? loaded(String language) => _cache[language];

  int get count => _words.length;

  bool contains(String word) => _words.contains(word.toUpperCase());
}
