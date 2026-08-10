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

## The win dialog has to lead *to* the share

Reported from the emulator: solving the daily word showed the win dialog over the
result card, and its only non-Home button was "New word" — which replaced the
finished daily with a practice word. The share buttons were therefore unreachable by
any route. The dialog is `barrierDismissible: false`, so there was no way past it.

On a daily puzzle the dialog now offers **Close** and **Share**. That needed a third
`WinAction`: `close` means "dismiss and stay here", which `home` cannot express. Only
dialogs given a `closeLabel` can return it, so the other fourteen games still see
just home/next and their `if (next) … else home` handling stays correct — there is a
test for that specifically. The lose dialog got the same treatment, since a failed
day is just as shareable.

**Two follow-up bugs, both found on the device.**

*The share sheet threw.* `MissingPluginException(No implementation found for method
share ...)`. Native plugin registration is generated at build time, so an app
hot-reloaded after `flutter pub add share_plus` has the Dart half of the plugin and
not the native half — a full rebuild fixes it. But it also showed that a failed share
put a stack trace where the player expected their score, so `_shareResult` now falls
back to the clipboard and says so. On a device with nothing registered to receive a
share, that fallback is the difference between a broken button and a working one.

*Why the tests appeared to hang.* Worth reading before adding a test here, because it
cost most of an afternoon and looked like several different problems:

- **A cold asset read inside `testWidgets` never finishes.** `testWidgets` runs its
  body in a fake-async zone, so the real I/O behind `rootBundle.loadString` never
  progresses. Every test that seemed to work was riding on a static cache warmed by
  an earlier plain `test()` in the same run, which is why the failure looked random
  and file-dependent. `setUpAll` runs outside that zone — warm the word list there.
- **`pumpAndSettle` never settles** while an indeterminate `CircularProgressIndicator`
  or the win dialog is on screen, so it fails by timeout rather than by assertion.
  Bounded `pump(Duration)` loops instead.
- **`debugPrint` is buffered per test** and never flushed for a test that doesn't
  complete, so prints say nothing about a hang. Split the flow into small tests and
  let the hang isolate itself.

With those understood, the end-to-end path *is* covered in
`test/wordle_daily_test.dart`: solve today's word, assert the dialog offers Share and
not "New word", dismiss, and assert both share buttons are `hitTestable`. One honest
limit remains — on a Windows test host `share_plus` resolves to a Dart implementation
backed by url_launcher, so the Android `MissingPluginException` cannot be reproduced
there; the test asserts the platform-independent guarantee (tapping Share never
surfaces an exception) and the clipboard fallback is verified on the device.

## Status

✅ Shipped. Tested: same date → same word regardless of time of day; consecutive
days are not alphabetically ordered; puzzle numbers advance by one a day; the shared
grid contains no letters outside the title; a finished day is remembered for that
day only; and the result card offers both share routes, with the clipboard channel
mocked so the assertion tests the app rather than the test harness.
