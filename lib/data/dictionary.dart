import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'word_tier.dart';

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
  Dictionary._(this._tiers);

  final Map<String, WordTier> _tiers;

  Iterable<String> get words => _tiers.keys;

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
    // Each line is WORD<TAB>tier. A line without a tier still counts as a valid
    // word (falling back to junk), so a malformed row can never make a real word
    // look unreal and cost the player a heart.
    final tiers = <String, WordTier>{};
    for (final line in const LineSplitter().convert(text)) {
      if (line.trim().isEmpty) continue;
      final tab = line.indexOf('\t');
      if (tab < 0) {
        tiers[line.trim().toUpperCase()] = WordTier.junk;
      } else {
        tiers[line.substring(0, tab).trim().toUpperCase()] =
            WordTier.fromCode(line.substring(tab + 1).trim());
      }
    }
    final dict = Dictionary._(tiers);
    _cache[language] = dict;
    _loading.remove(language);
    return dict;
  }

  /// Already-loaded list for [language], or null if it hasn't loaded yet. Lets
  /// the UI treat a not-yet-loaded dictionary as "can't tell" rather than block.
  static Dictionary? loaded(String language) => _cache[language];

  int get count => _tiers.length;

  bool contains(String word) => _tiers.containsKey(word.toUpperCase());

  /// How common [word] is, or null if it isn't a word at all.
  WordTier? tierOf(String word) => _tiers[word.toUpperCase()];

  /// Words of [length] within [tiers], for choosing puzzle words. Never returns
  /// [WordTier.junk] entries unless explicitly asked for them.
  List<String> wordsOfLength(int length, Set<WordTier> tiers) => [
        for (final entry in _tiers.entries)
          if (entry.key.length == length && tiers.contains(entry.value))
            entry.key,
      ];
}
