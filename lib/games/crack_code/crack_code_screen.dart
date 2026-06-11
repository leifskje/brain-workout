import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'crack_code_models.dart';

/// Playable Crack the Code: compose a guess on the digit pad and submit;
/// each guess earns clue dots — green for right-digit-right-spot, amber for
/// right-digit-wrong-spot. Win before the guesses run out.
class CrackCodeScreen extends StatefulWidget {
  const CrackCodeScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<CrackCodeScreen> createState() => _CrackCodeScreenState();
}

class _CrackCodeScreenState extends State<CrackCodeScreen> {
  static const _gameId = 'crack_code';
  static const _accent = Color(0xFF607D8B);
  static const _exactColor = Color(0xFF43A047);
  static const _presentColor = Color(0xFFF9A825);

  int _level = 1;
  late CrackCodeGame _game;
  final List<int> _input = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpCrackCode,
            accent: _accent);
      }
    });
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _game = CrackCodeGame.generate(level);
      _input.clear();
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onDigit(int d) {
    if (_busy ||
        _input.length >= _game.code.length ||
        _input.contains(d)) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _input.add(d));
  }

  void _onBackspace() {
    if (_busy || _input.isEmpty) return;
    setState(() => _input.removeLast());
  }

  void _onSubmit() {
    if (_busy || _input.length != _game.code.length) return;
    HapticFeedback.lightImpact();
    setState(() {
      _game.submit(_input);
      _input.clear();
    });
    if (_game.isWon) {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 300), _showWin);
    } else if (_game.isLost) {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 300), _showLose);
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final used = _game.guesses.length;
    final stars = used <= _game.maxGuesses - 4
        ? 3
        : (used <= _game.maxGuesses - 2 ? 2 : 1);
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
    final t = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.outOfGuesses),
        content: Text(t.crackCodeWas(_game.code.join(' '))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(t.home),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              Navigator.pop(dialogContext);
              _restart();
            },
            child: Text(t.tryAgain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cfg = crackCodeConfigForLevel(_level);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: t.levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () => showHowToPlay(context,
                    body: t.helpCrackCode, accent: _accent)),
            const SizedBox(height: 6),
            Text(
              t.crackGuessOf(
                  (_game.guesses.length + 1).clamp(1, _game.maxGuesses),
                  _game.maxGuesses),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54),
            ),
            Expanded(child: _buildHistory()),
            _buildInputRow(cfg),
            const SizedBox(height: 10),
            _buildPad(cfg),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
              child: Text(
                t.crackCodeHint,
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

  Widget _digitChip(String text,
      {double size = 44, Color? bg, Color? fg, Color? border}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        border: Border.all(color: border ?? _accent, width: 2),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            color: fg ?? Colors.black87),
      ),
    );
  }

  Widget _buildHistory() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      reverse: true,
      itemCount: _game.guesses.length,
      itemBuilder: (context, index) {
        final i = _game.guesses.length - 1 - index;
        final guess = _game.guesses[i];
        final result = _game.results[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in guess) ...[
                _digitChip('$d', border: Colors.black26),
                const SizedBox(width: 6),
              ],
              const SizedBox(width: 12),
              for (var e = 0; e < result.exact; e++)
                const Icon(Icons.circle, size: 18, color: _exactColor),
              for (var p = 0; p < result.present; p++)
                const Icon(Icons.circle, size: 18, color: _presentColor),
              for (var m = 0;
                  m < guess.length - result.exact - result.present;
                  m++)
                const Icon(Icons.circle_outlined,
                    size: 18, color: Colors.black26),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputRow(CrackCodeConfig cfg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var s = 0; s < cfg.length; s++) ...[
          _digitChip(
            s < _input.length ? '${_input[s]}' : '',
            size: 52,
            bg: s < _input.length
                ? _accent.withValues(alpha: 0.12)
                : Colors.white,
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          onPressed: _onBackspace,
          icon: const Icon(Icons.backspace_outlined),
          iconSize: 28,
          color: _accent,
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          onPressed:
              _input.length == cfg.length && !_busy ? _onSubmit : null,
          child: const Icon(Icons.check_rounded, size: 26),
        ),
      ],
    );
  }

  Widget _buildPad(CrackCodeConfig cfg) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var d = 1; d <= cfg.symbols; d++)
          GestureDetector(
            key: ValueKey('cc_pad_$d'),
            onTap: () => _onDigit(d),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _input.contains(d) ? 0.3 : 1,
              child: _digitChip('$d',
                  size: 54, bg: Colors.white, fg: _accent),
            ),
          ),
      ],
    );
  }
}
