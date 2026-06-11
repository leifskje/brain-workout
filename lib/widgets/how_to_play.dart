import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/progress_store.dart';

/// Shows the "how to play" sheet for a game: large text, one big button.
Future<void> showHowToPlay(
  BuildContext context, {
  required String body,
  required Color accent,
}) {
  final t = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
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
                  child: Icon(Icons.lightbulb_outline_rounded,
                      size: 28, color: accent),
                ),
                const SizedBox(width: 12),
                Text(
                  t.howToPlay,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: const TextStyle(
                  fontSize: 18, height: 1.45, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
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
