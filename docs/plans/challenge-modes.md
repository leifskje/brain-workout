# Challenge modes — thoughts, not decisions (30 Sep 2026)

The pressure rule was rewritten on 30 Sep (see the top of `CLAUDE.md`):
**pressure is a choice, never the default, and never costs progress.** It
happened because the player this app was built for thrives on "beat my own
time" and on one-heart runs. Everything below follows from the new rule, but
**none of it is decided**. These are notes to come back to and iterate on, and
each needs the owner's view, ideally after watching someone play.

## Ideas, smallest first

1. **Time and best time on the win dialog, by default, in every game** —
   including the arrow games. Nothing ticks during play unless the clock is
   switched on in Settings. Time is already recorded in six games, and the
   "new personal best" badge exists. The number to beat is simply always in
   view afterwards.
   - *Question:* does a time on the win dialog of an arrow game invite hurrying
     next time, even with no clock on screen? The owner's mother would enjoy
     it; would a player who wants to sit and think feel judged?
   - *Cost:* a source test asserts the arrow games are untimed, so it would
     have to change deliberately.
2. **One-heart run**: the "Harder" half of
   [difficulty-choice.md](difficulty-choice.md), already designed. Chosen per
   level, on the level screen. It fits the arrow games, Minesweeper and
   anything else with hearts.
3. **Beat-your-best countdown**: an opt-in clock set to your own best time for
   that level (or for that game's level band). Running out ends the challenge,
   not the level. You can keep playing, just without the challenge badge.
   - *Question:* is a countdown ever kind, even opt-in? The rule allows it; the
     taste test is watching someone use it.
4. **Local "faster than N of your last 10"** after a timed game. It's already in
   difficulty-choice.md. Achievements only: never "your slowest 20%" (the
   stats-screen rule).
5. **A challenge badge on the level picker**, next to the stars, so a
   one-heart or beat-the-clock clear is visible and not just remembered.

## Guard-rails any version must keep

- The default path stays untimed and forgiving. Challenges are always one
  deliberate tap away, never switched on for you.
- Failing a challenge never costs progress: the level stays cleared, and stars,
  unlocks and streaks are untouched.
- Only your own history. No leaderboards: they need a server and everyone's
  data, and nothing in this app leaves the phone.
- The clock counts foreground time only, and persists with a resumed board.
- The store listing says "No timers" and "No countdown clock"
  ([store-listing.md](store-listing.md)). If a challenge mode ships, reword
  that before the release that carries it, to something like "No clocks unless
  you want one". Don't publish the listing without asking.

## Games the new rule opens

These were ruled out or awkward under "no time pressure". Each still needs an
untimed default, or to be framed entirely as an opt-in challenge. They are
quick-plan candidates for [new-games.md](new-games.md), not commitments.

- **Speed game (flash and answer)**: the ACTIVE trial's speed-of-processing
  training, which has the strongest long-term evidence in the field. The
  shrinking flash *is* the game, and answering stays untimed.
- **Schulte table**: tap 1–25, scattered on a grid, in order. A classic
  attention drill, scored purely against your own best time. It has no
  meaningful untimed version, so it would be a challenge-only game.
- **Colour–word (Stroop)**: say the ink colour, not the word. A classic
  executive-function test. Untimed it is trivial, so it's challenge-only too.
- **Numbers round** (reach a target from six numbers using + − × ÷). Good
  untimed, with an optional clock; a solver proves every target is reachable
  and counts how many ways there are.
- **Letter grid** (find words in a 4×4 grid of letters; not "Boggle", which is
  a trademark). Untimed with a word-count target, or a 3-minute opt-in round.
  Reuses the word lists.

Challenge-only games are a real shift: they would be the first where time *is*
the score. The rule allows that, as long as they're opt-in by being a separate
game you choose. Decide that deliberately.
