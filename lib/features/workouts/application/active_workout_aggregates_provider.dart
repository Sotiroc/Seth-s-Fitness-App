import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/workout_detail.dart';
import '../../../data/models/workout_set.dart';
import 'active_workout_provider.dart';

part 'active_workout_aggregates_provider.g.dart';

/// Header-level numbers for the active workout: working-set totals,
/// completion count, and exercise count. Computed once per detail
/// emission and short-circuited by value-equality so the gradient header
/// and Finish button don't rebuild on keystrokes that don't move the
/// counters (e.g. typing into a weight field that's already part of an
/// existing working set).
class ActiveWorkoutAggregates {
  const ActiveWorkoutAggregates({
    required this.totalSets,
    required this.completedSets,
    required this.exerciseCount,
  });

  static const ActiveWorkoutAggregates empty = ActiveWorkoutAggregates(
    totalSets: 0,
    completedSets: 0,
    exerciseCount: 0,
  );

  /// Working sets only (warm-ups excluded).
  final int totalSets;

  /// Completed working sets (warm-ups excluded).
  final int completedSets;

  /// Number of exercises currently on the workout.
  final int exerciseCount;

  bool get hasAnyCompletedSet => completedSets > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveWorkoutAggregates &&
        other.totalSets == totalSets &&
        other.completedSets == completedSets &&
        other.exerciseCount == exerciseCount;
  }

  @override
  int get hashCode => Object.hash(totalSets, completedSets, exerciseCount);
}

@Riverpod(keepAlive: true)
ActiveWorkoutAggregates activeWorkoutAggregates(Ref ref) {
  final WorkoutDetail? detail = ref
      .watch(activeWorkoutDetailProvider)
      .asData
      ?.value;
  if (detail == null) return ActiveWorkoutAggregates.empty;
  int total = 0;
  int completed = 0;
  for (final WorkoutExerciseDetail e in detail.exercises) {
    for (final WorkoutSet s in e.sets) {
      if (!s.kind.countsAsWorkingSet) continue;
      total++;
      if (s.completed) completed++;
    }
  }
  return ActiveWorkoutAggregates(
    totalSets: total,
    completedSets: completed,
    exerciseCount: detail.exercises.length,
  );
}
