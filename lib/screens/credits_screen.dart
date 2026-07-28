import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';

/// Attribution for the bundled word lists.
///
/// Not decorative: the Norwegian list (Norsk ordbank) is CC BY 4.0, which
/// *requires* naming the creator, identifying the licence, and stating that the
/// data was changed. All three are on this screen, which is why the app must
/// keep a route to it. The English list is public domain and needs nothing, but
/// is credited alongside for consistency.
///
/// Reached from the home screen so it works offline — a store listing would not
/// satisfy the licence for someone playing on a plane.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const _licenceUrl = 'https://creativecommons.org/licenses/by/4.0/';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.credits)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            t.creditsIntro,
            style: const TextStyle(fontSize: 17, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Text(
            t.creditsWordListsTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _Credit(
            name: t.creditsOrdbankName,
            body: t.creditsOrdbankBody,
            changes: t.creditsOrdbankChanges,
            linkLabel: t.creditsLicenceLink,
            url: _licenceUrl,
          ),
          const SizedBox(height: 20),
          _Credit(
            name: t.creditsDwylName,
            body: t.creditsDwylBody,
            changes: t.creditsDwylChanges,
          ),
        ],
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit({
    required this.name,
    required this.body,
    required this.changes,
    this.linkLabel,
    this.url,
  });

  final String name;
  final String body;

  /// CC BY obliges us to say the data was modified, so this is not optional
  /// detail — it is part of the attribution.
  final String changes;
  final String? linkLabel;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 16, height: 1.35)),
            const SizedBox(height: 8),
            Text(
              changes,
              style: const TextStyle(
                  fontSize: 15, height: 1.35, color: Colors.black54),
            ),
            if (linkLabel != null && url != null) ...[
              const SizedBox(height: 4),
              // Large hit area: this audience gets generous tap targets.
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(url!),
                  mode: LaunchMode.externalApplication,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 48),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(linkLabel!, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
