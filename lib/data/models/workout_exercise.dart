class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.orderIndex,
    this.createdAt,
  });

  final String id;
  final String workoutId;
  final String exerciseId;
  final int orderIndex;

  /// When the exercise was added to the workout. Counts as activity for
  /// the auto-close inactivity timer (so adding an exercise without
  /// logging any sets still keeps the workout alive). Nullable because
  /// pre-v9 rows are backfilled from the parent workout's `startedAt`.
  final DateTime? createdAt;
}
