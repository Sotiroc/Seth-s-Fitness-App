import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_template.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/template_repository.dart';
import '../../../data/repositories/workout_repository.dart';

part 'phase2_debug_snapshot_provider.g.dart';

class Phase2DebugSnapshot {
  const Phase2DebugSnapshot({
    required this.exercises,
    required this.templates,
    required this.completedWorkouts,
    this.activeWorkout,
  });

  final List<Exercise> exercises;
  final List<WorkoutTemplate> templates;
  final List<Workout> completedWorkouts;
  final Workout? activeWorkout;

  int get totalWorkoutCount =>
      completedWorkouts.length + (activeWorkout == null ? 0 : 1);
}

@riverpod
Future<Phase2DebugSnapshot> phase2DebugSnapshot(Ref ref) async {
  await ref.watch(databaseBootstrapProvider.future);

  final ExerciseRepository exerciseRepository = ref.watch(
    exerciseRepositoryProvider,
  );
  final TemplateRepository templateRepository = ref.watch(
    templateRepositoryProvider,
  );
  final WorkoutRepository workoutRepository = ref.watch(
    workoutRepositoryProvider,
  );

  final List<Exercise> exercises = await exerciseRepository.getAllExercises();
  final List<WorkoutTemplate> templates = await templateRepository
      .getAllTemplates();
  final List<Workout> completedWorkouts = await workoutRepository.listHistory();
  final Workout? activeWorkout = await workoutRepository.getActiveWorkout();

  return Phase2DebugSnapshot(
    exercises: exercises,
    templates: templates,
    completedWorkouts: completedWorkouts,
    activeWorkout: activeWorkout,
  );
}
