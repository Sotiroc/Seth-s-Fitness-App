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
}
