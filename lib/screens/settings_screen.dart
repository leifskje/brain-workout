import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/progress_store.dart';
import 'credits_screen.dart';

/// The app's settings. Currently one switch, and that is fine — a settings
/// screen exists so the clock has somewhere to live, not to be filled.
///
/// Language is deliberately *not* moved here: it lives in the home screen's
/// header menu, where someone who has opened the app in the wrong language can
/// actually find it. Burying it one screen deeper would strand them.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final store = ProgressStore.instance;
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SwitchListTile(
            key: const ValueKey('settings_show_timer'),
            value: store.showTimerDuringPlay,
            onChanged: (value) async {
              await store.setShowTimerDuringPlay(value);
              if (mounted) setState(() {});
            },
            title: Text(t.showTimer,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            // Says the thing that is easy to get wrong about this switch: the
            // time is recorded either way, so turning it on later loses nothing.
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(t.showTimerNote,
                  style: const TextStyle(fontSize: 15, height: 1.35)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          ),
          const Divider(height: 8),
          // Norsk ordbank is CC BY 4.0, which obliges the *app* to carry the
          // credit, so a route to this screen is a licence requirement and not a
          // nicety. It moved off the home header to make room, but it must stay
          // reachable in-app — a store listing would not satisfy the licence for
          // someone playing on a plane.
          ListTile(
            key: const ValueKey('settings_credits'),
            leading: const Icon(Icons.info_outline_rounded, size: 28),
            title: Text(t.credits,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreditsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
