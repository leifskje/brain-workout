// Core logic for the Wordle-style word game (pure Dart, no Flutter imports
// so it stays unit-testable).

const int wordLength = 5;
const int maxGuesses = 6;

/// Per-letter feedback for a guess.
enum LetterState {
  correct, // right letter, right position (green)
  present, // letter is in the word, wrong position (yellow)
  absent, // letter not in the word (grey)
}

/// A selectable language: its word-list asset and on-screen keyboard layout.
class WordleLanguage {
  const WordleLanguage({
    required this.id,
    required this.name,
    required this.asset,
    required this.keyboardRows,
  });

  final String id;
  final String name;
  final String asset;
  final List<String> keyboardRows;
}

/// Available languages. Add another by dropping in `assets/words/<id>.txt` and
/// a keyboard layout.
const List<WordleLanguage> wordleLanguages = [
  WordleLanguage(
    id: 'en',
    name: 'English',
    asset: 'assets/words/en.txt',
    keyboardRows: ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'],
  ),
  WordleLanguage(
    id: 'nb',
    name: 'Norsk',
    asset: 'assets/words/nb.txt',
    keyboardRows: ['QWERTYUIOPÅ', 'ASDFGHJKLØÆ', 'ZXCVBNM'],
  ),
];

/// The language with [id], or the first as a fallback.
WordleLanguage wordleLanguageById(String id) =>
    wordleLanguages.firstWhere((l) => l.id == id, orElse: () => wordleLanguages.first);

/// Scores [guess] against [target], returning one [LetterState] per position.
///
/// Handles duplicate letters the way Wordle does: greens are assigned first and
/// consume an occurrence of that letter in the target; only the remaining
/// occurrences can turn a later position yellow. Both inputs must be the same
/// length (caller enforces [wordLength]).
List<LetterState> scoreGuess(String guess, String target) {
  final g = guess.toUpperCase();
  final t = target.toUpperCase();
  assert(g.length == t.length, 'guess and target must be the same length');

  final result = List<LetterState>.filled(g.length, LetterState.absent);
  final remaining = <String, int>{};
  for (final ch in t.split('')) {
    remaining[ch] = (remaining[ch] ?? 0) + 1;
  }

  // First pass: exact matches (green).
  for (var i = 0; i < g.length; i++) {
    if (g[i] == t[i]) {
      result[i] = LetterState.correct;
      remaining[g[i]] = remaining[g[i]]! - 1;
    }
  }

  // Second pass: present-but-misplaced (yellow), limited by what's left.
  for (var i = 0; i < g.length; i++) {
    if (result[i] == LetterState.correct) continue;
    final ch = g[i];
    if ((remaining[ch] ?? 0) > 0) {
      result[i] = LetterState.present;
      remaining[ch] = remaining[ch]! - 1;
    }
  }

  return result;
}

/// Stars for solving in [guesses] tries: ≤3 → 3, ≤4 → 2, else 1.
int wordleStars(int guesses) {
  if (guesses <= 3) return 3;
  if (guesses <= 4) return 2;
  return 1;
}
