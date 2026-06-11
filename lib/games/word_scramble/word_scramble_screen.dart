import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'word_scramble_models.dart';

/// Playable Word Scramble: tap the shuffled letters in order to spell the
/// word; tap a placed letter to put it back. A wrong full word costs a heart.
class WordScrambleScreen extends StatefulWidget {
  const WordScrambleScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends State<WordScrambleScreen> {
  static const _gameId = 'word_scramble';
  static const _accent = Color(0xFF7A9D3C);

  int _level = 1;
  String _language = 'en';
  List<ScrambleWord>? _round;
  int _wordIndex = 0;
  late int _hearts;

  /// For each answer slot, the index into the word's letter tiles (or null).
  late List<int?> _slots;
  late List<bool> _used;
  bool _busy = false;
  bool _flashWrong = false;

  ScrambleWord get _word => _round![_wordIndex];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_round != null) return;
    _language =
        Localizations.localeOf(context).languageCode == 'nb' ? 'nb' : 'en';
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpWordScramble,
            accent: _accent);
      }
    });
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _round = generateScrambleRound(level, _language);
      _wordIndex = 0;
      _hearts = wordScrambleConfigForLevel(level).hearts;
      _busy = false;
      _resetSlots();
    });
  }

  void _resetSlots() {
    _slots = List<int?>.filled(_word.word.length, null);
    _used = List<bool>.filled(_word.letters.length, false);
    _flashWrong = false;
  }

  void _restart() => _loadLevel(_level);

  void _onLetterTap(int letterIndex) {
    if (_busy || _used[letterIndex]) return;
    final slot = _slots.indexOf(null);
    if (slot == -1) return;
    HapticFeedback.lightImpact();
    setState(() {
      _slots[slot] = letterIndex;
      _used[letterIndex] = true;
    });
    if (!_slots.contains(null)) _check();
  }

  void _onSlotTap(int slot) {
    if (_busy || _slots[slot] == null) return;
    setState(() {
      _used[_slots[slot]!] = false;
      _slots[slot] = null;
      _flashWrong = false;
    });
  }

  void _check() {
    final spelled = [for (final i in _slots) _word.letters[i!]].join();
    if (spelled == _word.word) {
      HapticFeedback.lightImpact();
      _busy = true;
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        if (_wordIndex + 1 >= _round!.length) {
          _showWin();
        } else {
          setState(() {
            _wordIndex++;
            _busy = false;
            _resetSlots();
          });
        }
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _flashWrong = true;
        _hearts = (_hearts - 1).clamp(0, 1 << 30);
      });
      if (_hearts <= 0) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 550), () {
          if (mounted) _showLose();
        });
      } else {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _resetSlots();
          });
        });
      }
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final lost = wordScrambleConfigForLevel(_level).hearts - _hearts;
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
    final round = _round;
    if (round == null) return const Scaffold(body: SizedBox.shrink());
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: t.levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () => showHowToPlay(context,
                    body: t.helpWordScramble, accent: _accent)),
            _buildHearts(wordScrambleConfigForLevel(_level).hearts),
            const SizedBox(height: 6),
            Text(
              t.wordOf(_wordIndex + 1, round.length),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSlots(),
                    const SizedBox(height: 36),
                    _buildLetters(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                t.wordScrambleHint,
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

  Widget _buildSlots() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var s = 0; s < _slots.length; s++)
          GestureDetector(
            onTap: () => _onSlotTap(s),
            child: Container(
              width: 48,
              height: 56,
              decoration: BoxDecoration(
                color: _slots[s] != null
                    ? (_flashWrong
                        ? const Color(0xFFFDE3E3)
                        : _accent.withValues(alpha: 0.15))
                    : Colors.white,
                border: Border.all(
                    color: _flashWrong ? const Color(0xFFC62828) : _accent,
                    width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                _slots[s] == null ? '' : _word.letters[_slots[s]!],
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _flashWrong
                      ? const Color(0xFFC62828)
                      : Colors.black87,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLetters() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < _word.letters.length; i++)
          GestureDetector(
            key: ValueKey('ws_tile_$i'),
            onTap: () => _onLetterTap(i),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _used[i] ? 0.25 : 1,
              child: Container(
                width: 56,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _accent, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: Offset(0, 2)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _word.letters[i],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
