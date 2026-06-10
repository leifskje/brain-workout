import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/win_dialog.dart';
import 'word_search_models.dart';

/// Playable Word Search: drag across the letters (any straight line) to mark
/// a word; found words tint and get crossed off the list. No lose state.
class WordSearchScreen extends StatefulWidget {
  const WordSearchScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  static const _gameId = 'word_search';
  static const _accent = Color(0xFFB5527D);

  int _level = 1;
  String _language = 'en';
  WordSearchBoard? _board;
  int _wrongAttempts = 0;
  bool _busy = false;

  (int, int)? _dragStart;
  List<(int, int)> _selection = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_board != null) return;
    // The word list follows the app language (needs inherited Localizations,
    // hence didChangeDependencies rather than initState).
    _language =
        Localizations.localeOf(context).languageCode == 'nb' ? 'nb' : 'en';
    _loadLevel(widget.startLevel);
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _board = WordSearchBoard.generate(level, _language);
      _wrongAttempts = 0;
      _busy = false;
      _dragStart = null;
      _selection = const [];
    });
  }

  void _restart() => _loadLevel(_level);

  /// Cells from [_dragStart] to (r,c), snapped to the nearest straight line
  /// (horizontal, vertical, or 45° diagonal).
  List<(int, int)> _lineTo(int r, int c) {
    final start = _dragStart;
    if (start == null) return const [];
    final (r0, c0) = start;
    final dr = r - r0, dc = c - c0;
    if (dr == 0 && dc == 0) return [start];
    int stepR, stepC, len;
    if (dr.abs() >= 2 * dc.abs()) {
      stepR = dr.sign;
      stepC = 0;
      len = dr.abs();
    } else if (dc.abs() >= 2 * dr.abs()) {
      stepR = 0;
      stepC = dc.sign;
      len = dc.abs();
    } else {
      stepR = dr.sign;
      stepC = dc.sign;
      len = math.max(dr.abs(), dc.abs());
    }
    final size = _board!.size;
    final cells = <(int, int)>[];
    for (var i = 0; i <= len; i++) {
      final rr = r0 + stepR * i, cc = c0 + stepC * i;
      if (rr < 0 || rr >= size || cc < 0 || cc >= size) break;
      cells.add((rr, cc));
    }
    return cells;
  }

  void _endDrag() {
    if (_busy) return;
    final cells = _selection;
    setState(() {
      _dragStart = null;
      _selection = const [];
    });
    if (cells.length < 2) return;
    final found = _board!.trySelect(cells);
    if (found != null) {
      HapticFeedback.lightImpact();
      setState(() {});
      if (_board!.isSolved) {
        _busy = true;
        Future.delayed(const Duration(milliseconds: 200), _showWin);
      }
    } else {
      _wrongAttempts++;
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final stars = _wrongAttempts <= 1 ? 3 : (_wrongAttempts <= 4 ? 2 : 1);
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final board = _board;
    if (board == null) return const Scaffold(body: SizedBox.shrink());
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: t.levelN(_level), accent: _accent, onRestart: _restart),
            const SizedBox(height: 4),
            Text(
              t.wordsFound(board.foundCount, board.words.length),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _accent),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Center(child: _buildGrid(board)),
              ),
            ),
            _buildWordList(board),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
              child: Text(
                t.wordSearchHint,
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

  Widget _buildGrid(WordSearchBoard board) {
    final size = board.size;
    final foundCells = <(int, int)>{
      for (final w in board.words)
        if (w.found) ...w.cells
    };
    final selected = _selection.toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = 8.0;
        final cell = (math.min(constraints.maxWidth, constraints.maxHeight) -
                pad * 2) /
            size;

        (int, int) cellAt(Offset local) {
          final c = ((local.dx - pad) / cell).floor().clamp(0, size - 1);
          final r = ((local.dy - pad) / cell).floor().clamp(0, size - 1);
          return (r, c);
        }

        return GestureDetector(
          onPanStart: (d) {
            if (_busy) return;
            setState(() {
              _dragStart = cellAt(d.localPosition);
              _selection = [_dragStart!];
            });
          },
          onPanUpdate: (d) {
            if (_busy || _dragStart == null) return;
            final (r, c) = cellAt(d.localPosition);
            setState(() => _selection = _lineTo(r, c));
          },
          onPanEnd: (_) => _endDrag(),
          onPanCancel: _endDrag,
          child: Container(
            padding: const EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: SizedBox(
              width: cell * size,
              height: cell * size,
              child: Column(
                children: [
                  for (var r = 0; r < size; r++)
                    Row(children: [
                      for (var c = 0; c < size; c++)
                        _letterCell(
                          board.letterAt(r, c),
                          cell,
                          found: foundCells.contains((r, c)),
                          selected: selected.contains((r, c)),
                        ),
                    ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _letterCell(String letter, double size,
      {required bool found, required bool selected}) {
    final bg = selected
        ? _accent.withValues(alpha: 0.45)
        : found
            ? _accent.withValues(alpha: 0.18)
            : Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(size * 0.04),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(size * 0.18),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: size * 0.44,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : found
                      ? _accent
                      : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordList(WordSearchBoard board) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final w in board.words)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: w.found ? _accent.withValues(alpha: 0.15) : Colors.white,
                border: Border.all(
                    color: w.found
                        ? _accent.withValues(alpha: 0.4)
                        : _accent),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (w.found) ...[
                    const Icon(Icons.check_rounded, size: 16, color: _accent),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    w.word,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: w.found
                          ? _accent.withValues(alpha: 0.6)
                          : Colors.black87,
                      decoration:
                          w.found ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
