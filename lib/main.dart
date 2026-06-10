import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/app_locale.dart';
import 'services/progress_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressStore.init();
  final storedLanguage = ProgressStore.instance.appLanguageId;
  if (storedLanguage != null) {
    appLocaleOverride.value = Locale(storedLanguage);
  }
  runApp(const BrainWorkoutApp());
}

class BrainWorkoutApp extends StatelessWidget {
  const BrainWorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocaleOverride,
      builder: (context, localeOverride, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // Set from the home screen's language menu; null follows the phone.
        locale: localeOverride,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Any Norwegian variant (Bokmål, Nynorsk, legacy 'no') gets the Bokmål
        // translation; everything else falls back to English.
        localeListResolutionCallback: (locales, supported) {
          for (final locale in locales ?? const <Locale>[]) {
            switch (locale.languageCode) {
              case 'nb' || 'nn' || 'no':
                return const Locale('nb');
              case 'en':
                return const Locale('en');
            }
          }
          return const Locale('en');
        },
        // Enlarge all text a little for easier reading.
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.1,
          maxScaleFactor: 1.3,
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
