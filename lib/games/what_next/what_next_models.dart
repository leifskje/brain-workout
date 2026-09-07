import 'dart:math';

/// What kind of pattern a question shows. All carry their data as ints; the UI
/// renders each int according to the kind:
/// - [number]: the literal number
/// - [dots]: that many dots
/// - [color]: a palette colour index
/// - [arrow]: a rotation (0=up,1=right,2=down,3=left)
enum QuestionKind { number, dots, color, arrow }

/// Number of palette colours / used by the colour-cycle questions and the UI.
const int patternColorCount = 4;

/// One "what comes next?" question: a few visible terms, the hidden next term,
/// and four multiple-choice options (including the answer). Values are ints
/// interpreted per [kind].
class SequenceQuestion {
  SequenceQuestion({
    required this.kind,
    required this.shown,
    required this.answer,
    required this.options,
  });

  final QuestionKind kind;
  final List<int> shown;
  final int answer;
  final List<int> options;
}

class WhatNextLevelConfig {
  const WhatNextLevelConfig({
    required this.questions,
    required this.hearts,
    required this.tier,
  });

  final int questions;
  final int hearts;
  final int tier; // 1 easy .. 5 hard
}

WhatNextLevelConfig whatNextConfigForLevel(int level) {
  final questions = (4 + (level - 1) ~/ 2).clamp(4, 8);
  // Tiers 4 and 5 unlock the two harder rules (sum-of-previous-two, and two
  // interleaved sequences). Both are standard puzzle fare for a well-read adult
  // and neither is reachable by "spot the constant step", which is what the first
  // three tiers all reduce to — the reason the curve went flat at level 9. Also
  // slowed to one tier per four levels so the ladder isn't spent immediately.
  final tier = (1 + (level - 1) ~/ 4).clamp(1, 5);
  return WhatNextLevelConfig(questions: questions, hearts: 5, tier: tier);
}

/// Builds a deterministic set of questions for a level — a mix of number
/// sequences and visual (dots/colour/arrow) patterns. Seeded by level so a
/// retry gives the same questions.
class WhatNextRound {
  static const _visible = 4;

  static List<SequenceQuestion> generate(int level) {
    final cfg = whatNextConfigForLevel(level);
    return [for (var q = 0; q < cfg.questions; q++) _question(level, q, cfg.tier)];
  }

  static SequenceQuestion _question(int level, int qIndex, int tier) {
    final rng = Random(level * 100003 + qIndex * 31 + 7);
    // ~40% visual pattern questions, the rest number sequences.
    if (rng.nextInt(10) < 4) {
      const shapeKinds = [QuestionKind.dots, QuestionKind.color, QuestionKind.arrow];
      return _shapeQuestion(shapeKinds[rng.nextInt(shapeKinds.length)], rng, tier);
    }
    return _numberQuestion(rng, tier);
  }

  static SequenceQuestion _numberQuestion(Random rng, int tier) {
    // Each tier adds one rule to the pool it may draw from, so higher tiers stay
    // varied rather than only ever showing the newest, hardest rule.
    final rulePool = switch (tier) {
      1 => 1, // constant step only
      2 => 2,
      3 => 3,
      4 => 4, // + sum of the previous two
      _ => 5, // + two interleaved sequences
    };
    final rule = tier == 1 ? 0 : rng.nextInt(rulePool);

    List<int> terms;
    switch (rule) {
      case 1: // geometric: doubling (gentle mental step)
        final start = rng.nextInt(3) + 1;
        const ratio = 2;
        terms = [for (var i = 0; i <= _visible; i++) start * pow(ratio, i).toInt()];
      case 2: // increasing differences: +1, +2, +3, ...
        final start = rng.nextInt(5) + 1;
        var d = rng.nextInt(3) + 1;
        terms = [start];
        for (var i = 1; i <= _visible; i++) {
          terms.add(terms.last + d);
          d += 1;
        }
      case 3: // each term is the sum of the previous two (Fibonacci-like)
        final a = rng.nextInt(3) + 1;
        final b = a + rng.nextInt(3) + 1; // keep it ascending
        terms = [a, b];
        for (var i = 2; i <= _visible; i++) {
          terms.add(terms[i - 2] + terms[i - 1]);
        }
      case 4: // two interleaved sequences: 3, 20, 6, 30, 9 -> 40
        // The answer sits in whichever strand lands on the last slot, so both
        // strands have to be tracked rather than one difference.
        final startA = rng.nextInt(5) + 1;
        final stepA = rng.nextInt(4) + 2;
        final startB = (rng.nextInt(3) + 2) * 10;
        final stepB = (rng.nextInt(2) + 1) * 10;
        terms = [
          for (var i = 0; i <= _visible; i++)
            i.isEven
                ? startA + (i ~/ 2) * stepA
                : startB + (i ~/ 2) * stepB,
        ];
      default: // arithmetic: constant positive step
        final start = rng.nextInt(9) + 1;
        final step = rng.nextInt(tier == 1 ? 5 : 9) + 1;
        terms = [for (var i = 0; i <= _visible; i++) start + i * step];
    }

    final shown = terms.sublist(0, _visible);
    final answer = terms[_visible];
    return SequenceQuestion(
      kind: QuestionKind.number,
      shown: shown,
      answer: answer,
      options: _numberOptions(answer, shown.last, rng),
    );
  }

  /// Visual patterns, graded by [tier].
  ///
  /// These used to ignore the tier entirely: dots always counted up by one,
  /// arrows always turned a quarter clockwise, and colour cycles were 2-4 long.
  /// Since roughly 40% of every round is a shape question, that left nearly half
  /// the game exactly as hard at level 60 as at level 1 — "yellow, red, yellow,
  /// red, ...?" is the two-colour cycle, and it could appear at any level. The
  /// level audit missed it because the *number* tiers did climb.
  static SequenceQuestion _shapeQuestion(
      QuestionKind kind, Random rng, int tier) {
    switch (kind) {
      case QuestionKind.dots:
        // Tier 1-2 count up by one; higher tiers vary the step, and from tier 4
        // the step itself grows, so the count can't be read off as "one more".
        // Bounded on purpose: the answer is drawn as that many dots, and past
        // a dozen they stop being countable at a glance, which is a different
        // (and worse) kind of hard. Growing steps therefore start from 1.
        final growing = tier >= 4 && rng.nextBool();
        final start = growing ? 1 : rng.nextInt(2) + 1;
        final step = (tier <= 2 || growing) ? 1 : rng.nextInt(2) + 1;
        final terms = <int>[start];
        var d = step;
        for (var i = 1; i <= _visible; i++) {
          terms.add(terms.last + d);
          if (growing) d += 1;
        }
        return SequenceQuestion(
          kind: kind,
          shown: terms.sublist(0, _visible),
          answer: terms[_visible],
          options: _dotOptions(terms[_visible], rng),
        );
      case QuestionKind.color:
        // The cycle has to be longer than the four visible terms before the
        // answer stops being "look four back". At tier 4+ the cycle also runs
        // backwards half the time.
        final minLen = switch (tier) { 1 => 2, 2 => 3, 3 => 4, _ => 5 };
        final maxLen = switch (tier) { 1 => 3, 2 => 4, _ => 6 };
        final cycleLen = minLen + rng.nextInt(maxLen - minLen + 1);
        final cycle = <int>[
          for (var i = 0; i < cycleLen; i++) rng.nextInt(patternColorCount),
        ];
        // A cycle of a single repeated colour is not a pattern.
        if (cycle.toSet().length < 2) {
          cycle[0] = (cycle[0] + 1) % patternColorCount;
        }
        final reversed = tier >= 4 && rng.nextBool();
        int at(int i) =>
            cycle[reversed ? (cycleLen - 1 - (i % cycleLen)) : (i % cycleLen)];
        return SequenceQuestion(
          kind: kind,
          shown: [for (var i = 0; i < _visible; i++) at(i)],
          answer: at(_visible),
          options: [0, 1, 2, 3]..shuffle(rng),
        );
      default:
        // Arrows: a quarter clockwise forever is one rule. Higher tiers pick a
        // different rotation, may run anticlockwise, and from tier 5 alternate
        // between two rotations.
        final start = rng.nextInt(4);
        final stepSize = tier <= 1 ? 1 : rng.nextInt(3) + 1; // 1..3 quarters
        final dir = tier >= 3 && rng.nextBool() ? -1 : 1;
        final alternating = tier >= 5 && rng.nextBool();
        final other = rng.nextInt(3) + 1;
        int at(int i) {
          var v = start;
          for (var k = 0; k < i; k++) {
            final s = alternating && k.isOdd ? other : stepSize;
            v += dir * s;
          }
          return v % 4 < 0 ? v % 4 + 4 : v % 4;
        }
        return SequenceQuestion(
          kind: QuestionKind.arrow,
          shown: [for (var i = 0; i < _visible; i++) at(i)],
          answer: at(_visible),
          options: [0, 1, 2, 3]..shuffle(rng),
        );
    }
  }

  static List<int> _numberOptions(int answer, int last, Random rng) {
    final d = (answer - last).abs().clamp(1, 1 << 30);
    final chosen = <int>{answer};
    for (final c in [answer + 1, answer - 1, answer + d, answer - d, answer + 2 * d]) {
      if (chosen.length >= 4) break;
      if (c != answer && c > 0) chosen.add(c);
    }
    var bump = 2;
    while (chosen.length < 4) {
      chosen.add(answer + bump);
      bump++;
    }
    return chosen.toList()..shuffle(rng);
  }

  /// Distractors for a dot count. They must sit on *both* sides of the answer:
  /// clamping them into 1..9 meant a larger answer got only bigger neighbours,
  /// so "the smallest option" was the answer without counting anything.
  static List<int> _dotOptions(int answer, Random rng) {
    final chosen = <int>{answer};
    for (final delta in [-1, 1, -2, 2, -3, 3, 4]) {
      if (chosen.length >= 4) break;
      final c = answer + delta;
      if (c >= 1) chosen.add(c);
    }
    var bump = 5;
    while (chosen.length < 4) {
      chosen.add(answer + bump);
      bump++;
    }
    return chosen.toList()..shuffle(rng);
  }
}
