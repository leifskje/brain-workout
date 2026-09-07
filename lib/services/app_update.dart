import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Prompts a tester to update when Play has a newer build.
///
/// Why this exists: Play *does* auto-update in the background, but it defers
/// updates for apps the user opens rarely — which describes most testers. The
/// result is a tester playing a months-old build while we wait for feedback on
/// a new one, with no way for either side to notice.
///
/// **Immediate, not flexible.** The flexible flow shows a dismissible banner and
/// downloads in the background; for this audience that is a thing to dismiss
/// forever. The immediate flow blocks with Play's own full-screen updater, which
/// is what every other app they use does.
///
/// Testing this end to end is awkward and worth knowing before you try: the API
/// only reports an update for a build actually **installed from Play**, so
/// `flutter run` always reports none. Verifying it needs a throwaway version
/// bump published to the internal track.
class AppUpdate {
  AppUpdate._();

  /// Checks for an update and, if one is available, hands over to Play.
  ///
  /// Returns true only if Play reported a flexible/immediate update as allowed
  /// and the update flow was started. Every failure path is swallowed: a broken
  /// update check must never stop someone reaching the games.
  static Future<bool> promptIfAvailable() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }
      if (!info.immediateUpdateAllowed) return false;
      await InAppUpdate.performImmediateUpdate();
      return true;
    } catch (e) {
      // No Play install, no network, sideloaded debug build, user declined —
      // all land here and all are fine.
      debugPrint('AppUpdate: check skipped ($e)');
      return false;
    }
  }
}
