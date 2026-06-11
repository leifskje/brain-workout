import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'what_next_models.dart';

/// Playable "What Comes Next?": spot the pattern and pick the next number.
/// Each level is a short set of questions; a wrong pick costs a heart.
class WhatNextScreen extends StatefulWidget {
  const WhatNextScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<WhatNextScreen> createState() => _WhatNextScreenState();
}

class _WhatNextScreenState extends State<WhatNextScreen> {
  static const _gameId = 'what_next';
  static const _accent = Color(0xFFEF8A3D);

  int _level = 1;
  late List<SequenceQuestion> _questions;
  late int _hearts;
  int _index = 0;
  int? _wrongValue; // option flashed red after a wrong pick
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpWhatNext,
            accent: _accent);
      }
    });
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _questions = WhatNextRound.generate(level);
      _hearts = whatNextConfigForLevel(level).hearts;
      _index = 0;
      _wrongValue = null;
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onPick(int value) {
    if (_busy) return;
    final question = _questions[_index];

    if (value == question.answer) {
      HapticFeedback.lightImpact();
      if (_index + 1 >= _questions.length) {
        _busy = true;
        _showWin();
      } else {
        setState(() {
          _index++;
          _wrongValue = null;
        });
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _wrongValue = value;
        _hearts = (_hearts - 1).clamp(0, 1 << 30);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _wrongValue = null);
      });
      if (_hearts <= 0) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 550), () {
          if (mounted) _showLose();
        });
      }
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final lost = whatNextConfigForLevel(_level).hearts - _hearts;
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
    final cfg = whatNextConfigForLevel(_level);
    final question = _questions[_index];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: AppLocalizations.of(context).levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () => showHowToPlay(context,
                    body: AppLocalizations.of(context).helpWhatNext,
                    accent: _accent)),
            _buildHearts(cfg.hearts),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)
                  .questionOf(_index + 1, _questions.length),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSequence(question),
                    const SizedBox(height: 28),
                    _buildOptions(question),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                AppLocalizations.of(context).whichComesNext,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.black.withValues(alpha: 0.6)),
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

  Widget _buildSequence(SequenceQuestion question) {
    Widget box({required Widget child, required bool isAnswer}) => Container(
          margin: const EdgeInsets.all(4),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isAnswer ? _accent.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAnswer ? _accent : Colors.black12,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        );

    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (final term in question.shown)
          box(child: _renderValue(question.kind, term), isAnswer: false),
        box(
          child: const Text(
            '?',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: _accent),
          ),
          isAnswer: true,
        ),
      ],
    );
  }

  Widget _buildOptions(SequenceQuestion question) {
    final o = question.options;
    return Column(
      children: [
        Row(children: [
          Expanded(child: _option(question, o[0])),
          Expanded(child: _option(question, o[1])),
        ]),
        Row(children: [
          Expanded(child: _option(question, o[2])),
          Expanded(child: _option(question, o[3])),
        ]),
      ],
    );
  }

  Widget _option(SequenceQuestion question, int value) {
    final wrong = value == _wrongValue;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: wrong ? const Color(0xFFE53935) : Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onPick(value),
          child: SizedBox(
            height: 64,
            child: Center(
              child: _renderValue(question.kind, value, onRed: wrong),
            ),
          ),
        ),
      ),
    );
  }

  static const List<Color> _palette = [
    Color(0xFFE53935), // red
    Color(0xFF1E88E5), // blue
    Color(0xFF43A047), // green
    Color(0xFFFB8C00), // orange
  ];

  /// Renders a value according to the question kind: a number, that many dots,
  /// a palette colour, or a rotated arrow.
  Widget _renderValue(QuestionKind kind, int value, {bool onRed = false}) {
    switch (kind) {
      case QuestionKind.number:
        return Text(
          '$value',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: onRed ? Colors.white : Colors.black87,
          ),
        );
      case QuestionKind.color:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: _palette[value], shape: BoxShape.circle),
        );
      case QuestionKind.arrow:
        return Transform.rotate(
          angle: value * (math.pi / 2),
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 34,
            color: onRed ? Colors.white : const Color(0xFF37474F),
          ),
        );
      case QuestionKind.dots:
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < value; i++)
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: onRed ? Colors.white : _accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        );
    }
  }
}
