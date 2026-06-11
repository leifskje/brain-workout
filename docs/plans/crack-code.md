# Crack the Code (Knekk koden)

Mastermind with digits: guess the secret code; after each guess, clue dots
show how many digits are right-and-in-place (green) and right-but-misplaced
(amber). Win before the guesses run out. Fills the *deduction* gap in the
catalog (logic category).

## Design

- **Codes never repeat a digit** — keeps deduction gentle, and the digit pad
  disables already-used digits so guesses can't repeat either.
- Difficulty: length 3 → 5, digit range 1–5 → 1–8, 8 → 10 guesses.
- Seeded per level. Stars by guesses used (≤ max−4 → 3★, ≤ max−2 → 2★).
- Lose dialog reveals the code; history list shows newest guess at the bottom
  with digit chips + dot clues.

## Status

✅ Shipped. Tested: code validity/distinctness/determinism + scoring
(self-guess = all exact; rotation = all present) for levels 1–30, plus a
widget test that enters the code on the pad and wins.
