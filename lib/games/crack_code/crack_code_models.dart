import 'dart:math';

/// Crack the Code — Mastermind with digits. Guess the secret code; after each
/// guess, clues show how many digits are correct-and-in-place (exact) and how
/// many are correct-but-misplaced (present). The code never repeats a digit,
/// which keeps deduction gentle.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

class CrackCodeConfig {
  const CrackCodeConfig({
    required this.length,
    required this.symbols,
    required this.maxGuesses,
  });

  final int length; // code length
  final int symbols; // digits run 1..symbols
  final int maxGuesses;
}

CrackCodeConfig crackCodeConfigForLevel(int level) {
  if (level < 4) {
    return const CrackCodeConfig(length: 3, symbols: 5, maxGuesses: 8);
  }
  if (level < 8) {
    return const CrackCodeConfig(length: 4, symbols: 6, maxGuesses: 9);
  }
  if (level < 12) {
    return const CrackCodeConfig(length: 4, symbols: 7, maxGuesses: 9);
  }
  // Kept climbing past here rather than stopping at 5/8/10, which used to be
  // every level from 12 upwards. Guesses grow alongside length and symbols so
  // the harder codes stay deducible rather than becoming a lottery.
  if (level < 18) {
    return const CrackCodeConfig(length: 5, symbols: 8, maxGuesses: 10);
  }
  if (level < 26) {
    return const CrackCodeConfig(length: 5, symbols: 9, maxGuesses: 10);
  }
  if (level < 36) {
    return const CrackCodeConfig(length: 6, symbols: 9, maxGuesses: 11);
  }
  return const CrackCodeConfig(length: 6, symbols: 10, maxGuesses: 12);
}

class CrackCodeGame {
  CrackCodeGame._(this.code, this.maxGuesses);

  final List<int> code; // distinct digits, 1..symbols
  final int maxGuesses;
  final List<List<int>> guesses = [];
  final List<({int exact, int present})> results = [];

  bool get isWon =>
      results.isNotEmpty && results.last.exact == code.length;
  bool get isLost => !isWon && guesses.length >= maxGuesses;

  /// Scores and records [guess] (same length as [code]).
  ({int exact, int present}) submit(List<int> guess) {
    assert(guess.length == code.length);
    var exact = 0, present = 0;
    for (var i = 0; i < code.length; i++) {
      if (guess[i] == code[i]) {
        exact++;
      } else if (code.contains(guess[i])) {
        // The code has no repeated digits, so containment is enough.
        present++;
      }
    }
    guesses.add([...guess]);
    results.add((exact: exact, present: present));
    return results.last;
  }

  /// Builds the level's secret code, seeded so a retry gives the same one.
  static CrackCodeGame generate(int level) {
    final cfg = crackCodeConfigForLevel(level);
    final rng = Random(level * 5099 + 433);
    final digits = [for (var d = 1; d <= cfg.symbols; d++) d]..shuffle(rng);
    return CrackCodeGame._(digits.take(cfg.length).toList(), cfg.maxGuesses);
  }
}
