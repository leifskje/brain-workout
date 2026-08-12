import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'crack_code_models.dart';

/// Playable Crack the Code: compose a guess on the digit pad and submit; each
/// guess earns two clue counts — green for right-digit-right-spot, amber for
/// right-digit-wrong-spot. Win before the guesses run out.
///
/// The clues are deliberately *counts*, never per-digit marks. Mastermind never
/// reveals which digit earned which clue, and working that out is the game; a
/// Wordle-style colouring of the chips themselves would collapse even a
/// six-digit code to about three guesses.
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
    // Local-only personal best. This is save data, not analytics: it lives in
    // SharedPreferences on the device and nothing about it is ever sent anywhere.
    final beat = ProgressStore.instance
        .recordBest(_gameId, _level, used, lowerIsBetter: true);
    final best = ProgressStore.instance.bestResult(_gameId, _level);
    showWinDialog(context,
            level: _level,
            accent: _accent,
            stars: stars,
            newRecord: beat,
            bestText: best == null
                ? null
                : AppLocalizations.of(context).bestGuesses(best))
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

  /// One clue: a coloured dot naming the kind, a numeral for how many. The
  /// numeral stays near-black on purpose — amber on white is about 2:1, far
  /// under readable contrast, so the colour carries meaning and the dot carries
  /// the colour.
  Widget _clueCount(Color color, int count, {Key? key}) {
    return Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: const TextStyle(
              fontSize: 21, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    // Long codes crowd the row: six 44dp chips plus clues overran a 360dp phone
    // even before the clues grew.
    final chipSize = _game.code.length >= 5 ? 38.0 : 44.0;
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
          // Counts rather than one dot per digit. A run of same-sized dots
          // alongside a run of digits reads as "this dot means that digit",
          // which is the one thing the clue never says — it fooled the owner
          // during testing. The divider keeps the two groups visibly apart.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in guess) ...[
                  _digitChip('$d', size: chipSize, border: Colors.black26),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 6),
                Container(
                    width: 1, height: chipSize * 0.7, color: Colors.black26),
                const SizedBox(width: 12),
                _clueCount(_exactColor, result.exact,
                    key: ValueKey('cc_exact_$i')),
                const SizedBox(width: 14),
                _clueCount(_presentColor, result.present,
                    key: ValueKey('cc_present_$i')),
              ],
            ),
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
