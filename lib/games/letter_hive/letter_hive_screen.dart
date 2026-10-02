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
import 'letter_hive_models.dart';

/// Playable Letter hive. Tap letters to spell, OK to submit.
///
/// Reaching the goal clears the level, but the dialog offers "Keep going":
/// the hunt for more words is the game, and more stars are the reward for it.
/// No timer and no lose state — there is nothing to lose.
class LetterHiveScreen extends StatefulWidget {
  const LetterHiveScreen({super.key, this.startLevel = 1});

  final int startLevel;

  @override
  State<LetterHiveScreen> createState() => _LetterHiveScreenState();
}

/// Built once per language from the dictionary; ~100ms, so not per level.
final Map<String, HiveIndex> _indexes = {};

class _LetterHiveScreenState extends State<LetterHiveScreen>
    with WidgetsBindingObserver, BoardAutosave<LetterHiveScreen> {
  static const _gameId = 'letter_hive';
  static const _accent = Color(0xFFB8860B);
  static const _centreColour = Color(0xFFF7C948);
  static const _outerColour = Color(0xFFEDEDED);

  String _language = 'en';
  int _level = 1;
  LetterHivePuzzle? _puzzle;

  /// Outer letters in display order; Shuffle reorders them.
  List<String> _outer = const [];
  final List<String> _found = [];
  String _current = '';
  String? _message;
  bool _messageGood = false;
  int _messageToken = 0;

  /// Whether the goal was reached, and the stars held, for this level.
  bool _cleared = false;
  int _stars = 0;

  /// The dictionary load is kicked off once, from the first dependency change.
  bool _started = false;

  /// The word the current hint points at, and how many of its letters it
  /// shows. Each further hint shows one more letter of the same word until it
  /// is found. The first hint caps the level at two stars, as in the other
  /// word games.
  String? _hintWord;
  int _hintShown = 0;
  bool _usedHint = false;

  /// Missed words are on show, so the level can earn no more stars: otherwise
  /// the reveal would be a list to copy from.
  bool _revealed = false;

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
      _indexes[_language] ??= HiveIndex(_language, [
        for (final word in dictionary.words) (word, dictionary.tierOf(word)!),
      ]);
      _loadLevel(widget.startLevel);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          maybeShowHowToPlay(
            context,
            gameId: _gameId,
            body: AppLocalizations.of(context).helpLetterHive,
            accent: _accent,
          );
        }
      });
    });
  }

  void _loadLevel(int level, {bool allowResume = true}) {
    final index = _indexes[_language]!;
    ProgressStore.instance.recordReached(_gameId, level);
    final puzzle = LetterHivePuzzle.generate(level, index);
    final saved = allowResume
        ? ProgressStore.instance.loadBoard(_gameId, level)
        : null;
    final found = <String>[];
    final usable =
        saved != null &&
        saved['lang'] == _language &&
        saved['v'] == LetterHivePuzzle.generatorVersion;
    if (usable && saved['found'] is List) {
      for (final w in saved['found'] as List) {
        if (w is String &&
            !found.contains(w) &&
            puzzle.check(w, const {}) == HiveVerdict.ok) {
          found.add(w);
        }
      }
    }
    setState(() {
      _level = level;
      _puzzle = puzzle;
      _outer = puzzle.letters.substring(1).split('');
      _found
        ..clear()
        ..addAll(found);
      _current = '';
      _message = null;
      final hint = usable ? saved['hint'] : null;
      _hintWord = hint is String && puzzle.answers.contains(hint) ? hint : null;
      _hintShown = usable ? (saved['shown'] as int? ?? 0) : 0;
      _usedHint = usable && saved['usedHint'] == true;
      _revealed = usable && saved['revealed'] == true;
      _stars = _starsFor(_score);
      _cleared = _score >= puzzle.starPoints.first;
    });
  }

  void _restart() {
    ProgressStore.instance.clearBoard(_gameId);
    _loadLevel(_level, allowResume: false);
  }

  @override
  void dispose() {
    if (_puzzle != null) saveBoardNow();
    stopAutosave();
    super.dispose();
  }

  // ---- BoardAutosave ----

  @override
  String get autosaveGameId => _gameId;

  @override
  int get autosaveLevel => _level;

  @override
  Map<String, dynamic>? captureBoard() {
    // Kept after the goal too: the player may come back for more stars.
    if (_found.isEmpty && !_usedHint) return null;
    return {
      'lang': _language,
      'v': LetterHivePuzzle.generatorVersion,
      'found': List<String>.from(_found),
      'hint': _hintWord,
      'shown': _hintShown,
      'usedHint': _usedHint,
      'revealed': _revealed,
    };
  }

  // ---- Play ----

  int get _score => _found.fold(0, (sum, w) => sum + _puzzle!.pointsFor(w));

  int _starsFor(int score) {
    final earned = _puzzle!.starPoints.where((p) => score >= p).length;
    return _usedHint ? math.min(earned, 2) : earned;
  }

  void _tapLetter(String letter) {
    if (_current.length >= maxWordLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _current += letter;
      _message = null;
    });
  }

  void _delete() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  void _shuffle() {
    HapticFeedback.selectionClick();
    setState(() => _outer = List.of(_outer)..shuffle());
  }

  void _submit() {
    final puzzle = _puzzle!;
    if (_current.isEmpty) return;
    final t = AppLocalizations.of(context);
    final word = _current;
    final verdict = puzzle.check(word, _found.toSet());
    if (verdict != HiveVerdict.ok) {
      HapticFeedback.mediumImpact();
      _say(switch (verdict) {
        HiveVerdict.tooShort => t.letterHiveTooShort,
        HiveVerdict.missingCentre => t.letterHiveMissingCentre(puzzle.centre),
        HiveVerdict.alreadyFound => t.letterHiveAlreadyFound,
        _ => t.letterHiveNotAWord,
      }, good: false);
      setState(() => _current = '');
      return;
    }
    HapticFeedback.lightImpact();
    final points = puzzle.pointsFor(word);
    setState(() {
      _found.add(word);
      _current = '';
    });
    _say(
      puzzle.isPangram(word)
          ? t.letterHivePangram(points)
          : puzzle.answers.contains(word)
          ? t.letterHivePoints(points)
          : t.letterHiveBonus(points),
      good: true,
    );

    if (_revealed) return;
    final stars = _starsFor(_score);
    if (stars <= _stars) return;
    _stars = stars;
    ProgressStore.instance.recordCleared(_gameId, _level, stars);
    if (!_cleared) {
      _cleared = true;
      ProgressStore.instance.registerPlay(_gameId);
      _showWin();
    } else {
      HapticFeedback.heavyImpact();
      _snack(t.letterHiveMoreStars(stars));
    }
  }

  void _hint() {
    final puzzle = _puzzle;
    if (puzzle == null) return;
    final t = AppLocalizations.of(context);
    final current = _hintWord;
    if (current == null || _found.contains(current)) {
      final left = [
        for (final w in puzzle.answers)
          if (!_found.contains(w)) w,
      ];
      if (left.isEmpty) {
        _snack(t.letterHiveNoHints);
        return;
      }
      final word = left[math.Random().nextInt(left.length)];
      setState(() {
        _hintWord = word;
        _hintShown = math.min(2, word.length - 1);
      });
    } else if (_hintShown < current.length - 1) {
      setState(() => _hintShown++);
    }
    HapticFeedback.selectionClick();
    if (!_usedHint) {
      setState(() => _usedHint = true);
      _snack(t.hintCost);
    }
  }

  /// The hint as it reads on screen: "GU _ _ _ _ _".
  String? get _hintPattern {
    final word = _hintWord;
    if (word == null || _found.contains(word)) return null;
    return word.substring(0, _hintShown) +
        List.filled(word.length - _hintShown, ' _').join();
  }

  Future<void> _confirmReveal() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.letterHiveRevealTitle),
        content: Text(
          t.letterHiveRevealBody,
          style: const TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.letterHiveRevealCancel),
          ),
          FilledButton(
            key: const ValueKey('hive_reveal_confirm'),
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.letterHiveRevealConfirm),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    setState(() => _revealed = true);
    saveBoardNow();
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
  void _say(String text, {required bool good}) {
    final token = ++_messageToken;
    setState(() {
      _message = text;
      _messageGood = good;
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && token == _messageToken) setState(() => _message = null);
    });
  }

  void _showWin() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final t = AppLocalizations.of(context);
    showWinDialog(
      context,
      level: _level,
      accent: _accent,
      stars: _stars,
      message: t.letterHiveGoalReached(_level),
      closeLabel: t.letterHiveKeepGoing,
    ).then((action) {
      if (!mounted || action == null) return;
      if (action == WinAction.next) _nextLevel();
    });
  }

  void _nextLevel() {
    saveBoardNow();
    _loadLevel(_level + 1);
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
                body: t.helpLetterHive,
                accent: _accent,
              ),
              showHint: true,
              onHint: puzzle == null ? null : _hint,
            ),
            if (puzzle == null)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _accent)),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => Column(
                    children: [
                      _buildScore(t, puzzle),
                      _buildWord(t, puzzle),
                      SizedBox(
                        height: 28,
                        child: _message == null
                            ? null
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _message!,
                                  key: const ValueKey('hive_message'),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: _messageGood
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                  ),
                                ),
                              ),
                      ),
                      // Width-bound on most phones; on a short one the found-words
                      // list needs room too, so height caps it as well.
                      _buildHive(
                        puzzle,
                        math.max(
                          28.0,
                          math.min(
                            46.0,
                            math.min(
                              (c.maxWidth - 32) / 5.6,
                              (c.maxHeight - 330) / 5.6,
                            ),
                          ),
                        ),
                      ),
                      _buildButtons(t),
                      Expanded(child: _buildFound(t, puzzle)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScore(AppLocalizations t, LetterHivePuzzle puzzle) {
    final marks = puzzle.starPoints;
    final top = marks.last;
    final score = _score;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.letterHiveScore(score, marks.first),
                  key: const ValueKey('hive_score'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, c) {
                    return SizedBox(
                      height: 26,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 9,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: math.min(1.0, score / top),
                                minHeight: 8,
                                color: _accent,
                                backgroundColor: Colors.black12,
                              ),
                            ),
                          ),
                          for (var i = 0; i < marks.length; i++)
                            Positioned(
                              left: (c.maxWidth * marks[i] / top) - 13,
                              top: 0,
                              child: Icon(
                                score >= marks[i]
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 26,
                                color: score >= marks[i]
                                    ? _accent
                                    : Colors.black38,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Once the goal is met, moving on is always one tap away, not only
          // from the dialog the player may have dismissed.
          if (_cleared)
            FilledButton(
              key: const ValueKey('hive_next'),
              onPressed: _nextLevel,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                minimumSize: const Size(56, 48),
              ),
              child: const Icon(Icons.arrow_forward_rounded),
            ),
        ],
      ),
    );
  }

  Widget _buildWord(AppLocalizations t, LetterHivePuzzle puzzle) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _current.isEmpty
          ? Text(
              t.letterHiveTapLetters,
              style: const TextStyle(fontSize: 16, color: Colors.black38),
            )
          : FittedBox(
              child: Text.rich(
                key: const ValueKey('hive_current'),
                TextSpan(
                  children: [
                    for (final ch in _current.split(''))
                      TextSpan(
                        text: ch,
                        style: TextStyle(
                          color: ch == puzzle.centre
                              ? const Color(0xFFB07D00)
                              : Colors.black87,
                        ),
                      ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
    );
  }

  /// Centre hex plus six around it, flat-topped. One detector covers them all
  /// and picks the nearest centre, so the gaps between hexes never swallow a
  /// tap.
  Widget _buildHive(LetterHivePuzzle puzzle, double radius) {
    return Builder(
      builder: (context) {
        final step = radius * math.sqrt(3) * 1.06;
        final width = radius * 5.4;
        final height = step * 3;
        final centre = Offset(width / 2, height / 2);
        final positions = [
          centre,
          for (var i = 0; i < 6; i++)
            centre + Offset.fromDirection(-math.pi / 2 + i * math.pi / 3, step),
        ];
        final letters = [puzzle.centre, ..._outer];
        return SizedBox(
          width: width,
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              var best = 0;
              for (var i = 1; i < positions.length; i++) {
                if ((d.localPosition - positions[i]).distance <
                    (d.localPosition - positions[best]).distance) {
                  best = i;
                }
              }
              if ((d.localPosition - positions[best]).distance <= step * 0.75) {
                _tapLetter(letters[best]);
              }
            },
            child: Stack(
              children: [
                for (var i = 0; i < 7; i++)
                  Positioned(
                    left: positions[i].dx - radius,
                    top: positions[i].dy - radius,
                    child: CustomPaint(
                      key: ValueKey('hive_letter_${letters[i]}'),
                      size: Size(radius * 2, radius * 2),
                      painter: _HexPainter(
                        letter: letters[i],
                        colour: i == 0 ? _centreColour : _outerColour,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtons(AppLocalizations t) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: Colors.black87,
      side: const BorderSide(color: Colors.black26, width: 1.5),
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const ValueKey('hive_delete'),
              onPressed: _current.isEmpty ? null : _delete,
              style: style,
              child: FittedBox(child: Text(t.letterHiveDelete)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            key: const ValueKey('hive_shuffle'),
            onPressed: _shuffle,
            style: style,
            child: Tooltip(
              message: t.letterHiveShuffle,
              child: const Icon(Icons.shuffle_rounded),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              key: const ValueKey('hive_ok'),
              onPressed: _current.isEmpty ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
              ),
              child: FittedBox(child: Text(t.letterHiveOk)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFound(AppLocalizations t, LetterHivePuzzle puzzle) {
    final words = List.of(_found)..sort();
    final missed = _revealed
        ? [
            for (final w in puzzle.answers)
              if (!_found.contains(w)) w,
          ]
        : const <String>[];
    final hint = _hintPattern;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.letterHiveFound(_found.length),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Only once the goal is met, so it never spoils the hunt itself.
              if (_cleared && !_revealed)
                TextButton(
                  key: const ValueKey('hive_reveal'),
                  onPressed: _confirmReveal,
                  style: TextButton.styleFrom(foregroundColor: _accent),
                  child: Text(t.letterHiveShowMissed),
                ),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Text(
                t.letterHiveHintLine(hint, _hintWord!.length),
                key: const ValueKey('hive_hint'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB07D00),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _wordWrap(words, puzzle, missed: false),
                  if (missed.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      t.letterHiveMissed(missed.length),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _wordWrap(missed, puzzle, missed: true),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordWrap(
    List<String> words,
    LetterHivePuzzle puzzle, {
    required bool missed,
  }) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final w in words)
          Text(
            w,
            style: TextStyle(
              fontSize: 17,
              fontWeight: puzzle.isPangram(w)
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: missed
                  ? Colors.black45
                  : puzzle.isPangram(w)
                  ? const Color(0xFFB07D00)
                  : Colors.black87,
            ),
          ),
      ],
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter({required this.letter, required this.colour});

  final String letter;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final p = c + Offset.fromDirection(i * math.pi / 3, r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = colour);
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: r * 0.75,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.letter != letter || old.colour != colour;
}
