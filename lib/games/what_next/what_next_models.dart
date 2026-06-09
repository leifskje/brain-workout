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
  final int tier; // 1 easy .. 3 hard
}

WhatNextLevelConfig whatNextConfigForLevel(int level) {
  final questions = (4 + (level - 1) ~/ 2).clamp(4, 8);
  final tier = (1 + (level - 1) ~/ 3).clamp(1, 3);
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
      return _shapeQuestion(shapeKinds[rng.nextInt(shapeKinds.length)], rng);
    }
    return _numberQuestion(rng, tier);
  }

  static SequenceQuestion _numberQuestion(Random rng, int tier) {
    final rule = tier == 1 ? 0 : rng.nextInt(tier == 2 ? 2 : 3);

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

  static SequenceQuestion _shapeQuestion(QuestionKind kind, Random rng) {
    switch (kind) {
      case QuestionKind.dots:
        final start = rng.nextInt(2) + 1; // 1 or 2
        final terms = [for (var i = 0; i <= _visible; i++) start + i];
        return SequenceQuestion(
          kind: kind,
          shown: terms.sublist(0, _visible),
          answer: terms[_visible],
          options: _dotOptions(terms[_visible], rng),
        );
      case QuestionKind.color:
        final cycleLen = rng.nextInt(3) + 2; // 2..4
        final cycle = ([0, 1, 2, 3]..shuffle(rng)).take(cycleLen).toList();
        return SequenceQuestion(
          kind: kind,
          shown: [for (var i = 0; i < _visible; i++) cycle[i % cycleLen]],
          answer: cycle[_visible % cycleLen],
          options: [0, 1, 2, 3]..shuffle(rng),
        );
      default: // arrow: rotate one quarter clockwise each step
        final start = rng.nextInt(4);
        return SequenceQuestion(
          kind: QuestionKind.arrow,
          shown: [for (var i = 0; i < _visible; i++) (start + i) % 4],
          answer: (start + _visible) % 4,
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

  static List<int> _dotOptions(int answer, Random rng) {
    final chosen = <int>{answer};
    for (final c in [answer - 1, answer + 1, answer + 2, answer - 2, answer + 3]) {
      if (chosen.length >= 4) break;
      if (c >= 1 && c <= 9) chosen.add(c);
    }
    var bump = 3;
    while (chosen.length < 4) {
      chosen.add(answer + bump);
      bump++;
    }
    return chosen.toList()..shuffle(rng);
  }
}
