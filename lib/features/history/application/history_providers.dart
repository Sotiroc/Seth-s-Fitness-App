import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_detail.dart';
import '../../../data/repositories/workout_repository.dart';

final StreamProvider<List<Workout>> workoutHistoryProvider =
    StreamProvider<List<Workout>>((Ref ref) async* {
      await ref.watch(databaseBootstrapProvider.future);
      yield* ref.watch(workoutRepositoryProvider).watchHistory();
    });

final workoutDetailProvider = StreamProvider.family<WorkoutDetail, String>((
  Ref ref,
  String workoutId,
) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(workoutRepositoryProvider).watchWorkoutDetail(workoutId);
});
