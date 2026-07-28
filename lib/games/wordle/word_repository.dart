import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../../data/dictionary.dart';
import '../../data/word_tier.dart';
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
    // Sort the answers by how common they are, so most answers are gettable.
    repo.attachTiers(await Dictionary.forLanguage(language.id));
    _cache[language.id] = repo;
    return repo;
  }

  int get count => _words.length;

  /// True if [word] is an accepted guess in this language.
  bool isValid(String word) => _set.contains(word.toUpperCase());

  /// Answers split by how common the word is, filled in by [attachTiers].
  List<String> _commonAnswers = const [];
  List<String> _rarerAnswers = const [];

  /// One answer in [_rareEvery] is drawn from the rarer pool.
  static const _rareEvery = 5;

  /// Sorts the answer list into common and rarer pools using [dictionary].
  ///
  /// Without this, answers are drawn uniformly from an exhaustive word list —
  /// which means *most* of them are obscure. A sample of twenty English answers
  /// contained about five recognisable words (HIGRA, PONGO, SUYOG, BEMIX...).
  /// That is the opposite of a fair guessing game, where the answer has to be
  /// gettable and the letter feedback is the only intended difficulty.
  void attachTiers(Dictionary dictionary) {
    final common = <String>[];
    final rarer = <String>[];
    for (final word in _words) {
      switch (dictionary.tierOf(word)) {
        case WordTier.common:
        case WordTier.normal:
          common.add(word);
        case WordTier.lessCommon:
          rarer.add(word);
        // Junk and unknown words stay out of the answer pools entirely; they are
        // still accepted as *guesses* via isValid.
        case WordTier.junk:
        case null:
          break;
      }
    }
    // Only adopt the split if it left something to draw from, so a missing or
    // malformed tier file degrades to the old behaviour instead of breaking.
    if (common.isNotEmpty) {
      _commonAnswers = common;
      _rarerAnswers = rarer;
    }
  }

  int get commonAnswerCount => _commonAnswers.length;
  int get rarerAnswerCount => _rarerAnswers.length;

  /// A random answer word. Pass a seeded [rng] for deterministic picks.
  ///
  /// Mostly common words, with roughly one in [_rareEvery] drawn from the rarer
  /// pool so the game stays interesting for a strong vocabulary.
  String randomWord([Random? rng]) {
    final random = rng ?? Random();
    if (_commonAnswers.isEmpty) {
      return _words[random.nextInt(_words.length)];
    }
    if (_rarerAnswers.isNotEmpty && random.nextInt(_rareEvery) == 0) {
      return _rarerAnswers[random.nextInt(_rarerAnswers.length)];
    }
    return _commonAnswers[random.nextInt(_commonAnswers.length)];
  }
}
