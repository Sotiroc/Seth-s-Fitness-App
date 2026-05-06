class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.orderIndex,
    this.createdAt,
    this.notes,
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

  /// Optional free-text note attached to this exercise within this specific
  /// workout (e.g. "left shoulder felt tight"). Trimmed at write time;
  /// null/empty means "no note".
  final String? notes;

  WorkoutExercise copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? orderIndex,
    DateTime? createdAt,
    String? notes,
    bool clearNotes = false,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      notes: clearNotes ? null : notes ?? this.notes,
    );
  }
}
