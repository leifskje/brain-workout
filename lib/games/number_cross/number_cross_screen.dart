import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'number_cross_models.dart';

/// Playable Number Cross: place pool numbers into the blanks so every across
/// and down equation holds. Place by tapping (number then cell) or by dragging
/// a number onto a cell. No lose state — rearrange freely until it's solved.
class NumberCrossScreen extends StatefulWidget {
  const NumberCrossScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<NumberCrossScreen> createState() => _NumberCrossScreenState();
}

class _NumberCrossScreenState extends State<NumberCrossScreen> {
  static const _gameId = 'number_cross';
  static const _accent = Color(0xFFB5651D);
  static const _tile = Color(0xFFE8D8C3); // given-number tile (tan)

  int _level = 1;
  late NumberCrossBoard _board;
  int? _selectedPool;
  int _placements = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.startLevel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowHowToPlay(context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpNumberCross,
            accent: _accent);
      }
    });
  }

  void _loadLevel(int level) {
    ProgressStore.instance.recordReached(_gameId, level);
    setState(() {
      _level = level;
      _board = NumberCrossBoard.generate(level);
      _selectedPool = null;
      _placements = 0;
      _busy = false;
    });
  }

  void _restart() => _loadLevel(_level);

  void _onPoolTap(int index) {
    if (_busy) return;
    setState(() => _selectedPool = _selectedPool == index ? null : index);
  }

  /// Places the pool number at [poolIndex] into cell (r,c) — used by both tap
  /// and drag.
  void _placeFromPool(int poolIndex, int r, int c) {
    if (_busy || poolIndex < 0 || poolIndex >= _board.pool.length) return;
    final cell = _board.cells[r][c];
    if (cell.fixed) return;
    final value = _board.pool[poolIndex];
    setState(() {
      if (cell.placed != null) _board.pool.add(cell.placed!); // return existing
      cell.placed = value;
      _board.pool.removeAt(poolIndex);
      _selectedPool = null;
      _placements++;
    });
    HapticFeedback.lightImpact();
    if (_board.isSolved) {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 150), _showWin);
    }
  }

  void _onCellTap(int r, int c) {
    if (_busy) return;
    final cell = _board.cells[r][c];
    if (cell.fixed) return;
    if (_selectedPool != null) {
      _placeFromPool(_selectedPool!, r, c);
    } else if (cell.placed != null) {
      setState(() {
        _board.pool.add(cell.placed!);
        cell.placed = null;
      });
    }
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final blanks = _board.blankCount;
    final wasted = _placements - blanks;
    final stars = wasted <= 0 ? 3 : (wasted <= blanks ? 2 : 1);
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
                title: AppLocalizations.of(context).levelN(_level),
                accent: _accent,
                onRestart: _restart,
                onHelp: () => showHowToPlay(context,
                    body: AppLocalizations.of(context).helpNumberCross,
                    accent: _accent)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: _buildGrid()),
              ),
            ),
            _buildPool(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text(
                AppLocalizations.of(context).numberCrossHint,
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
    final rows = _board.rows, cols = _board.cols;
    return LayoutBuilder(
      builder: (context, constraints) {
        const panelPad = 10.0;
        final cell = math.min(
          (constraints.maxWidth - panelPad * 2) / cols,
          (constraints.maxHeight - panelPad * 2) / rows,
        );
        return Container(
          padding: const EdgeInsets.all(panelPad),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: cell * cols,
            height: cell * rows,
            child: Column(
              children: [
                for (var r = 0; r < rows; r++)
                  Row(children: [
                    for (var c = 0; c < cols; c++) _buildCell(r, c, cell),
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
    switch (cell.kind) {
      case NcKind.blank:
        return SizedBox(width: size, height: size);
      case NcKind.op:
        return _symbolCell(opSymbol(cell.op!), size);
      case NcKind.equals:
        return _symbolCell('=', size);
      case NcKind.number:
        return _numberCell(cell, r, c, size);
    }
  }

  Widget _symbolCell(String text, double size) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
                color: Colors.black54),
          ),
        ),
      );

  Widget _tileBox(double size, {required Color bg, required Color border, Widget? child, double borderWidth = 2}) {
    final pad = size * 0.07;
    // Always occupy the full cell so the grid aligns and the whole cell is a
    // tap / drop target (the inset is just visual padding).
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: borderWidth),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _numberCell(NcCell cell, int r, int c, double size) {
    final numStyle = TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold);

    if (cell.fixed) {
      // Given number — solid tan tile, not interactive.
      return _tileBox(
        size,
        bg: _tile,
        border: const Color(0xFFCBB694),
        child: Text('${cell.value}',
            style: numStyle.copyWith(color: Colors.black87)),
      );
    }

    // To-place cell — accepts taps and drops; highlights while hovered and
    // previews the number being dragged in.
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !_busy,
      onAcceptWithDetails: (d) => _placeFromPool(d.data, r, c),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        final filled = cell.placed != null;
        final hintTarget = _selectedPool != null && !filled;

        int? preview;
        if (hovering && candidate.first != null) {
          final idx = candidate.first!;
          if (idx >= 0 && idx < _board.pool.length) preview = _board.pool[idx];
        }

        final bg = hovering
            ? _accent.withValues(alpha: 0.38)
            : filled
                ? _accent.withValues(alpha: 0.16)
                : hintTarget
                    ? _accent.withValues(alpha: 0.12)
                    : Colors.white;

        Widget? child;
        if (filled) {
          child = Text('${cell.placed}', style: numStyle.copyWith(color: _accent));
        } else if (preview != null) {
          child = Text('$preview',
              style: numStyle.copyWith(color: _accent.withValues(alpha: 0.45)));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onCellTap(r, c),
          child: _tileBox(
            size,
            bg: bg,
            border: _accent,
            borderWidth: hovering ? 3.5 : 2.5,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildPool() {
    if (_board.pool.isEmpty) return const SizedBox(height: 8);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [for (var i = 0; i < _board.pool.length; i++) _poolChip(i)],
      ),
    );
  }

  Widget _poolChip(int index) {
    final value = _board.pool[index];
    final selected = _selectedPool == index;
    final chip = _chipVisual(value, selected: selected);
    return Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: _chipVisual(value, selected: true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: GestureDetector(onTap: () => _onPoolTap(index), child: chip),
    );
  }

  Widget _chipVisual(int value, {required bool selected}) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: selected ? _accent : Colors.white,
        border: Border.all(color: _accent, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : _accent,
        ),
      ),
    );
  }
}
