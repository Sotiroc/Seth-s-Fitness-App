import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/workout_repository.dart';

final StreamProvider<WorkoutDetail?> activeWorkoutDetailProvider =
    StreamProvider<WorkoutDetail?>((Ref ref) async* {
      await ref.watch(databaseBootstrapProvider.future);
      yield* ref.watch(workoutRepositoryProvider).watchActiveWorkoutDetail();
    });

final FutureProvider<List<Exercise>> workoutExerciseOptionsProvider =
    FutureProvider<List<Exercise>>((Ref ref) async {
      await ref.watch(databaseBootstrapProvider.future);
      return ref.watch(exerciseRepositoryProvider).getAllExercises();
    });

/// One-shot loader for a finished workout (summary screen).
final workoutDetailByIdProvider = FutureProvider.family<WorkoutDetail, String>((
  Ref ref,
  String id,
) async {
  await ref.watch(databaseBootstrapProvider.future);
  return ref.watch(workoutRepositoryProvider).getWorkoutById(id);
});
