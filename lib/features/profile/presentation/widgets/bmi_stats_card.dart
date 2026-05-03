import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/profile_stats_provider.dart';

/// Surfaces the headline BMI metric, the WHO category chip, and a placeholder
/// for the future composite score on the Profile screen.
class BmiStatsCard extends StatelessWidget {
  const BmiStatsCard({super.key, required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'BODY MASS INDEX',
            style: TextStyle(
              color: palette.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (stats.hasBmi)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  stats.bmi!.toStringAsFixed(1),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: palette.shade950,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (stats.bmiCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CategoryChip(
                      palette: palette,
                      category: stats.bmiCategory!,
                    ),
                  ),
              ],
            )
          else
            Text(
              'Add height & weight to see your BMI.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: palette.shade100),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'SCORE',
                      style: TextStyle(
                        color: palette.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats.score?.toString() ?? '—',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: palette.shade950,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Coming soon',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (stats.hasGoalDelta && stats.weightToGoalDirection != null)
                _GoalDeltaPill(
                  palette: palette,
                  deltaKg: stats.weightToGoalKg!,
                  direction: stats.weightToGoalDirection!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.palette, required this.category});

  final JellyBeanPalette palette;
  final BmiCategory category;

  @override
  Widget build(BuildContext context) {
    final ({Color background, Color foreground}) colors = _colorsFor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  ({Color background, Color foreground}) _colorsFor(BmiCategory category) {
    switch (category) {
      case BmiCategory.underweight:
      case BmiCategory.overweight:
        return (background: palette.shade100, foreground: palette.shade900);
      case BmiCategory.normal:
        return (background: palette.shade300, foreground: palette.shade950);
      case BmiCategory.obese:
        return (background: palette.shade900, foreground: Colors.white);
    }
  }
}

class _GoalDeltaPill extends StatelessWidget {
  const _GoalDeltaPill({
    required this.palette,
    required this.deltaKg,
    required this.direction,
  });

  final JellyBeanPalette palette;
  final double deltaKg;
  final WeightGoalDirection direction;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (direction) {
      WeightGoalDirection.lose => Icons.trending_down_rounded,
      WeightGoalDirection.gain => Icons.trending_up_rounded,
      WeightGoalDirection.atGoal => Icons.check_rounded,
    };
    final String label = direction == WeightGoalDirection.atGoal
        ? 'At goal'
        : '${direction.label} ${deltaKg.toStringAsFixed(1)} kg';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: palette.shade900),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: palette.shade900,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
