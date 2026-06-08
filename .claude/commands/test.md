# Analyze + test

Run the static analyzer and the unit/widget tests, then report.

Arguments: `$ARGUMENTS` — optional test name filter passed to `flutter test`
(e.g. `"solvable"` to run only matching tests).

## Steps

1. **Analyze:**
   ```
   flutter analyze
   ```
   Must end with "No issues found!". If there are issues, show them and stop —
   fix the root cause before testing.

2. **Test:**
   - No filter: `flutter test`
   - With filter: `flutter test --plain-name "$ARGUMENTS"`

3. **Report** one line per gate:

   | Gate | Result | Notes |
   |---|---|---|
   | Analyze | ✅/❌ | issue count |
   | Tests | ✅/❌ | N passed / M failed |

   On any failure, show the failing output in full.

Notes:
- Needs `JAVA_HOME` only for Android builds, not for analyze/test — these run fine
  without the emulator.
- This is the same `flutter analyze` the pre-commit hook runs, so a green `/test`
  means commits won't be blocked by the hook.
