# Simon

Repeat the light sequence — the classic sequence-memory game, and the second
*memory* game in the catalog. Four huge colored buttons (red/green/blue/
yellow, 2×2) light up one at a time; the player repeats the sequence by
tapping. Each round replays the sequence one step longer; the level is won at
the target length.

## Design

- **Model (pure Dart):** the full target sequence is generated up front,
  seeded by level → deterministic and retry-stable. Rounds reveal prefixes.
  Never the same button three times in a row (long same-button runs read as a
  single flash). `tap()` returns step / roundComplete / won / wrong.
- **Difficulty:** target length 3 → 12 (`3 + level ~/ 2`), playback flash
  650ms → 420ms. Always 4 buttons — huge targets matter more than more
  colors for this audience.
- **Hearts:** 3. A wrong tap costs one and the *same* round replays; 0 → the
  standard out-of-hearts dialog. Stars by hearts lost (0 → 3★, ≤2 → 2★).
- **Screen:** async playback loop guarded by a token + `mounted` (no
  AnimationControllers); status line flips «Se nøye etter…» / «Din tur!»;
  taps disabled while watching. Visual flash + glow, haptics on taps.

## Status

✅ Shipped. Tested: sequence length/range/no-triples/determinism + full tap
flow for levels 1–30, and a widget test that waits out the playback timing,
repeats round 1, and asserts round 2 starts (`test/widget_test.dart`).
