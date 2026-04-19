class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.orderIndex,
  });

  final String id;
  final String workoutId;
  final String exerciseId;
  final int orderIndex;
}
