import 'package:flutter/material.dart';

/// Shared game-screen header: back button, centered "Level N" title, and a
/// restart button — tinted with the game's accent colour so each game has its
/// own identity.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    required this.accent,
    required this.onRestart,
  });

  final String title;
  final Color accent;
  final VoidCallback onRestart;

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
            tooltip: 'Back',
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            iconSize: 28,
            color: accent,
            tooltip: 'Restart level',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}
