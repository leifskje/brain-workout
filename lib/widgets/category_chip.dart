import 'package:flutter/material.dart';

import '../data/word_pool.dart';
import '../l10n/generated/app_localizations.dart';

/// The localised display name for a puzzle-word category.
String wordCategoryName(AppLocalizations l10n, WordCategory category) =>
    switch (category) {
      WordCategory.food => l10n.categoryFood,
      WordCategory.animals => l10n.categoryAnimals,
      WordCategory.home => l10n.categoryHome,
      WordCategory.nature => l10n.categoryNature,
      WordCategory.clothing => l10n.categoryClothing,
      WordCategory.body => l10n.categoryBody,
      WordCategory.travel => l10n.categoryTravel,
      WordCategory.people => l10n.categoryPeople,
    };

/// Shows which kind of word the letters spell.
///
/// This is the answer to "the letters make several words and nothing tells me
/// which one you want" — about 60% of scrambles have a second valid answer, and
/// the category separates them because the rival word is almost never another
/// everyday noun (CAR/ARC, MELK/KLEM). It doubles as a gentle hint for anyone
/// simply stuck, which is most of its value for this audience.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, required this.accent});

  final WordCategory category;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 22, color: accent),
          const SizedBox(width: 8),
          // Flexible so a long name ("Nature and weather", "Steder og reise")
          // wraps instead of overflowing. The app enlarges all text globally, so
          // one line cannot be assumed — an overflow here is what the Word
          // Scramble widget test caught.
          Flexible(
            child: Text(
              wordCategoryName(AppLocalizations.of(context), category),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
