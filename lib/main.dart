import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/progress_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressStore.init();
  runApp(const BrainWorkoutApp());
}

class BrainWorkoutApp extends StatelessWidget {
  const BrainWorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brain Workout',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Enlarge all text a little for easier reading.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.1,
        maxScaleFactor: 1.3,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
