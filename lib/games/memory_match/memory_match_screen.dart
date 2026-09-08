import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'memory_match_models.dart';

/// Playable "Memory Match": flip cards to find matching pairs. There is no lose
/// state (mismatches are part of remembering) — clear the board to win.
class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  static const _gameId = 'memory_match';
  static const _accent = Color(0xFF7E57C2);

  int _level = 1;
  late MemoryBoard _board;
  /// Cards turned over in the current attempt, up to the board's group size.
  /// A list rather than a single id because a triples board needs three.
  final List<int> _faceUpIds = [];
  int _moves = 0;
  bool _busy = false; // locked while a mismatched pair flips back

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpMemoryMatch,
            accent: _accent);
      }
    });
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _board = MemoryBoard.generate(level);
      _faceUpIds.clear();
      _moves = 0;
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onTapCard(MemoryCard card) {
    if (_busy || card.faceUp || card.matched) return;

    HapticFeedback.selectionClick();
    setState(() {
      card.faceUp = true;
      _faceUpIds.add(card.id);
    });

    // Still filling the attempt: on a triples board the first two taps decide
    // nothing, and a mismatch is only known once the third is over.
    if (_faceUpIds.length < _board.groupSize) return;

    final turned = [
      for (final id in _faceUpIds)
        _board.cards.firstWhere((c) => c.id == id)
    ];
    setState(() => _moves++);

    final matched = turned.every((c) => c.symbol == turned.first.symbol);
    if (matched) {
      HapticFeedback.lightImpact();
      setState(() {
        for (final c in turned) {
          c.matched = true;
        }
        _faceUpIds.clear();
      });
      if (_board.isSolved) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _showWin();
        });
      }
    } else {
      HapticFeedback.mediumImpact();
      _busy = true;
      // Longer on a triples board: three cards is more to take in before they
      // turn back, and the whole game is remembering what was under them.
      final linger = _board.isTriples ? 1150 : 850;
      Future.delayed(Duration(milliseconds: linger), () {
        if (!mounted) return;
        setState(() {
          for (final c in turned) {
            c.faceUp = false;
          }
          _faceUpIds.clear();
          _busy = false;
        });
      });
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    // Scored on *attempts per group*, so the thresholds carry over unchanged
    // from pairs to triples: a perfect game is one attempt per group either way.
    final groups = _board.groups;
    final stars = _moves <= (groups * 1.7).ceil()
        ? 3
        : (_moves <= (groups * 2.6).ceil() ? 2 : 1);
    ProgressStore.instance
      ..registerPlay(_gameId)
      ..recordCleared(_gameId, _level, stars);
    // Local-only personal best. This is save data, not analytics: it lives in
    // SharedPreferences on the device and nothing about it is ever sent anywhere.
    final beat = ProgressStore.instance
        .recordBest(_gameId, _level, _moves, lowerIsBetter: true);
    final best = ProgressStore.instance.bestResult(_gameId, _level);
    showWinDialog(
      context,
      level: _level,
      accent: _accent,
      stars: stars,
      message:
          AppLocalizations.of(context).clearedLevelInMoves(_level, _moves),
      newRecord: beat,
      bestText: best == null
          ? null
          : AppLocalizations.of(context).bestMoves(best),
    ).then((action) {
      if (!mounted || action == null) return;
      if (action == WinAction.next) {
        _loadLevel(_level + 1);
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final found = _board.groupsFound;
    final total = _board.groups;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: AppLocalizations.of(context).levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () => showHowToPlay(context,
                    body: AppLocalizations.of(context).helpMemoryMatch,
                    accent: _accent)),
            Text(
              _board.isTriples
                  ? t.triplesFound(found, total)
                  : t.pairsFound(found, total),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: _accent),
            ),
            // The mechanic has to be unmissable *before* the first match, not
            // inferred from it: a player who has only ever matched two of a kind
            // will keep trying to, and read the board as broken. A banner rather
            // than a line of body text for the same reason.
            if (_board.isTriples)
              Container(
                key: const ValueKey('memory_triples_banner'),
                margin: const EdgeInsets.only(top: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _accent.withValues(alpha: 0.45)),
                ),
                child: Text(
                  t.findThreeOfAKind,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: _buildBoard()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                _board.isTriples ? t.memoryMatchHintTriples : t.memoryMatchHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Size the board to a grid that fits without scrolling.
        final aspect = _board.cols / _board.rows;
        var w = constraints.maxWidth;
        var h = w / aspect;
        if (h > constraints.maxHeight) {
          h = constraints.maxHeight;
          w = h * aspect;
        }
        return SizedBox(
          width: w,
          height: h,
          child: Column(
            children: [
              for (var r = 0; r < _board.rows; r++)
                Expanded(
                  child: Row(
                    children: [
                      for (var c = 0; c < _board.cols; c++)
                        Expanded(
                          child: _buildCard(_board.cards[r * _board.cols + c]),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(MemoryCard card) {
    final up = card.faceUp || card.matched;
    return Padding(
      padding: const EdgeInsets.all(5),
      child: GestureDetector(
        // Keyed so tests can measure a *card* — a by-type finder also matches the
        // header's icon buttons, which sit earlier in the tree.
        key: ValueKey('memory-card-${card.id}'),
        onTap: () => _onTapCard(card),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: up ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 260),
          builder: (context, t, _) {
            final showFront = t > 0.5;
            final face = showFront ? _cardFront(card) : _cardBack();
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(t * math.pi),
              child: showFront
                  // Counter-rotate the front so it isn't mirrored after the flip.
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: face,
                    )
                  : face,
            );
          },
        ),
      ),
    );
  }

  Widget _cardFront(MemoryCard card) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: card.matched
            ? _accent.withValues(alpha: 0.18)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: card.matched ? _accent : Colors.black12,
          width: 2,
        ),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.6,
          heightFactor: 0.6,
          child: FittedBox(child: Text(card.symbol)),
        ),
      ),
    );
  }

  Widget _cardBack() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: const Center(
        child: FractionallySizedBox(
          widthFactor: 0.5,
          heightFactor: 0.5,
          child: FittedBox(
            child: Icon(Icons.psychology_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
