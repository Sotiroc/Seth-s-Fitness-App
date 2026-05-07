import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/exercise_type.dart';
import '../../../../data/models/pr_event.dart';
import '../../../../data/models/unit_system.dart';
import '../../../progression/application/pr_events_provider.dart';
import '../../../progression/presentation/widgets/pr_event_formatting.dart';

/// "Personal records" header card on the exercise history sheet.
/// Type-aware — for weighted exercises shows best set, e1RM, and the
/// rep-range bests; for cardio shows longest distance / duration; for
/// bodyweight shows most reps in a set / workout.
///
/// Collapses to nothing when no PRs exist (empty history or first-ever
/// session that hasn't been compared against priors yet).
class ExerciseHistoryPrCard extends StatelessWidget {
  const ExerciseHistoryPrCard({
    super.key,
    required this.palette,
    required this.bests,
    required this.exerciseType,
    required this.unitSystem,
    this.onTapEvent,
  });

  final JellyBeanPalette palette;
  final ExercisePrBests bests;
  final ExerciseType exerciseType;
  final UnitSystem unitSystem;

  /// Called when the user taps a single PR row. The receiver typically
  /// scrolls the parent history list to the day card that contains the
  /// originating set so the user can see the source session in context.
  /// `null` disables the tap behaviour entirely.
  final ValueChanged<PrEvent>? onTapEvent;

  @override
  Widget build(BuildContext context) {
    if (bests.isEmpty) return const SizedBox.shrink();

    final List<PrEvent> rows = _rowsForType();
    if (rows.isEmpty) return const SizedBox.shrink();

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
                      'PERSONAL RECORDS',
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
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: Colors.white.withValues(alpha: 0.10),
              ),
            _PrLine(
              event: rows[i],
              palette: palette,
              unitSystem: unitSystem,
              onTap: onTapEvent == null
                  ? null
                  : () => onTapEvent!(rows[i]),
            ),
          ],
        ],
      ),
    );
  }

  /// Picks which PRs to render in which order based on the exercise's
  /// type. Weighted leads with best set + e1RM, then rep-range bests
  /// sorted ascending by rep count. Cardio and bodyweight render their
  /// two domain PRs.
  List<PrEvent> _rowsForType() {
    switch (exerciseType) {
      case ExerciseType.weighted:
        final List<MapEntry<int, PrEvent>> repMaxRows = bests.repMaxes.entries
            .toList(growable: false)
          ..sort(
            (MapEntry<int, PrEvent> a, MapEntry<int, PrEvent> b) =>
                a.key.compareTo(b.key),
          );
        return <PrEvent>[
          if (bests.bestSet != null) bests.bestSet!,
          if (bests.e1rm != null) bests.e1rm!,
          for (final MapEntry<int, PrEvent> e in repMaxRows) e.value,
        ];
      case ExerciseType.bodyweight:
        return <PrEvent>[
          if (bests.mostRepsInSet != null) bests.mostRepsInSet!,
          if (bests.mostRepsInWorkout != null) bests.mostRepsInWorkout!,
        ];
      case ExerciseType.cardio:
        return <PrEvent>[
          if (bests.longestDistance != null) bests.longestDistance!,
          if (bests.longestDuration != null) bests.longestDuration!,
          if (bests.mostLaps != null) bests.mostLaps!,
          if (bests.mostFloors != null) bests.mostFloors!,
          if (bests.mostCalories != null) bests.mostCalories!,
        ];
    }
  }
}

class _PrLine extends StatelessWidget {
  const _PrLine({
    required this.event,
    required this.palette,
    required this.unitSystem,
    this.onTap,
  });

  final PrEvent event;
  final JellyBeanPalette palette;
  final UnitSystem unitSystem;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String value = PrEventFormatting.value(event, unitSystem);
    final String typeLabel = PrEventFormatting.typeLabel(event);
    final Widget content = Row(
      children: <Widget>[
        Expanded(
          child: Text(
            typeLabel,
            style: TextStyle(
              color: palette.shade100,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        if (onTap != null) ...<Widget>[
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: palette.shade100.withValues(alpha: 0.7),
          ),
        ],
      ],
    );

    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: content,
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: body,
      ),
    );
  }
}
