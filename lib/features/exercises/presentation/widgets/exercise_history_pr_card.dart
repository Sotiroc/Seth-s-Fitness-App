import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/strength_point.dart';

/// Hero "personal record" card for an exercise's history view: shows the
/// best Epley-estimated 1RM the user has ever logged, the source set
/// (weight × reps), and the date it happened. Collapses to nothing when no
/// PR exists (empty history or non-weighted exercise).
class ExerciseHistoryPrCard extends StatelessWidget {
  const ExerciseHistoryPrCard({
    super.key,
    required this.palette,
    required this.pr,
  });

  final JellyBeanPalette palette;
  final StrengthPoint? pr;

  @override
  Widget build(BuildContext context) {
    final StrengthPoint? record = pr;
    if (record == null) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final String oneRm = _formatNumber(record.oneRepMaxKg);
    final String weight = _formatNumber(record.bestSetWeightKg);
    final String reps = '${record.bestSetReps}';
    final String dateLabel = DateFormat(
      'MMM d, yyyy',
    ).format(record.date.toLocal());

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade900, palette.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 13,
                      color: palette.shade100,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ALL-TIME BEST',
                      style: TextStyle(
                        color: palette.shade100,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                dateLabel,
                style: TextStyle(
                  color: palette.shade100.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                oneRm,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                  height: 1,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'kg',
                  style: TextStyle(
                    color: palette.shade200,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'est. 1RM',
                  style: TextStyle(
                    color: palette.shade200.withValues(alpha: 0.7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.fitness_center_rounded,
                  size: 14,
                  color: palette.shade100,
                ),
                const SizedBox(width: 6),
                Text(
                  'From $weight kg × $reps reps',
                  style: TextStyle(
                    color: palette.shade100,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}
