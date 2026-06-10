# Word Search (Ordleting)

Find hidden words in a letter grid — the most familiar puzzle for the target
audience. Drag across the letters (any straight line, either direction) to
mark a word; found words tint and get crossed off the list below the grid.

## Approach (guaranteed findable — placement by construction)

- **Curated word pools** embedded in the model (`wordSearchWords`): ~100
  familiar, everyday nouns per language (en + nb), 3–8 letters, uppercase,
  Norwegian incl. ÆØÅ. The Wordle asset lists were rejected — they are
  5-letter-only valid-guess dictionaries full of obscure words.
- **Forward-reading placements only** (right, down, down-right; up-right from
  level 10) — no word has to be read backwards, but a *selection* may be
  dragged in either direction.
- **Crossings are a difficulty step:** below level 8 words never share a cell
  (fully separate words are much easier to spot — tested); from level 8 words
  may cross where letters match.
- Generator places all target words first (crossings allowed where letters
  match), then fills empty cells with random letters from the language's
  alphabet → every word findable by construction. Seeded per
  (level, language) with fixed language salts → retry-stable.
- Difficulty: grid 6×6→9×9, 4→7 words, more directions.

## Status

✅ Shipped. Word list follows the app language (en/nb). Stars by wrong
selections (≤1 → 3★, ≤4 → 2★). Tested: levels 1–30 × both languages — word
count, every placement spells its word, selection matching, determinism
(`test/widget_test.dart`).
