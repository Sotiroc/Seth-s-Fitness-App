import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/exercise_history_day.dart';

/// Aggregate stat strip shown at the top of an exercise's history list:
/// total sessions and total completed sets.
class ExerciseHistorySummary extends StatelessWidget {
  const ExerciseHistorySummary({
    super.key,
    required this.history,
    required this.palette,
  });

  final List<ExerciseHistoryDay> history;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    final int sessions = history.length;
    final int totalSets = history.fold<int>(
      0,
      (sum, day) => sum + day.sets.length,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.shade100),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SummaryStat(
              palette: palette,
              value: '$sessions',
              label: sessions == 1 ? 'Session' : 'Sessions',
            ),
          ),
          Container(width: 1, height: 32, color: palette.shade100),
          Expanded(
            child: _SummaryStat(
              palette: palette,
              value: '$totalSets',
              label: totalSets == 1 ? 'Total set' : 'Total sets',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.palette,
    required this.value,
    required this.label,
  });

  final JellyBeanPalette palette;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            color: palette.shade950,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: palette.shade700,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
