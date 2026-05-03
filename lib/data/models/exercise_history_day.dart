import 'workout_set.dart';

/// One day's worth of completed sets for a given exercise. Surfaces in the
/// per-exercise history screen so the user can scroll through every session
/// they've ever done that movement.
class ExerciseHistoryDay {
  const ExerciseHistoryDay({
    required this.date,
    required this.workoutId,
    required this.workoutName,
    required this.workoutStartedAt,
    required this.sets,
  });

  /// Local-time midnight for the day this session belongs to. Used as the
  /// grouping key and for the card header.
  final DateTime date;

  final String workoutId;
  final String? workoutName;
  final DateTime workoutStartedAt;

  /// Completed sets only, ordered by set number ascending.
  final List<WorkoutSet> sets;
}
