import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../games/games_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/game_definition.dart';
import '../services/app_locale.dart';
import '../services/progress_store.dart';
import '../services/app_info.dart';
import '../services/app_update.dart';
import 'coming_soon_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'level_select_screen.dart';

const String _supportUrl = 'https://ko-fi.com/loffen';

final ButtonStyle _footerButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black45,
  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
);

/// Startup screen: pick a brain-training game to play.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame, not during it: the check is a platform call and
    // Play's immediate flow takes over the screen, which it cannot do while the
    // first frame is still being built. Every failure path is silent by design.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdate.promptIfAvailable();
    });
  }

  /// Opens [game]. With [direct], level games skip the level picker and jump
  /// straight into their current level (used by Continue / Play next).
  Future<void> _open(GameDefinition game, {bool direct = false}) async {
    if (game.available) ProgressStore.instance.recordOpened(game.id);
    final WidgetBuilder builder;
    if (game.screenBuilder != null) {
      builder = game.screenBuilder!; // direct-entry game (e.g. Wordle)
    } else if (game.hasLevels) {
      builder = direct
          ? (_) =>
              game.levelBuilder!(ProgressStore.instance.highestLevel(game.id))
          : (_) => LevelSelectScreen(game: game);
    } else {
      final title = game.title(AppLocalizations.of(context));
      builder = (_) => ComingSoonScreen(title: title);
    }
    await Navigator.push(context, MaterialPageRoute(builder: builder));
    // Returning from a game may have advanced progress — refresh the cards.
    if (mounted) setState(() {});
  }

  /// The most recently opened playable game, or null before the first play.
  GameDefinition? get _lastPlayed {
    GameDefinition? best;
    var bestTime = 0;
    for (final game in gamesCatalog) {
      if (!game.available) continue;
      final t = ProgressStore.instance.lastOpened(game.id);
      if (t > bestTime) {
        bestTime = t;
        best = game;
      }
    }
    return best;
  }

  /// The game "Play next" suggests: rotates daily and advances with each
  /// completed level, so a workout naturally varies.
  GameDefinition get _suggested {
    final games = [for (final g in gamesCatalog) if (g.available) g];
    final day = DateTime.now().difference(DateTime(2026)).inDays;
    return games[(day + ProgressStore.instance.dailyCount) % games.length];
  }

  Future<void> _support() async {
    final ok = await launchUrl(
      Uri.parse(_supportUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).supportPageError)),
      );
    }
  }

  /// Opens the tester's mail app with the diagnostics already filled in.
  ///
  /// Testers are non-developers; a blank compose window with no version in it
  /// produces reports we cannot act on. If no mail app answers the intent the
  /// whole thing goes to the clipboard instead, so the report is never lost.
  Future<void> _sendFeedback() async {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final uri = AppInfo.instance.feedbackUri(
      subject: t.feedbackSubject,
      body: t.feedbackIntro,
      locale: locale,
    );

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false; // no mail app registered: fall through to the clipboard
    }
    if (opened || !mounted) return;

    await Clipboard.setData(ClipboardData(
      text: '$feedbackEmail\n\n${t.feedbackIntro}\n\n'
          '${AppInfo.instance.diagnostics(locale: locale)}',
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.feedbackNoMailApp)),
    );
  }

  Widget _buildDailyCard() {
    final t = AppLocalizations.of(context);
    final store = ProgressStore.instance;
    final count = store.dailyCount;
    final goal = ProgressStore.dailyGoal;
    final complete = store.dailyWorkoutComplete;
    final streak = store.currentStreak;

    // The daily card is the way in to the stats screen: it already shows the
    // streak and today's progress, so "how am I doing" is what a player is
    // asking when they touch it, and routing from here costs almost no vertical
    // space (a header icon and a footer button were each tried and pushed a game
    // card off a 360dp screen at 1.3x text scale).
    //
    // But it needs a *visible* affordance, which the first version had none of —
    // no label, no chevron, not even a ripple, because it was a GestureDetector.
    // The owner went looking for the stats screen on a device and could not find
    // it, which is the whole feature lost to save one grid row.
    // "Elderly-friendly" means obvious affordances before it means anything else.
    final radius = BorderRadius.circular(20);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Material(
        color: complete ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: radius,
        child: InkWell(
          key: const ValueKey('home_stats'),
          borderRadius: radius,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatsScreen()),
          ).then((_) {
            if (mounted) setState(() {});
          }),
          child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: complete ? const Color(0xFF66BB6A) : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(streak > 0 ? '🔥' : '🧠',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  streak > 0
                      ? t.streakDays(streak)
                      : t.startStreakToday,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (store.bestStreak > 1)
                Text(t.bestStreak(store.bestStreak),
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  complete
                      ? t.workoutComplete
                      : t.workoutProgress(count.clamp(0, goal), goal),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: complete
                        ? const Color(0xFF2E7D32)
                        : Colors.black87,
                  ),
                ),
              ),
              for (var i = 0; i < goal; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    i < count
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 24,
                    color: i < count
                        ? const Color(0xFF66BB6A)
                        : Colors.black26,
                  ),
                ),
            ],
          ),
          if (!complete) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _open(_suggested, direct: true),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(t.playNext(_suggested.title(t))),
                style: FilledButton.styleFrom(
                  backgroundColor: _suggested.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          // The visible affordance. A label, not just a chevron: this audience
          // does not read a lone arrow as "there is a screen behind this".
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                t.statistics,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: complete
                      ? const Color(0xFF2E7D32)
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 22,
                  color: complete
                      ? const Color(0xFF2E7D32)
                      : Theme.of(context).colorScheme.primary),
            ],
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  /// Wide "Continue" card: jumps straight back into the most recently played
  /// game. Hidden until something has been played once.
  Widget _buildContinueCard() {
    final game = _lastPlayed;
    if (game == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final store = ProgressStore.instance;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _open(game, direct: true),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: game.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(game.icon, size: 28, color: game.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.continueLabel,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black45),
                      ),
                      Text(
                        game.hasLevels
                            ? t.gameAtLevel(
                                game.title(t), store.highestLevel(game.id))
                            : game.title(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_fill_rounded,
                    size: 34, color: game.color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Globe menu: follow the phone language, or force English / Norwegian.
  Widget _buildLanguageMenu() {
    final t = AppLocalizations.of(context);
    final current = ProgressStore.instance.appLanguageId ?? 'system';
    return PopupMenuButton<String>(
      tooltip: t.language,
      initialValue: current,
      icon: const Icon(Icons.language_rounded,
          size: 28, color: Colors.black45),
      onSelected: (id) {
        final language = id == 'system' ? null : id;
        ProgressStore.instance.setAppLanguageId(language);
        appLocaleOverride.value = language == null ? null : Locale(language);
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'system', child: Text(t.languageSystem)),
        const PopupMenuItem(value: 'en', child: Text('English')),
        const PopupMenuItem(value: 'nb', child: Text('Norsk')),
      ],
    );
  }

  /// Settings, and through it the word-list attribution.
  ///
  /// Credits used to have its own header icon. Norsk ordbank is CC BY 4.0, which
  /// obliges the *app* to carry the credit, so a route to it must exist in-app —
  /// but it need not be a top-level icon, and the header only has room for two
  /// controls before the title column narrows enough to push game cards off a
  /// 360dp screen at the app's 1.3x text scale. It now lives one tap inside
  /// Settings; don't remove that route.
  Widget _buildSettingsButton() {
    return IconButton(
      key: const ValueKey('home_settings'),
      tooltip: AppLocalizations.of(context).settings,
      icon: const Icon(Icons.settings_outlined,
          size: 28, color: Colors.black45),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).appTitle,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context).homeTagline,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  _buildLanguageMenu(),
                  _buildSettingsButton(),
                ],
              ),
            ),
            _buildDailyCard(),
            _buildContinueCard(),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                // Card height has to follow the text scale. With a fixed ratio
                // the cards stayed the same height while the text grew, so at
                // the app's 1.3x ceiling the two-line subtitle was clipped
                // mid-word ("Guess the hidden wo…"). Taller cards mean fewer
                // visible at once, which is the right trade here — legibility
                // over density.
                childAspectRatio: 0.78 /
                    (MediaQuery.textScalerOf(context).scale(100) / 100)
                        .clamp(1.0, 1.3),
                children: [
                  for (final game in gamesCatalog)
                    _GameCard(game: game, onOpen: () => _open(game)),
                ],
              ),
            ),
            // Quiet footer: support, feedback, and the running version.
            // The version is here so a tester can read it out — Play defers
            // auto-updates for rarely-opened apps, so "which build are you on"
            // is a real question and used to be unanswerable.
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _support,
                        icon: const Icon(Icons.coffee_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).supportDeveloper),
                        style: _footerButtonStyle,
                      ),
                      TextButton.icon(
                        key: const ValueKey('home_send_feedback'),
                        onPressed: _sendFeedback,
                        icon: const Icon(Icons.mail_outline_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).sendFeedback),
                        style: _footerButtonStyle,
                      ),

                    ],
                  ),
                  if (AppInfo.instance.versionLabel.isNotEmpty)
                    Text(
                      AppLocalizations.of(context)
                          .appVersion(AppInfo.instance.versionLabel),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black38),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onOpen});

  final GameDefinition game;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: game.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(game.icon, size: 36, color: game.color),
                  ),
                  const SizedBox(width: 6),
                  // Scales down rather than overflowing on narrow cards /
                  // large text scales.
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: game.color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            game.category.label(t),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: game.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                game.title(t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  game.subtitle(t),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 8),
              if (game.available)
                // spaceBetween rather than a Spacer, so the level label is the
                // *only* flexible child. With both a Flexible and a Spacer they
                // shared the free space equally and "Nivå 46" was ellipsised to
                // "Niv…" — the label needs its natural width, and should shrink
                // only when there genuinely isn't room.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // scaleDown, not ellipsis: "Level 46" alongside a star count
                    // and chevron needs ~112px but only gets ~89 in a two-column
                    // card, so truncating painted it as "Level 4…" and lost the
                    // number entirely. Shrinking it a few percent keeps it
                    // readable, which matters more here than exact type size.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          game.hasLevels
                              ? t.levelN(
                                  ProgressStore.instance.highestLevel(game.id))
                              : t.play,
                          maxLines: 1,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: game.color),
                        ),
                      ),
                    ),
                    // Trimmed from 18/22 and a 4px gap: every pixel here comes
                    // straight off the level label's width.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (game.hasLevels &&
                            ProgressStore.instance.totalStars(game.id) > 0) ...[
                          const Icon(Icons.star_rounded,
                              size: 16, color: Color(0xFFF5B301)),
                          const SizedBox(width: 2),
                          Text(
                            '${ProgressStore.instance.totalStars(game.id)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54),
                          ),
                        ],
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: game.color),
                      ],
                    ),
                  ],
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t.comingSoon,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
