import 'dart:math';

/// Simon — watch the colored buttons light up in order, then repeat the
/// sequence by tapping. Each round replays the sequence one step longer;
/// the level is won when the full target sequence is repeated.
///
/// Pure Dart (no Flutter imports) so it stays unit-testable.

class SimonConfig {
  const SimonConfig({
    required this.buttons,
    required this.targetLength,
    required this.flashMs,
    required this.hearts,
  });

  final int buttons; // always 4 — two huge rows of two
  final int targetLength;
  final int flashMs; // how long each button stays lit during playback
  final int hearts;
}

SimonConfig simonConfigForLevel(int level) {
  return SimonConfig(
    buttons: 4,
    targetLength: (3 + level ~/ 2).clamp(3, 12),
    // Playback speeds up gently on higher levels.
    flashMs: (650 - level * 12).clamp(420, 650),
    hearts: 3,
  );
}

/// What a tap did to the game state.
enum SimonTap { step, roundComplete, won, wrong }

class SimonGame {
  SimonGame._(this.sequence);

  /// The full target sequence (button indices 0..3).
  final List<int> sequence;

  /// Current round = how many steps of [sequence] are in play (1-based).
  int round = 1;

  /// How many correct taps the player has made this round.
  int inputPos = 0;

  List<int> get shown => sequence.sublist(0, round);

  /// Handles a tap on [button]. A wrong tap resets the round's input so the
  /// player retries the same round (after the screen replays it).
  SimonTap tap(int button) {
    if (button != sequence[inputPos]) {
      inputPos = 0;
      return SimonTap.wrong;
    }
    inputPos++;
    if (inputPos < round) return SimonTap.step;
    if (round == sequence.length) return SimonTap.won;
    round++;
    inputPos = 0;
    return SimonTap.roundComplete;
  }

  /// Builds the level's sequence, seeded so a retry gives the same one.
  /// Never repeats the same button three times in a row — long same-button
  /// runs read as a single flash and feel unfair.
  static SimonGame generate(int level) {
    final cfg = simonConfigForLevel(level);
    final rng = Random(level * 3571 + 257);
    final seq = <int>[];
    while (seq.length < cfg.targetLength) {
      final b = rng.nextInt(cfg.buttons);
      final n = seq.length;
      if (n >= 2 && seq[n - 1] == b && seq[n - 2] == b) continue;
      seq.add(b);
    }
    return SimonGame._(seq);
  }
}
