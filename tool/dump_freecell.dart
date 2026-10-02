// ignore_for_file: avoid_print
// Prints a FreeCell level as text: the opening layout (cascades top to bottom,
// as on screen) and the solver's winning line, for checking deals without
// launching the app.
//
//   dart run tool/dump_freecell.dart [level] [--moves]
import 'package:brain_workout/games/freecell/freecell_models.dart';

const _suits = ['C', 'D', 'H', 'S'];
const _ranks = ' A23456789TJQK';

String name(int card) => '${_ranks[cardRank(card)]}${_suits[cardSuit(card)]}';

void main(List<String> args) {
  final level = args.isNotEmpty && !args[0].startsWith('-')
      ? int.parse(args[0])
      : 1;
  final d = FreeCellDeal.generate(level);
  final p = d.start();
  print(
    'Level $level: ${d.cells} free cells, needs ${d.need}, '
    'solution ${d.solution.length} moves, ${d.candidatesTried} deal(s) tried',
  );
  print(
    'home: ${[for (var s = 0; s < 4; s++) '${_suits[s]}${p.foundations[s]}'].join(' ')}',
  );
  final tallest = p.cascades
      .map((c) => c.length)
      .reduce((a, b) => a > b ? a : b);
  for (var row = 0; row < tallest; row++) {
    print(
      [
        for (final c in p.cascades)
          (row < c.length ? name(c[row]) : '').padLeft(4),
      ].join(),
    );
  }
  if (args.contains('--moves')) {
    final q = d.start();
    for (final m in d.solution) {
      final card = q.movingCard(m);
      q
        ..apply(m)
        ..autoPlay();
      print('${name(card)}  $m');
    }
    print(q.isWon ? 'won' : 'NOT WON');
  }
}
