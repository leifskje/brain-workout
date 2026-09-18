# Odd One Out (Finn den som ikke passer)

Six items, one doesn't belong. Tap it. The other five share something the odd
one lacks — a colour, a shape, a category, a number property.

Category: attention / speed (without the speed — no timer, as everywhere else).
It is the second game in that domain after Follow the Trail, and the first that
is *visual* rather than motor: Trail asks you to track a path, this asks you to
scan a set and notice what is uniform.

## Why it needs more care than it looks

Odd-one-out is trivial to generate and hard to generate *fairly*. Every item has
several attributes, so a set built to isolate one item on colour can accidentally
isolate a different item on size. Both answers are then defensible and the game
is simply wrong — which for a well-read player is worse than being too hard,
because the game is telling them they are mistaken when they are not.

This is the same class of problem as nonogram uniqueness, and it gets the same
treatment: **prove it, don't construct it and hope.** See the Picture Logic note
in `CLAUDE.md`, and `tool/analyze_scramble_ambiguity.dart` for the precedent of
auditing a generator for ambiguity rather than assuming it.

**The fairness check.** Each item is a set of attribute → value pairs. After
generating a candidate set, for every attribute count the items holding a value
no other item holds. Accept the set only if the union of all such isolated items
is exactly one item — the intended answer. Anything else is discarded. The check
is attributes × items, so it costs nothing and can run on every candidate.

Note what this rules out and should: a set where *no* attribute isolates
anything (no answer), and a set where two different attributes isolate two
different items (two answers).

## Design

- **Model (pure Dart, no Flutter imports):** an `OddItem` is a map of attributes.
  Three families, mixed by level:
  - **Visual** — shape, fill colour, outline, size, rotation, dot count. Language
    neutral, which matters: a player who finds word games hard should not be shut
    out of an attention game. Weighted heaviest at low levels.
  - **Semantic** — five words from one `WordCategory` and one from another,
    reusing `lib/data/word_pool.dart` (already categorised, already bilingual).
  - **Numeric** — parity, multiples, digit sum, range. Smallest share; arithmetic
    under observation is a different game and this is not a numeracy slot.
- **Difficulty**, in the order they should be tuned:
  1. **Varying attributes** — the real knob. With one attribute varying the
     answer is pre-attentive and needs no thought; with four you must check each
     dimension in turn. This is the analogue of branching factor.
  2. **Near-miss distractors** — two items sharing an otherwise-rare value, so a
     quick scan lands on one of them and has to be verified. Fairness is not at
     risk (a shared value isolates nobody), but scan cost rises sharply.
  3. **Item count**, 4 → 9. Weakest axis and capped early: nine items at a
     legible tap size is about what a phone holds. Do not chase difficulty here.
  4. **Attribute subtlety** — colour is instant, rotation and dot count are not.
- **Measured, not assumed.** `tool/analyze_odd_one_out_difficulty.dart`, modelled
  on `analyze_snake_difficulty.dart`: simulate a rational scanner that checks one
  attribute across all items at a time, and report the **scan cost** — how many
  (item, attribute) pairs must be read before the answer is forced. Set the
  per-level targets from the printed spread, not by guessing, and re-run it after
  any generator change. Audit the plateau with `analyze_level_curves.dart`.
- **Hearts:** 3. A wrong tap costs one and the set stays up — the answer is still
  there to be found, and removing it would punish twice. Stars by hearts lost
  (0 → 3★, ≤2 → 2★), the standard bar.
- **Screen:** a grid of large cards, one round per set, several rounds per level.
  Correct → brief confirm, next round. Wrong → shake the tapped card, lose a
  heart. No timer, no streak pressure. Visual items are drawn with `CustomPaint`,
  so there are no image assets to license.
- **Assist:** the same bargain as the word-game hints — a lightbulb that greys out
  two items that are *not* the answer, capping the level at 2 stars. Costs a star,
  never a heart.
- **Localisation:** all UI strings in both `.arb` files. Visual rounds carry no
  text at all; semantic rounds draw their words from the existing bilingual pool.

## Open questions

- Should a round state the rule ("five of these are animals") or leave it to be
  discovered? Stating it is much easier and probably right for the first few
  levels only. Level-gated, not a setting.
- Whether the numeric family earns its place, or whether it belongs in What Comes
  Next instead.

## Status

📝 Planned. Nothing built.
