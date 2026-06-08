import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/progress_store.dart';
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
  int? _firstId; // first card of an in-progress pair
  int _moves = 0;
  bool _busy = false; // locked while a mismatched pair flips back

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.startLevel);
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _board = MemoryBoard.generate(level);
      _firstId = null;
      _moves = 0;
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onTapCard(MemoryCard card) {
    if (_busy || card.faceUp || card.matched) return;

    setState(() => card.faceUp = true);

    if (_firstId == null) {
      _firstId = card.id;
      return;
    }

    final first = _board.cards.firstWhere((c) => c.id == _firstId);
    setState(() => _moves++);

    if (first.symbol == card.symbol) {
      setState(() {
        first.matched = true;
        card.matched = true;
        _firstId = null;
      });
      if (_board.isSolved) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _showWin();
        });
      }
    } else {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        setState(() {
          first.faceUp = false;
          card.faceUp = false;
          _firstId = null;
          _busy = false;
        });
      });
    }
  }

  void _showWin() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Well done!'),
        content: Text('You cleared level $_level in $_moves moves.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _loadLevel(_level + 1);
            },
            child: const Text('Next level'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matched = _board.cards.where((c) => c.matched).length ~/ 2;
    final total = _board.cards.length ~/ 2;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    iconSize: 28,
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Level $_level',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    iconSize: 28,
                    tooltip: 'Restart level',
                    onPressed: _restart,
                  ),
                ],
              ),
            ),
            Text(
              'Pairs found: $matched / $total',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: _accent),
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
                'Tap two cards to find a matching pair.',
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
