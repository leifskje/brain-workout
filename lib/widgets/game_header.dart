import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Shared game-screen header: back button, centered "Level N" title, and a
/// restart button — tinted with the game's accent colour so each game has its
/// own identity.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    required this.accent,
    required this.onRestart,
    this.onHelp,
  });

  final String title;
  final Color accent;
  final VoidCallback onRestart;

  /// Shows a "?" button that reopens the game's how-to-play sheet.
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            iconSize: 28,
            color: accent,
            tooltip: AppLocalizations.of(context).back,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (onHelp != null)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              iconSize: 28,
              color: accent,
              tooltip: AppLocalizations.of(context).howToPlay,
              onPressed: onHelp,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            iconSize: 28,
            color: accent,
            tooltip: AppLocalizations.of(context).restartLevel,
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}
