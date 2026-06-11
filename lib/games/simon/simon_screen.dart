import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'simon_models.dart';

/// Playable Simon: four huge colored buttons light up in a sequence; repeat
/// it by tapping. A wrong tap costs a heart and the round replays.
class SimonScreen extends StatefulWidget {
  const SimonScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

enum _Phase { watching, input, busy }

class _SimonScreenState extends State<SimonScreen> {
  static const _gameId = 'simon';
  static const _accent = Color(0xFFC94B4B);
  static const _colors = [
    Color(0xFFE53935), // red
    Color(0xFF43A047), // green
    Color(0xFF1E88E5), // blue
    Color(0xFFFDD835), // yellow
  ];

  int _level = 1;
  late SimonGame _game;
  late int _hearts;
  _Phase _phase = _Phase.busy;
  int? _lit; // button currently lit (during playback or tap feedback)

  /// Invalidates in-flight playback loops on restart/navigation.
  int _playToken = 0;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || ProgressStore.instance.helpSeen(_gameId)) return;
      // First open: hold the playback so the intro sheet isn't missed.
      _playToken++;
      setState(() => _phase = _Phase.busy);
      await maybeShowHowToPlay(context,
          gameId: _gameId,
          body: AppLocalizations.of(context).helpSimon,
          accent: _accent);
      if (mounted) _playSequence();
    });
  }

  @override
  void dispose() {
    _playToken++;
    super.dispose();
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _game = SimonGame.generate(level);
      _hearts = simonConfigForLevel(level).hearts;
      _phase = _Phase.busy;
      _lit = null;
    });
    _playSequence();
  }

  void _restart() => _loadLevel(_level);

  /// Plays the current round's sequence, then hands over to the player.
  Future<void> _playSequence() async {
    final token = ++_playToken;
    final flashMs = simonConfigForLevel(_level).flashMs;
    setState(() {
      _phase = _Phase.watching;
      _lit = null;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    for (final b in _game.shown) {
      if (!mounted || token != _playToken) return;
      setState(() => _lit = b);
      await Future.delayed(Duration(milliseconds: flashMs));
      if (!mounted || token != _playToken) return;
      setState(() => _lit = null);
      await Future.delayed(Duration(milliseconds: (flashMs * 0.45).round()));
    }
    if (!mounted || token != _playToken) return;
    setState(() => _phase = _Phase.input);
  }

  Future<void> _onButtonTap(int b) async {
    if (_phase != _Phase.input) return;
    final token = _playToken;

    // Tap feedback flash.
    HapticFeedback.lightImpact();
    setState(() => _lit = b);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && token == _playToken && _lit == b) {
        setState(() => _lit = null);
      }
    });

    switch (_game.tap(b)) {
      case SimonTap.step:
        break;
      case SimonTap.roundComplete:
        setState(() => _phase = _Phase.busy);
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted || token != _playToken) return;
        _playSequence();
      case SimonTap.won:
        setState(() => _phase = _Phase.busy);
        Future.delayed(const Duration(milliseconds: 300), _showWin);
      case SimonTap.wrong:
        HapticFeedback.mediumImpact();
        setState(() {
          _phase = _Phase.busy;
          _hearts = (_hearts - 1).clamp(0, 1 << 30);
        });
        if (_hearts <= 0) {
          Future.delayed(const Duration(milliseconds: 550), () {
            if (mounted) _showLose();
          });
        } else {
          await Future.delayed(const Duration(milliseconds: 800));
          if (!mounted || token != _playToken) return;
          _playSequence(); // replay the same round
        }
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final lost = simonConfigForLevel(_level).hearts - _hearts;
    final stars = lost == 0 ? 3 : (lost <= 2 ? 2 : 1);
    ProgressStore.instance
      ..registerPlay(_gameId)
      ..recordStars(_gameId, _level, stars);
    showWinDialog(context, level: _level, accent: _accent, stars: stars)
        .then((action) {
      if (!mounted || action == null) return;
      if (action == WinAction.next) {
        _loadLevel(_level + 1);
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  void _showLose() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).outOfHearts),
        content: Text(AppLocalizations.of(context).outOfHeartsBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(AppLocalizations.of(context).home),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _restart();
            },
            child: Text(AppLocalizations.of(context).tryAgain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cfg = simonConfigForLevel(_level);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: t.levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () async {
                  _playToken++; // pause playback under the sheet
                  setState(() => _phase = _Phase.busy);
                  await showHowToPlay(context,
                      body: t.helpSimon, accent: _accent);
                  if (mounted) _playSequence(); // replay the current round
                }),
            _buildHearts(cfg.hearts),
            const SizedBox(height: 6),
            Text(
              t.simonRound(_game.round, _game.sequence.length),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              _phase == _Phase.input ? t.simonYourTurn : t.simonWatch,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: _accent),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: _buildButtons()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                t.simonHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHearts(int maxHearts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < maxHearts; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i < _hearts
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: i < _hearts ? const Color(0xFFE53935) : Colors.black26,
              size: 28,
            ),
          ),
      ],
    );
  }

  Widget _buildButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dim =
            (constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight)
                .clamp(0.0, 420.0);
        final size = (dim - 16) / 2;
        Widget button(int i) {
          final lit = _lit == i;
          final base = _colors[i];
          return GestureDetector(
            key: ValueKey('simon_btn_$i'),
            onTap: () => _onButtonTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: lit ? base : base.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(size * 0.22),
                border: Border.all(
                    color: base.withValues(alpha: 0.9), width: 3),
                boxShadow: lit
                    ? [
                        BoxShadow(
                            color: base.withValues(alpha: 0.7),
                            blurRadius: 24,
                            spreadRadius: 2)
                      ]
                    : const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              button(0),
              const SizedBox(width: 16),
              button(1),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisSize: MainAxisSize.min, children: [
              button(2),
              const SizedBox(width: 16),
              button(3),
            ]),
          ],
        );
      },
    );
  }
}
