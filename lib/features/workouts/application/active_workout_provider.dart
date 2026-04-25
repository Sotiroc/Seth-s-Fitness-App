import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/workout_repository.dart';

part 'active_workout_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<WorkoutDetail?> activeWorkoutDetail(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchActiveWorkoutDetail();
}

@Riverpod(keepAlive: true)
Future<List<Exercise>> workoutExerciseOptions(Ref ref) async {
  await ref.watch(databaseBootstrapProvider.future);
  return ref.watch(exerciseRepositoryProvider).getAllExercises();
}

/// One-shot loader for a finished workout (summary screen).
@Riverpod(keepAlive: true)
Future<WorkoutDetail> workoutDetailById(Ref ref, String id) async {
  await ref.watch(databaseBootstrapProvider.future);
  return ref.watch(workoutRepositoryProvider).getWorkoutById(id);
}
