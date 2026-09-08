import 'package:flutter/material.dart';

import '../games/games_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/game_definition.dart';
import '../services/level_timer.dart';
import '../services/progress_store.dart';

/// What the player has done so far.
///
/// **Only achievements, never shortfalls.** No "3 of 60 levels", no completion
/// bars, no per-game percentage. A screen that tells a retired teacher she has
/// finished 5% of a game is a scoreboard of failure, and this is the screen she
/// would visit precisely when she wants to feel she is getting somewhere. Games
/// with nothing recorded are simply absent rather than shown at zero.
///
/// Reads existing local save data and nothing else. Nothing about this leaves
/// the phone, which is why the app carries no analytics at all — see the
/// personal-bests note in ProgressStore.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final store = ProgressStore.instance;

    final played = [
      for (final game in gamesCatalog)
        if (store.levelsCleared(game.id) > 0) game
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.statistics)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(t.statsHeader,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _OverallCard(
            daysPlayed: store.daysPlayed,
            streak: store.currentStreak,
            bestStreak: store.bestStreak,
            totalStars: [
              for (final game in gamesCatalog) store.totalStars(game.id)
            ].fold<int>(0, (a, b) => a + b),
          ),
          const SizedBox(height: 16),
          if (played.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(t.statsNothingYet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, color: Colors.black54)),
            ),
          for (final game in played) ...[
            _GameCard(game: game),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({
    required this.daysPlayed,
    required this.streak,
    required this.bestStreak,
    required this.totalStars,
  });

  final int daysPlayed;
  final int streak;
  final int bestStreak;
  final int totalStars;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 30, color: Color(0xFFF9A825)),
              const SizedBox(width: 8),
              // Expanded so the line wraps instead of overflowing: at the app's
              // 1.3x text ceiling "5 stars in all" beside a 30dp icon already
              // ran 16px past the edge on a 360dp phone.
              Expanded(
                child: Text(t.statsTotalStars(totalStars),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(t.statsDaysPlayed(daysPlayed),
              style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            '${t.statsStreakNow(streak)}   ·   ${t.bestStreak(bestStreak)}',
            style: const TextStyle(fontSize: 17, color: Colors.black54),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final GameDefinition game;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final store = ProgressStore.instance;
    final cleared = store.levelsCleared(game.id);
    final stars = store.totalStars(game.id);
    final fastest = store.fastestLevel(game.id);

    return Container(
      key: ValueKey('stats_${game.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(game.title(t),
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            '${t.statsLevelsCleared(cleared)}   ·   ${t.statsStars(stars)}',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            softWrap: true,
          ),
          if (fastest != null) ...[
            const SizedBox(height: 4),
            Text(
              t.statsFastest(fastest.$1,
                  formatLevelTime(Duration(seconds: fastest.$2))),
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}
