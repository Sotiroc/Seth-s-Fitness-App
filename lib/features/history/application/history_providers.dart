import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/repositories/workout_repository.dart';

part 'history_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<Workout>> workoutHistory(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchHistory();
}

@Riverpod(keepAlive: true)
Stream<WorkoutDetail> workoutDetail(Ref ref, String workoutId) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchWorkoutDetail(workoutId);
}
