# Word Scramble (Bokstavsalat)

The letters of a familiar word are shuffled; tap them in the right order to
spell it. Tap a letter in the answer to put it back. A level is a short run
of 3–5 words; a wrong full word costs a heart (3 hearts, standard dialogs).
Stars by hearts lost.

## Design

- **Reuses the curated word pools** from Word Search (`wordSearchWords`,
  en + nb) — the word list follows the app language.
- Model: seeded per (level, language); the scramble is always a permutation
  that differs from the word. Difficulty: word length 3–4 → 5–8 letters,
  words per level 3 → 5.
- Auto-checks when all slots are filled; correct → brief pause → next word.

## Status

✅ Shipped. Tested: permutation/never-the-word/word-count/length/uniqueness/
determinism for levels 1–30 × both languages, plus a widget test that spells
word 1 by tapping tiles and asserts word 2 starts.
