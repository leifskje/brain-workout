import 'package:flutter/widgets.dart';

import 'progress_store.dart';

/// Keeps a game's in-progress board on disk so an interruption doesn't lose it.
///
/// The case this exists for is mundane and was completely unhandled: the phone
/// rings, Android backgrounds the app, the process is eventually killed, and a
/// half-finished 12x12 Picture Logic board is simply gone.
///
/// Mix into a game's [State] alongside [WidgetsBindingObserver] and implement the
/// three members. Saving happens on two triggers:
///
///  - **`paused` / `hidden`** — the phone-call case. This is the one that matters:
///    once the process is killed there is no later chance to write anything, so
///    the save has to already have happened.
///  - **`dispose`** — the player pressing Back. Cheap, and it means leaving and
///    re-entering behaves the same as being interrupted.
///
/// [captureBoard] returning null means "nothing worth keeping", which is how a
/// finished or untouched board avoids being saved. That matters for ordering: a
/// win clears the slot and then `dispose` runs, so if a won board still captured
/// state it would immediately write itself back and the player would resume a
/// board they had already beaten.
mixin BoardAutosave<W extends StatefulWidget> on State<W>
    implements WidgetsBindingObserver {
  /// The `GameDefinition.id` this board belongs to.
  String get autosaveGameId;

  /// The level currently being played. Part of the saved slot, so a save is only
  /// ever restored onto the level it came from.
  int get autosaveLevel;

  /// The board as JSON, or null when there is nothing worth saving — an
  /// untouched board, or one that is already won or lost.
  Map<String, dynamic>? captureBoard();

  void startAutosave() => WidgetsBinding.instance.addObserver(this);

  void stopAutosave() => WidgetsBinding.instance.removeObserver(this);

  /// Writes the board now, or clears the slot if there is nothing to keep.
  void saveBoardNow() {
    final state = captureBoard();
    if (state == null) {
      ProgressStore.instance.clearBoard(autosaveGameId);
    } else {
      ProgressStore.instance.saveBoard(autosaveGameId, autosaveLevel, state);
    }
  }

  /// The saved board for the level being played, or null.
  Map<String, dynamic>? restoreBoard() =>
      ProgressStore.instance.loadBoard(autosaveGameId, autosaveLevel);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      saveBoardNow();
    }
  }
}
