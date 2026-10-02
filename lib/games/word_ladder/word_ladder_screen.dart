import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/dictionary.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/board_autosave.dart';
import '../../services/progress_store.dart';
import '../../widgets/game_header.dart';
import '../../widgets/how_to_play.dart';
import '../../widgets/win_dialog.dart';
import 'word_ladder_models.dart';

/// Playable Word Ladder. Tap a letter of the current word, then a new letter
/// on the keypad; a real word becomes the next rung. Stepping back is free.
/// Untimed, and a word that isn't one costs nothing.
class WordLadderScreen extends StatefulWidget {
  const WordLadderScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<WordLadderScreen> createState() => _WordLadderScreenState();
}

/// Built once per language from the dictionary; ~150ms, so not per level.
final Map<String, LadderIndex> _indexes = {};

class _WordLadderScreenState extends State<WordLadderScreen>
    with WidgetsBindingObserver, BoardAutosave<WordLadderScreen> {
  static const _gameId = 'word_ladder';
  static const _accent = Color(0xFF283593);
  static const _match = Color(0xFF2E7D32);
  static const _hintColour = Color(0xFFB07D00);

  String _language = 'en';
  int _level = 1;
  WordLadderPuzzle? _puzzle;

  /// Every word so far, the start first; the last one is the current word.
  final List<String> _ladder = [];
  int? _selected;
  bool _won = false;
  bool _usedHint = false;

  /// The word the hint suggests, for as long as the ladder hasn't moved.
  String? _hintWord;

  String? _message;
  int _messageToken = 0;

  bool _started = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    startAutosave();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _language = Localizations.localeOf(context).languageCode == 'nb'
        ? 'nb'
        : 'en';
    Dictionary.forLanguage(_language).then((dictionary) {
      if (!mounted) return;
      _indexes[_language] ??= LadderIndex(_language, [
        for (final word in dictionary.words) (word, dictionary.tierOf(word)!),
      ]);
      _loadLevel(widget.startLevel);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          maybeShowHowToPlay(
            context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpWordLadder,
            accent: _accent,
          );
        }
      });
    });
  }

  void _loadLevel(int level, {bool allowResume = true}) {
    final index = _indexes[_language]!;
    ProgressStore.instance.recordReached(_gameId, level);
    final puzzle = WordLadderPuzzle.generate(level, index);
    final saved = allowResume
        ? ProgressStore.instance.loadBoard(_gameId, level)
        : null;
    final usable =
        saved != null &&
        saved['lang'] == _language &&
        saved['v'] == WordLadderPuzzle.generatorVersion &&
        saved['ladder'] is List;
    final ladder = [puzzle.start];
    if (usable) {
      // Replayed through the rules, so a damaged save can only come back
      // shorter, never wrong.
      final words = (saved['ladder'] as List).whereType<String>().toList();
      if (words.isNotEmpty && words.first == puzzle.start) {
        for (final w in words.skip(1)) {
          if (w == puzzle.target ||
              puzzle.check(ladder.last, w, ladder) != StepVerdict.ok) {
            break;
          }
          ladder.add(w);
        }
      }
    }
    setState(() {
      _level = level;
      _puzzle = puzzle;
      _ladder
        ..clear()
        ..addAll(ladder);
      _selected = null;
      _won = false;
      _usedHint = usable && saved['usedHint'] == true;
      _hintWord = null;
      _message = null;
    });
    _scrollToEnd();
  }

  void _restart() {
    ProgressStore.instance.clearBoard(_gameId);
    _loadLevel(_level, allowResume: false);
  }

  @override
  void dispose() {
    if (_puzzle != null) saveBoardNow();
    stopAutosave();
    _scroll.dispose();
    super.dispose();
  }

  // ---- BoardAutosave ----

  @override
  String get autosaveGameId => _gameId;

  @override
  int get autosaveLevel => _level;

  @override
  Map<String, dynamic>? captureBoard() {
    if (_won || (_ladder.length < 2 && !_usedHint)) return null;
    return {
      'lang': _language,
      'v': WordLadderPuzzle.generatorVersion,
      'ladder': List<String>.from(_ladder),
      'usedHint': _usedHint,
    };
  }

  // ---- Play ----

  String get _current => _ladder.last;
  int get _steps => _ladder.length - 1;

  void _selectPosition(int i) {
    if (_won) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = _selected == i ? null : i);
  }

  void _pickLetter(String letter) {
    final puzzle = _puzzle;
    final pos = _selected;
    if (puzzle == null || pos == null || _won) return;
    final current = _current;
    if (current[pos] == letter) return;
    final word =
        current.substring(0, pos) + letter + current.substring(pos + 1);
    final t = AppLocalizations.of(context);
    final verdict = puzzle.check(current, word, _ladder);
    if (verdict != StepVerdict.ok) {
      HapticFeedback.mediumImpact();
      _say(
        verdict == StepVerdict.alreadyUsed
            ? t.wordLadderAlreadyUsed(word)
            : t.wordLadderNotAWord(word),
      );
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _ladder.add(word);
      _selected = null;
      _hintWord = null;
      _message = null;
    });
    _scrollToEnd();
    if (word == puzzle.target) _win();
  }

  void _stepBack() {
    if (_ladder.length < 2 || _won) return;
    HapticFeedback.selectionClick();
    setState(() {
      _ladder.removeLast();
      _selected = null;
      _hintWord = null;
      _message = null;
    });
  }

  void _hint() {
    final puzzle = _puzzle;
    if (puzzle == null || _won) return;
    final t = AppLocalizations.of(context);
    final next = puzzle.hint(_current);
    if (next == null) {
      _say(t.wordLadderNoWay);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _hintWord = next;
      _message = null;
    });
    if (!_usedHint) {
      setState(() => _usedHint = true);
      saveBoardNow();
      _snack(t.hintCost);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text, style: const TextStyle(fontSize: 18)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Shows [text] under the word, then clears it — unless something newer has
  /// replaced it in the meantime.
  void _say(String text) {
    final token = ++_messageToken;
    setState(() => _message = text);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && token == _messageToken) setState(() => _message = null);
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _win() {
    final puzzle = _puzzle!;
    setState(() => _won = true);
    HapticFeedback.heavyImpact();
    ProgressStore.instance.clearBoard(_gameId);
    final stars = WordLadderPuzzle.starsFor(
      _steps,
      puzzle.par,
      usedHint: _usedHint,
    );
    ProgressStore.instance
      ..registerPlay(_gameId)
      ..recordCleared(_gameId, _level, stars);
    // Local-only personal best; nothing here is ever sent anywhere.
    final beat = ProgressStore.instance.recordBest(
      _gameId,
      _level,
      _steps,
      lowerIsBetter: true,
    );
    final best = ProgressStore.instance.bestResult(_gameId, _level);
    final t = AppLocalizations.of(context);
    // After the new rung has painted, so the finished ladder shows behind it.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      showWinDialog(
        context,
        level: _level,
        accent: _accent,
        stars: stars,
        message: t.wordLadderWon(_steps, puzzle.par),
        newRecord: beat,
        bestText: best == null ? null : t.wordLadderBest(best),
      ).then((action) {
        if (!mounted || action == null) return;
        if (action == WinAction.next) {
          _loadLevel(_level + 1);
        } else {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      });
    });
  }

  // ---- Layout ----

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final puzzle = _puzzle;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: t.levelN(_level),
              accent: _accent,
              onRestart: _restart,
              onHelp: () => showHowToPlay(
                context,
                body: t.helpWordLadder,
                accent: _accent,
              ),
              showHint: true,
              onHint: puzzle == null || _won ? null : _hint,
            ),
            if (puzzle == null)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _accent)),
              )
            else ...[
              _buildInfo(t, puzzle),
              Expanded(child: _buildLadder(t, puzzle)),
              _buildCurrent(puzzle),
              _buildMessage(t),
              _buildTarget(t, puzzle),
              _buildKeypad(puzzle),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(AppLocalizations t, WordLadderPuzzle puzzle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.wordLadderPar(puzzle.par),
                    key: const ValueKey('ladder_par'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    t.wordLadderSteps(_steps),
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: const ValueKey('ladder_undo'),
            onPressed: _ladder.length < 2 || _won ? null : _stepBack,
            icon: const Icon(Icons.undo_rounded),
            label: Text(t.wordLadderStepBack),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              minimumSize: const Size(0, 48),
              side: const BorderSide(color: Colors.black26, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// The rungs climbed so far, the start first. The current word is drawn
  /// below as tiles, so it is left out here.
  Widget _buildLadder(AppLocalizations t, WordLadderPuzzle puzzle) {
    final past = _ladder.sublist(0, _ladder.length - 1);
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      itemCount: past.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              child: Text(
                i == 0 ? t.wordLadderStart : '$i',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  past[i].split('').join(' '),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            // Balances the label, so the words sit centred over the tiles.
            const SizedBox(width: 78),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrent(WordLadderPuzzle puzzle) {
    final word = _current;
    final hint = _hintWord;
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final size = math.min(
          64.0,
          (c.maxWidth - 32 - gap * (word.length - 1)) / word.length,
        );
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < word.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                _tile(
                  i,
                  word[i],
                  size,
                  selected: _selected == i,
                  matches: word[i] == puzzle.target[i],
                  hinted: hint != null && hint[i] != word[i],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tile(
    int i,
    String letter,
    double size, {
    required bool selected,
    required bool matches,
    required bool hinted,
  }) {
    final Color fill = _won ? _match : (selected ? _accent : Colors.white);
    final Color ink = _won || selected
        ? Colors.white
        : (matches ? _match : Colors.black87);
    return Semantics(
      button: true,
      selected: selected,
      label: letter,
      child: GestureDetector(
        key: ValueKey('ladder_pos_$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectPosition(i),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hinted
                  ? _hintColour
                  : (selected ? _accent : Colors.black45),
              width: hinted ? 4 : 2,
            ),
          ),
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                letter,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(AppLocalizations t) {
    final String text;
    final Color colour;
    if (_message != null) {
      (text, colour) = (_message!, const Color(0xFFC62828));
    } else if (_hintWord != null) {
      (text, colour) = (t.wordLadderHint(_hintWord!), _hintColour);
    } else if (_won) {
      (text, colour) = ('', Colors.black54);
    } else {
      (text, colour) = (
        _selected == null ? t.wordLadderTapLetter : t.wordLadderPickLetter,
        Colors.black54,
      );
    }
    return SizedBox(
      height: 30,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              key: const ValueKey('ladder_message'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colour,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTarget(AppLocalizations t, WordLadderPuzzle puzzle) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent, width: 2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _won ? Icons.check_circle_rounded : Icons.flag_rounded,
              color: _won ? _match : _accent,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              t.wordLadderTarget,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            Text(
              puzzle.target.split('').join(' '),
              key: const ValueKey('ladder_target'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(WordLadderPuzzle puzzle) {
    final letters = puzzle.index.alphabet.split('');
    final perRow = letters.length > 26 ? 8 : 7;
    final rows = [
      for (var i = 0; i < letters.length; i += perRow)
        letters.sublist(i, math.min(letters.length, i + perRow)),
    ];
    final enabled = _selected != null && !_won;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 5.0;
          final width = (c.maxWidth - gap * (perRow - 1)) / perRow;
          return Column(
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(top: gap),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < row.length; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        _key(row[i], width, enabled),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _key(String letter, double width, bool enabled) {
    final current = _selected == null ? null : _current[_selected!];
    final same = letter == current;
    return SizedBox(
      width: width,
      height: 50,
      child: FilledButton(
        key: ValueKey('ladder_key_$letter'),
        onPressed: enabled && !same ? () => _pickLetter(letter) : null,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFE8EAF6),
          foregroundColor: Colors.black87,
          disabledBackgroundColor: const Color(0xFFF1F1F1),
          disabledForegroundColor: Colors.black38,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          letter,
          textScaler: TextScaler.noScaling,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
