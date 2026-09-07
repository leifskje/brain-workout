import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Where tester feedback is sent.
///
/// Testers are non-developers, so GitHub issues are not a usable channel: they
/// need an account, the repo, and a form written for programmers. A `mailto:`
/// with the diagnostics already filled in means a one-line reply is still
/// actionable.
///
/// Change this if feedback should go somewhere other than the author's personal
/// inbox — it is the only place the address appears.
const String feedbackEmail = 'leifskje@gmail.com';

/// App version and the pre-filled feedback mail, in one place.
///
/// The version matters more than it looks: Play *defers* auto-updates for apps
/// opened rarely, so a tester can sit on a months-old build while we wait for
/// feedback on a new one. Before this existed the app showed its version
/// nowhere, so a report could not be tied to a build at all.
class AppInfo {
  AppInfo._();

  static final AppInfo instance = AppInfo._();

  String _version = '';
  String _build = '';

  /// "1.1.1 (4)", or an empty string before [load] completes.
  String get versionLabel =>
      _version.isEmpty ? '' : '$_version ($_build)';

  Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = info.version;
      _build = info.buildNumber;
    } catch (e) {
      // Never block startup over a version string.
      debugPrint('AppInfo: could not read package info: $e');
    }
  }

  /// The device facts worth having on a bug report, and nothing else. No
  /// identifiers, and nothing leaves the device unless the tester presses send
  /// in their own mail app.
  String diagnostics({required String locale, String? screen}) {
    final lines = <String>[
      'App: ${versionLabel.isEmpty ? 'unknown' : versionLabel}',
      if (screen != null) 'Screen: $screen',
      'Locale: $locale',
    ];
    if (!kIsWeb) {
      lines.add('OS: ${Platform.operatingSystem} '
          '${Platform.operatingSystemVersion}');
    }
    return lines.join('\n');
  }

  /// A `mailto:` for the feedback button. [body] is the localized prompt shown
  /// above the diagnostics block so the tester knows where to type.
  Uri feedbackUri({
    required String subject,
    required String body,
    required String locale,
    String? screen,
  }) {
    return Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      // queryParameters percent-encodes for us; building the query by hand is
      // how mailto links end up with raw spaces and newlines that Android's
      // intent resolver silently drops.
      queryParameters: {
        'subject': subject,
        'body': '$body\n\n\n'
            '-----\n'
            '${diagnostics(locale: locale, screen: screen)}\n',
      },
    );
  }
}
