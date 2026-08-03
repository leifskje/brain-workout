import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/progress_store.dart';

/// Shows the "how to play" sheet for a game: large text, one big button.
///
/// The sheet has to survive the app's 1.3x text scaling, a long body, and a
/// small phone all at once — Picture Logic's Norwegian help text hit all three
/// and overflowed by 38px on a real device. Two things keep that from coming
/// back, and both matter:
///
///  - **`isScrollControlled` plus an explicit cap.** Without it a modal bottom
///    sheet is limited to 9/16 of the screen and the content simply overflows;
///    there is no scrolling and no error until it paints.
///  - **The body scrolls, the button does not.** Only the text is inside the
///    scroll view, so "Got it!" can never be pushed off screen. For this
///    audience an unreachable dismiss button would be worse than clipped text.
///
/// Short help texts are unaffected: the Column still sizes to its content.
Future<void> showHowToPlay(
  BuildContext context, {
  required String body,
  required Color accent,
}) {
  final t = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // The cap has to be a real bound on the route, not just a widget inside it:
    // if the Column ends up laid out unbounded, Flexible never shrinks, the
    // button lands below the fold, and no overflow error is reported either —
    // silently unreachable, which is worse than a red banner.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 28,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded so the title wraps instead of running off the edge:
                // "Slik spiller du" at 1.3x on a 360dp phone overflowed by
                // 65px, which had nothing to do with the body length.
                Expanded(
                  child: Text(
                    t.howToPlay,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.45,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(t.gotIt),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shows the sheet once per game — on the first open ever — and remembers it.
Future<void> maybeShowHowToPlay(
  BuildContext context, {
  required String gameId,
  required String body,
  required Color accent,
}) async {
  if (ProgressStore.instance.helpSeen(gameId)) return;
  ProgressStore.instance.markHelpSeen(gameId);
  await showHowToPlay(context, body: body, accent: accent);
}
