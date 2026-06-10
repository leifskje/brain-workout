import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/game_definition.dart';
import '../services/progress_store.dart';

/// Shown when a game is selected: a big "Continue" at the furthest level, plus
/// a grid to replay any level already reached.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key, required this.game});

  final GameDefinition game;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Future<void> _play(int level) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => widget.game.levelBuilder!(level)),
    );
    // Progress may have advanced while playing — refresh the unlocked grid.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final game = widget.game;
    final highest = ProgressStore.instance.highestLevel(game.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(game.title(t)),
        backgroundColor: game.color.withValues(alpha: 0.18),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: game.color,
                    minimumSize: const Size.fromHeight(64),
                  ),
                  onPressed: () => _play(highest),
                  icon: const Icon(Icons.play_arrow_rounded, size: 30),
                  label: Text(
                    t.continueAtLevel(highest),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                t.replayLevel,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: highest,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final isCurrent = level == highest;
                  final earned = ProgressStore.instance.stars(game.id, level);
                  return Material(
                    color: isCurrent ? game.color : Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _play(level),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$level',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var s = 0; s < 3; s++)
                                Icon(
                                  s < earned
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 13,
                                  color: s < earned
                                      ? (isCurrent
                                          ? Colors.white
                                          : const Color(0xFFFFB300))
                                      : (isCurrent
                                          ? Colors.white38
                                          : Colors.black12),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
