# Difficulty choice

Letting a player pick how hard a game is, instead of deriving it entirely from
the level number.

## Why this is being reopened

There was a documented decision *against* it, in [backlog.md](backlog.md) under
Memory Match triples:

> **Level-gated, not a setting.** A toggle asks this audience to self-assess
> difficulty, which they will not do, and the level ladder is already the
> difficulty dial.

That argument is still sound about self-assessment. What it does not cover is the
evidence that arrived from the only two people actually playing the app:

- **The owner** is at Arrow Escape ~100 and Word Search 26, and avoids the word
  games — "I'm at a level where I find them too hard", specifically once the
  hints and the category disappear. He is dyslexic; the word-game hint button
  exists because he asked for it.
- **His mother** — the player this app was built for — plays a commercial arrow
  puzzle on its *extreme* setting and enjoys it there.

One ladder cannot serve both. The two of them want opposite things in different
games, and neither is failing to self-assess: they each know exactly what they
want.

## The actual diagnosis

**Difficulty and progress are the same number.** In Word Search, "level 26" means
both *how hard the board is* and *how far I have got*. So the only way to an
easier board is to visibly go backwards, and nobody wants to do that to their own
progress. The level picker already lets you replay any unlocked level — Word
Search 20 with the word list visible is two taps away today — but it reads as
regression, not as a choice, so it goes unused.

Separating the two is the whole feature.

## Shape

Two ends, one mechanism, and the existing hint bargain is the precedent:

> A hint costs a star, never a heart. The level stays finishable and simply
> cannot earn 3 stars.

- **Easier — an assist.** Give back the thing the level took away, and cap that
  level at 2 stars. Word Search: show the word list. Memory Match: pairs instead
  of triples. Mini Sudoku: mark a wrong entry. The level number does not move, so
  progress is untouched and the star record stays honest about the help taken.
- **Harder — a challenge.** Fewer hearts, up to a one-heart run. Local, no new
  content, and it is what the mother's "extreme" amounts to.

**Do not build the ad-gated continue** she also described. This app sends nothing
anywhere, which [backlog.md](backlog.md) protects deliberately against even a
crash SDK; an ad SDK is a tracking SDK, and it would mean an advertising ID, a
privacy policy and a Play data-safety declaration. Gating a stuck elderly player
behind a video is also the last thing this app should do. The ko-fi link is the
honest version. Take the one-heart tension, leave the advert.

## Build one game first

Word Search. It is the game the owner avoids, the word list is the cleanest thing
to hand back, and the hint code there was just touched. **Play it before rolling
the pattern into a second game** — five games retuned against an untested idea is
how this goes wrong.

The question only playing it can answer: is an assist **per-level** (chosen each
time you start one) or **sticky** (on until turned off)? Sticky is kinder for this
audience and riskier for the star record. Best guess is per-level, chosen on the
level screen, but do not decide it on paper.

## Related, from the same conversation

- **"Among the 5% quickest"**, which she also liked, needs a server and therefore
  everyone's times leaving their phone. The local version that keeps the feeling:
  compare against *your own* history — "faster than 8 of your last 10". Times and
  personal bests are already recorded. Obey the stats-screen rule: achievements
  only, never shortfalls. "You were in your slowest 20%" must never appear.
- **Timing the arrow games.** Both are deliberately untimed, and a source test
  asserts that list, because "a clock argues against sitting and thinking". But
  the principle at the top of `CLAUDE.md` already allows this: *recording is
  always allowed; displaying during play is opt-in; penalising is never.* Record
  the time, show it only on the win dialog. Nothing ticks while she thinks and
  there is still a number to beat. Changing that list is a deliberate decision,
  not a slip — update the test with it.

## Status

📝 Planned. Nothing built. Design is settled enough to start with Word Search;
everything past that waits on playing it.
