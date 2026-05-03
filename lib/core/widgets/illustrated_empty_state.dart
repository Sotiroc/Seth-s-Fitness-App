import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A consistent empty state used across the app: hand-drawn illustration,
/// title, body copy, and an optional action button.
///
/// All four illustrations live under `assets/illustrations/` and
/// share the same visual style (clean teal line art on transparent
/// backgrounds). Keep this widget in sync with the asset set.
class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.illustrationAsset,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.illustrationSize = 200,
  });

  final String illustrationAsset;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double illustrationSize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final JellyBeanPalette palette = context.jellyBeanPalette;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            illustrationAsset,
            width: illustrationSize,
            height: illustrationSize,
            fit: BoxFit.contain,
            // Source PNGs are 1024x1024; we render at ~200px. Decoding the
            // full resolution wastes memory on every empty-state render.
            cacheWidth: (illustrationSize * 2).round(),
            cacheHeight: (illustrationSize * 2).round(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.shade950,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.shade800.withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centralised paths so screens never type asset strings by hand.
class AppIllustrations {
  const AppIllustrations._();

  static const String emptyExercises =
      'assets/illustrations/empty_exercises.png';
  static const String emptyTemplates =
      'assets/illustrations/empty_templates.png';
  static const String emptyHistory =
      'assets/illustrations/empty_history.png';
  static const String workoutsHero =
      'assets/illustrations/workouts_hero.png';
}
