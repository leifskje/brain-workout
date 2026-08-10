# Word of the day

Asked for so players can compare with friends — *"I beat today's word in 3 tries"*.

## No server, and none needed

The word is a **pure function of the local calendar date**, so every player of a
language gets the same word with nothing to host and no network call. That keeps the
app's no-accounts, nothing-leaves-the-device stance intact while still being a
shared daily event.

Two details that matter more than they look:

- **The index is scrambled with an explicit integer hash, not `Random`.** Walking
  the answer list in date order would hand out alphabetically adjacent words on
  consecutive days (ABACK, ABASE, ABATE…). And `Random`'s algorithm is not a
  specified part of Dart, so seeding it would risk two app versions disagreeing
  about today's word — which is the one thing sharing depends on.
- **Local date, not UTC.** Today's word changes at the player's midnight.

Puzzle numbers count days from `dailyEpoch` (2026-01-01 = #1) and are quoted in the
shared text so two people can confirm they played the same puzzle.

## The shared grid

`dailyShareText` builds the familiar coloured-square grid. **Colours only — never
the word and never the letters**, which is the whole point of the format: someone
who hasn't played yet can see how you did without having it spoiled. A failed day
is `X/6` rather than `6/6`.

Both share routes ship, as chosen:

- **Share sheet** (`share_plus`) — what most people expect; goes straight to
  WhatsApp or SMS.
- **Copy to clipboard** — always works, needs no other app to cooperate, and is
  the more predictable option for anyone who finds the sheet confusing.

## Daily vs practice

Opening the game starts today's word. Once it is finished the board is replaced by a
result card — grid, share buttons, and "come back tomorrow" — rather than the board
being restored, because the stored result deliberately keeps only the colours.

**Practice words** are still available from the card and the header. They are random,
unrecorded and not shareable: a practice word is nobody else's puzzle, so a grid
from one would mean nothing to the person receiving it.

Today's result is stored keyed on the **puzzle number**, not a date string, so
yesterday's result can never be mistaken for today's.

## Notes

- If the shipped word list ever changes, so do the historical daily words. Nothing
  depends on the past, but don't expect puzzle #12 to be reproducible across a word
  list edit.
- Norwegian and English have independent daily words, since the lists differ.

## Status

✅ Shipped. Tested: same date → same word regardless of time of day; consecutive
days are not alphabetically ordered; puzzle numbers advance by one a day; the shared
grid contains no letters outside the title; a finished day is remembered for that
day only; and the result card offers both share routes, with the clipboard channel
mocked so the assertion tests the app rather than the test harness.
