# Compound Words (Sammensatte ord)

Find the word that joins two others. Given `sun + ___` and `___ + pot`, the
answer is `FLOWER`: *sunflower* and *flowerpot*. Norwegian: `barne + ___` and
`___ + bord` → `HAGE`, giving *barnehage* and *hagebord*.

Whether a given pair has an answer is a property of the lexicon, so the puzzles
are mined from the word lists rather than authored — which is where all the
difficulty is (see *Generation*).

Category: `words`. Norwegian is compound-heavy (`sammensatte ord`), so the
mechanic is more natural in `nb` than in `en` — an unusual and welcome direction
for this app.

## Why the bridge form, not build-or-split

Three candidate mechanics:

- **Split** — given a long compound, find the split points. Too easy for a
  literate player; the answer is visible.
- **Build** — given 6–8 parts, form as many compounds as possible. Open-ended,
  so scoring and "are you done" are both fuzzy.
- **Bridge** — given `A + ?` and `? + B`, find the middle word. ✅ One clean
  answer, trivially checkable, generates from an index, and scales in difficulty
  by how common the parts are.

Go with bridge.

## ⛔ Blocked: the shipped word lists cannot support this

**Measured before building, and the answer is no.** The plan assumed the corpus
only needed mining. It doesn't work, for two compounding reasons:

**1. The lists are full-form, so decomposition finds suffixes, not compounds.**
Sampling actual output of *W = A + B* with both parts in the lexicon:

```
nb:  ADVARSEL -> ADVAR + SEL     (a warning is not a "warn-seal")
     AGENTENE -> AGENT + ENE     (-ene is a plural suffix, not a word)
     AKSELEN  -> AKSEL + EN      (inflection)
     ROMANER  -> ROMAN + ER      (inflection)
en:  ABASHED  -> ABASH + ED      ABATING  -> ABAT + ING
     ABHORRED -> ABHOR + RED     ABALONE  -> ABAL + ONE
```

Roughly 15–20% of hits are real compounds (`ORDBOK`, `ENEBARN`, `ALDERDOM` do
come through). This is the false-positive problem the plan anticipated, but the
rate is not "needs tuning" — it is *most of the output*.

**2. The 3–8 letter filter excludes the compounds a player would recognize.**
`nb_all.txt` is 3–8 letters by construction (see the credits strings). But
`barnehage` is 9, `fotballbane` 11, `arbeidsplass` 12. The corpus keeps the
inflections that merely *look* like compounds and drops the real ones.

Together these gut the yield. Bridge words found in Norwegian:

| min part length | tier ≤2 (common) | tier ≤3 | any tier |
|---|---|---|---|
| 3 | 97 | 688 | 3845 |
| 4 | **9** | 114 | 1166 |

Nine bridge words at the quality bar this game needs is not a difficulty curve.
And the unfiltered thousands are mostly the garbage above, so no amount of pool
size helps.

## What would unblock it

One of these, both real work rather than tuning:

- **(a) Re-derive a lemma list with no length cap** from Norsk ordbank upstream —
  lemmas only (so suffixes stop masquerading as parts) and words past 8 letters
  (so compounds exist at all). The raw source is not in this repo. Norwegian also
  needs **linking morphemes** (fugemorfem) at the seam: `arbeid`+**s**+`plass`,
  `barn`+**e**+`hage`.
- **(b) Hand-author a bank** of a few hundred bridge triples per language. Content
  work, and the Norwegian half needs a native speaker.

(a) is shared with the Word Scramble inflection gap already in `backlog.md`, so it
buys two fixes. (b) ships sooner and is more reliably *fun*, because a human picks
the words.

The probe that produced the numbers above is not checked in — it was throwaway.
Re-derive it from this doc if (a) gets attempted; the measurement is a few dozen
lines over `assets/words/*_all.txt`.

## Generation — kept for whoever unblocks this

Everything below assumes a corpus that doesn't exist yet (see the blocker above).

`kanin` is not `kan` + `in`. Naive decomposition produces mostly garbage, and a
wrong puzzle is worse here than a hard one. Constraints:

- Both parts ≥ 3 letters (4 is probably better; tune it).
- Both parts must be **common tier**, not just present in the lexicon.
- Parts come from **lemmas**, not inflected forms. `backlog.md` already flags
  that `nb_all.txt` holds full forms — the Ordbank lemma list is the right
  source for parts, and that work is shared with the Word Scramble fix.
- Prefer 2-part splits and the split with the most common parts.

Then: **decompose offline, review, ship a bank.** `tool/build_compounds.dart`
emits `assets/words/nb_compounds.txt` (and `en_`), a human skims it, and the
runtime only reads the finished bank. Same shape as the existing curated word
assets — do not decompose at runtime, and do not trust the tool's output
unreviewed.

From the bank, index each part *P* by {compounds starting with P} and {compounds
ending with P}. A bridge puzzle exists wherever both sets are non-empty.

## Difficulty

- Level bands by **tier of the parts**: level 1 uses the most common parts,
  level 30 the rarest that are still fair.
- **Ambiguity** as the second knob: prefer puzzles with exactly one valid bridge
  early, and allow several valid answers (accept any) later — more candidates
  means a wider search for the player even when the parts are easy.
- Feed it into `tool/analyze_level_curves.dart` so it can't silently plateau the
  way eleven of twelve games once did.

## Blocked on, and shared with, the Norwegian word-list gap

`backlog.md` records that **there is no offensive-word filter for Norwegian** —
English puzzle answers are screened against SCOWL, Norwegian is not. Compounding
makes this strictly worse than it is for Wordle or Scramble: joining two innocent
parts can produce a crude word, so the risk is generated rather than merely
present in a list. A native speaker needs to write that list before this ships in
Norwegian. Same blocker, higher stakes.

## Build steps

1. `tool/build_compounds.dart` — decompose, constrain, emit the bank. Review the
   output by hand; iterate the constraints until the false-positive rate is low.
2. `lib/games/compound_words/compound_words_models.dart` — pure Dart: load bank,
   build the part index, seeded `generate(level)`, answer validation.
3. Unit tests: every level 1–30 has at least one valid bridge and the stated
   answer really forms two compounds; determinism; tier bands hold.
4. `compound_words_screen.dart`, l10n in both `.arb` files, catalog entry.

## Status

⛔ **Blocked on data, not on effort** — the shipped 3–8 letter full-form word
lists cannot produce enough real compounds (9 bridge words in Norwegian at the
quality bar). Needs either a re-derived uncapped lemma list or a hand-authored
bank; see *What would unblock it*.

Also still true, and a second prerequisite for `nb`: **no offensive-word filter
exists for Norwegian**, and compounding makes that worse than it is for Wordle or
Scramble, because joining two innocent parts can *generate* a crude word rather
than merely failing to filter one from a list.
