import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../data/models/exercise_history_day.dart';
import '../../../../data/models/exercise_type.dart';
import '../../../../data/models/workout_set.dart';

/// One workout day's worth of completed sets for an exercise. Used by the
/// exercise history sheet (and any future per-exercise history surface) to
/// render each session as a self-contained card.
///
/// [prSetIds] is the set of WorkoutSet ids that established a new estimated
/// 1RM PR at the time they were logged. Sets whose id is in this collection
/// render with a trophy badge.
class ExerciseHistoryDayCard extends StatelessWidget {
  const ExerciseHistoryDayCard({
    super.key,
    required this.day,
    required this.palette,
    required this.exerciseType,
    this.prSetIds = const <String>{},
  });

  final ExerciseHistoryDay day;
  final JellyBeanPalette palette;
  final ExerciseType exerciseType;
  final Set<String> prSetIds;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String dateLabel = _relativeDate(day.date);
    final String? subtitle = day.workoutName?.trim().isNotEmpty == true
        ? day.workoutName!.trim()
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.shade100),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: palette.shade800,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      dateLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.shade950,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: palette.shade700,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ExerciseHistorySetCountBadge(
                count: day.sets.length,
                palette: palette,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (int i = 0; i < day.sets.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == day.sets.length - 1 ? 0 : 2,
              ),
              child: ExerciseHistorySetTile(
                palette: palette,
                set: day.sets[i],
                exerciseType: exerciseType,
                isPr: prSetIds.contains(day.sets[i].id),
              ),
            ),
        ],
      ),
    );
  }
}

class ExerciseHistorySetCountBadge extends StatelessWidget {
  const ExerciseHistorySetCountBadge({
    super.key,
    required this.count,
    required this.palette,
  });

  final int count;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.shade900,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count == 1 ? '1 set' : '$count sets',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class ExerciseHistorySetTile extends StatelessWidget {
  const ExerciseHistorySetTile({
    super.key,
    required this.palette,
    required this.set,
    required this.exerciseType,
    this.isPr = false,
  });

  final JellyBeanPalette palette;
  final WorkoutSet set;
  final ExerciseType exerciseType;
  final bool isPr;

  @override
  Widget build(BuildContext context) {
    // No filled tint background — the set tiles sit directly on the day
    // card's white surface so consecutive sets read as a tight list
    // rather than a stack of pills. The set-number bubble carries the
    // weight of the visual structure.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 4,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.shade100,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${set.setNumber}',
              style: TextStyle(
                color: palette.shade900,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _formatSet(set, exerciseType),
              style: TextStyle(
                color: palette.shade950,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (isPr) ...<Widget>[
            const SizedBox(width: 8),
            const Icon(
              Icons.emoji_events_rounded,
              size: 18,
              color: Color(0xFF1976D2),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatSet(WorkoutSet set, ExerciseType type) {
  switch (type) {
    case ExerciseType.weighted:
      final String weight = set.weightKg != null
          ? _formatNumber(set.weightKg!)
          : '—';
      final String reps = set.reps != null ? '${set.reps}' : '—';
      return '$weight kg × $reps reps';
    case ExerciseType.bodyweight:
      final String reps = set.reps != null ? '${set.reps}' : '—';
      return '$reps reps';
    case ExerciseType.cardio:
      final String distance = set.distanceKm != null
          ? '${_formatNumber(set.distanceKm!)} km'
          : '—';
      final String duration = set.durationSeconds != null
          ? DurationFormatter.formatSeconds(set.durationSeconds!)
          : '—';
      return '$distance · $duration';
  }
}

String _formatNumber(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

String _relativeDate(DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final int diffDays = today.difference(date).inDays;
  if (diffDays == 0) return 'Today';
  if (diffDays == 1) return 'Yesterday';
  if (diffDays < 7) return DateFormat('EEEE').format(date);
  if (date.year == now.year) return DateFormat('EEE, MMM d').format(date);
  return DateFormat('MMM d, yyyy').format(date);
}
