import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/win_dialog.dart';
import 'mini_sudoku_models.dart';

/// Playable Mini Sudoku: tap a square, then a number from the pad. Conflicts
/// tint red so they are easy to spot and fix. No lose state — stars reflect
/// how many wrong numbers were placed along the way.
class MiniSudokuScreen extends StatefulWidget {
  const MiniSudokuScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<MiniSudokuScreen> createState() => _MiniSudokuScreenState();
}

class _MiniSudokuScreenState extends State<MiniSudokuScreen> {
  static const _gameId = 'mini_sudoku';
  static const _accent = Color(0xFF5C6BC0);
  static const _givenBg = Color(0xFFEDEAF6); // light lavender for givens

  int _level = 1;
  late MiniSudokuBoard _board;
  (int, int)? _selected;
  int _mistakes = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.startLevel);
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _board = MiniSudokuBoard.generate(level);
      _selected = null;
      _mistakes = 0;
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onCellTap(int r, int c) {
    if (_busy || _board.cells[r][c].given) return;
    setState(() {
      _selected = _selected == (r, c) ? null : (r, c);
    });
  }

  void _onNumberTap(int value) {
    final sel = _selected;
    if (_busy || sel == null) return;
    final (r, c) = sel;
    final cell = _board.cells[r][c];
    setState(() {
      if (cell.entered != value && value != cell.solution) _mistakes++;
      cell.entered = value;
    });
    HapticFeedback.lightImpact();
    if (_board.isSolved) {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 200), _showWin);
    }
  }

  void _onErase() {
    final sel = _selected;
    if (_busy || sel == null) return;
    setState(() => _board.cells[sel.$1][sel.$2].entered = null);
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final stars = _mistakes == 0 ? 3 : (_mistakes <= 2 ? 2 : 1);
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: t.levelN(_level), accent: _accent, onRestart: _restart),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: _buildGrid()),
              ),
            ),
            _buildNumberPad(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
              child: Text(
                t.miniSudokuHint,
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

  Widget _buildGrid() {
    final n = _board.size;
    return LayoutBuilder(
      builder: (context, constraints) {
        final dim = math.min(constraints.maxWidth, constraints.maxHeight);
        final cell = (dim - 4) / n;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 2),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
          child: SizedBox(
            width: cell * n,
            height: cell * n,
            child: Column(
              children: [
                for (var r = 0; r < n; r++)
                  Row(children: [
                    for (var c = 0; c < n; c++) _buildCell(r, c, cell),
                  ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c, double size) {
    final cell = _board.cells[r][c];
    final selected = _selected == (r, c);
    final conflict = !cell.given && cell.entered != null && _board.hasConflict(r, c);

    // Thicker dividers on box boundaries make the box structure obvious.
    BorderSide side(bool boxEdge) => BorderSide(
        color: boxEdge ? Colors.black87 : Colors.black26,
        width: boxEdge ? 1.8 : 0.6);

    final bg = selected
        ? _accent.withValues(alpha: 0.28)
        : conflict
            ? const Color(0xFFFDE3E3)
            : cell.given
                ? _givenBg
                : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onCellTap(r, c),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: side(r % _board.boxRows == 0 && r != 0),
            left: side(c % _board.boxCols == 0 && c != 0),
          ),
        ),
        alignment: Alignment.center,
        child: cell.effective == null
            ? null
            : Text(
                '${cell.effective}',
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight:
                      cell.given ? FontWeight.w800 : FontWeight.w600,
                  color: conflict
                      ? const Color(0xFFC62828)
                      : cell.given
                          ? Colors.black87
                          : _accent,
                ),
              ),
      ),
    );
  }

  Widget _buildNumberPad() {
    final n = _board.size;
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
          for (var v = 1; v <= n; v++) _padButton('$v', () => _onNumberTap(v)),
          _padButton(null, _onErase, icon: Icons.backspace_outlined),
        ],
      ),
    );
  }

  Widget _padButton(String? label, VoidCallback onTap, {IconData? icon}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 24, color: _accent)
              : Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
        ),
      ),
    );
  }
}
