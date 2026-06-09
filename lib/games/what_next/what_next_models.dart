import 'dart:math';

/// One "what comes next?" question: a few visible terms, the hidden next term,
/// and four multiple-choice options (including the answer).
class SequenceQuestion {
  SequenceQuestion({
    required this.shown,
    required this.answer,
    required this.options,
  });

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

/// Builds a deterministic set of sequence questions for a level. All terms and
/// options stay positive (kept simple for the audience). Seeded by level so a
/// retry gives the same questions.
class WhatNextRound {
  static const _visible = 4;

  static List<SequenceQuestion> generate(int level) {
    final cfg = whatNextConfigForLevel(level);
    return [for (var q = 0; q < cfg.questions; q++) _question(level, q, cfg.tier)];
  }

  static SequenceQuestion _question(int level, int qIndex, int tier) {
    final rng = Random(level * 100003 + qIndex * 31 + 7);

    // Pick a rule appropriate to the tier.
    // tier 1: arithmetic only. tier 2: + geometric. tier 3: + increasing-step.
    final rule = tier == 1 ? 0 : rng.nextInt(tier == 2 ? 2 : 3);

    List<int> terms;
    switch (rule) {
      case 1: // geometric: ×2 or ×3
        final start = rng.nextInt(3) + 1;
        final ratio = rng.nextBool() ? 2 : 3;
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
      shown: shown,
      answer: answer,
      options: _options(answer, shown.last, rng),
    );
  }

  static List<int> _options(int answer, int last, Random rng) {
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
}
