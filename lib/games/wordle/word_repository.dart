import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import 'wordle_models.dart';

/// Loads and serves a language's word list (bundled asset). Caches per language
/// so the file is parsed only once.
class WordRepository {
  WordRepository._(this._words);

  final List<String> _words;
  late final Set<String> _set = _words.toSet();

  static final Map<String, WordRepository> _cache = {};

  static Future<WordRepository> forLanguage(WordleLanguage language) async {
    final cached = _cache[language.id];
    if (cached != null) return cached;

    final text = await rootBundle.loadString(language.asset);
    final words = [
      for (final line in const LineSplitter().convert(text))
        if (line.trim().length == wordLength) line.trim().toUpperCase(),
    ];
    final repo = WordRepository._(words);
    _cache[language.id] = repo;
    return repo;
  }

  int get count => _words.length;

  /// True if [word] is an accepted guess in this language.
  bool isValid(String word) => _set.contains(word.toUpperCase());

  /// A random answer word. Pass a seeded [rng] for deterministic picks.
  String randomWord([Random? rng]) =>
      _words[(rng ?? Random()).nextInt(_words.length)];
}
