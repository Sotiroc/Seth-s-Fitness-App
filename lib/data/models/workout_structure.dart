import 'exercise.dart';
import 'workout.dart';
import 'workout_exercise.dart';

/// Structural shell of a workout, without any per-set data. The detail
/// screen splits its data sources into structure (rare changes — only
/// when an exercise is added, removed, or renamed) and per-exercise sets
/// (frequent changes — every keystroke during an active session, every
/// kind/RPE/note tweak on the detail screen). The shell stays stable
/// across set edits so the hero, section labels, and per-exercise card
/// frames don't repaint when the user only changes a set's kind.
class WorkoutStructure {
  const WorkoutStructure({required this.workout, required this.exercises});

  final Workout workout;
  final List<WorkoutExerciseStructure> exercises;
}

class WorkoutExerciseStructure {
  const WorkoutExerciseStructure({
    required this.workoutExercise,
    required this.exercise,
  });

  final WorkoutExercise workoutExercise;
  final Exercise exercise;
}
