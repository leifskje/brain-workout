import 'package:flutter/widgets.dart';

/// Whether the app enlarges text beyond the phone's own setting. `main` seeds it
/// from [ProgressStore] and the MaterialApp rebuilds when it changes.
final ValueNotifier<bool> appLargerText = ValueNotifier(true);

/// The smallest text scale the app allows. With larger text on (the default) it
/// is 1.1, so a phone left at 1.0 still reads comfortably; off, the phone's own
/// setting is followed down to 1.0 for players who prefer denser screens.
double appMinTextScale(bool larger) => larger ? 1.1 : 1.0;

/// Never above this: past 1.3 the game boards and cards stop fitting a phone.
const double appMaxTextScale = 1.3;
