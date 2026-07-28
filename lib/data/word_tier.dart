/// How common a word is, used to pick puzzle words that are hard but fair.
///
/// Sourced from SCOWL's size tiers (English) and corpus frequency rank
/// (Norwegian) — see `lib/screens/credits_screen.dart` for attribution.
///
/// Deliberately in its own Flutter-free file: the game models that choose puzzle
/// words are pure Dart so they stay unit-testable, and they need this enum.
/// `Dictionary`, which loads the tiers from an asset, is not pure Dart.
library;

enum WordTier {
  /// Everyday vocabulary: ABDUCT, ANGREP.
  common,

  /// Ordinary but less frequent: ABSEIL, AKSENT.
  normal,

  /// Rare and real — the hard end of a fair puzzle: ABBACY, ADELIG.
  lessCommon,

  /// Obscure to the point of being unfair: AALIIS, ABRODD. Valid for *checking*
  /// a word, never for setting one. Puzzle code must not draw from this tier.
  junk;

  static WordTier fromCode(String code) => switch (code) {
        '1' => WordTier.common,
        '2' => WordTier.normal,
        '3' => WordTier.lessCommon,
        _ => WordTier.junk,
      };
}
