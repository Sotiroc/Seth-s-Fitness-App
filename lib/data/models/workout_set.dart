class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    required this.completed,
    this.weightKg,
    this.reps,
    this.distanceKm,
    this.durationSeconds,
  });

  final String id;
  final String workoutExerciseId;
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final double? distanceKm;
  final int? durationSeconds;
  final bool completed;

  WorkoutSet copyWith({
    String? id,
    String? workoutExerciseId,
    int? setNumber,
    double? weightKg,
    int? reps,
    double? distanceKm,
    int? durationSeconds,
    bool? completed,
    bool clearWeightKg = false,
    bool clearReps = false,
    bool clearDistanceKm = false,
    bool clearDurationSeconds = false,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setNumber: setNumber ?? this.setNumber,
      weightKg: clearWeightKg ? null : weightKg ?? this.weightKg,
      reps: clearReps ? null : reps ?? this.reps,
      distanceKm: clearDistanceKm ? null : distanceKm ?? this.distanceKm,
      durationSeconds: clearDurationSeconds
          ? null
          : durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
    );
  }
}
