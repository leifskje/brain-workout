import 'package:flutter/widgets.dart';

/// The app-wide language override chosen on the home screen; null follows the
/// phone language. `main` seeds it from [ProgressStore] and the MaterialApp
/// rebuilds when it changes.
final ValueNotifier<Locale?> appLocaleOverride = ValueNotifier(null);
