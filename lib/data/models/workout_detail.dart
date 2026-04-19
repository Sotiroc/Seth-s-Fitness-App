import 'exercise.dart';
import 'workout.dart';
import 'workout_exercise.dart';
import 'workout_set.dart';

class WorkoutDetail {
  const WorkoutDetail({required this.workout, required this.exercises});

  final Workout workout;
  final List<WorkoutExerciseDetail> exercises;
}

class WorkoutExerciseDetail {
  const WorkoutExerciseDetail({
    required this.workoutExercise,
    required this.exercise,
    required this.sets,
  });

  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final List<WorkoutSet> sets;
}
