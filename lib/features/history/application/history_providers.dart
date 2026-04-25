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

/// Stable, ordered comma-joined string of finished workout ids. Recomputes on
/// every history emission, but only changes value when the *set* of finished
/// workouts itself changes — so the set-count provider keyed off this doesn't
/// refetch on unrelated workout-row updates (e.g. a renamed past session).
@Riverpod(keepAlive: true)
String historyWorkoutIdsSignature(Ref ref) {
  final List<Workout>? workouts = ref
      .watch(workoutHistoryProvider)
      .asData
      ?.value;
  if (workouts == null || workouts.isEmpty) return '';
  return workouts.map((w) => w.id).join(',');
}

/// Map of workoutId → completed-set count for every workout in history.
/// Used by the history list to render a sets tally on each tile. Depends on
/// [historyWorkoutIdsSignatureProvider] so it only re-runs when workouts are
/// added or removed.
@Riverpod(keepAlive: true)
Future<Map<String, int>> historyCompletedSetCounts(Ref ref) async {
  final String signature = ref.watch(historyWorkoutIdsSignatureProvider);
  if (signature.isEmpty) return const <String, int>{};
  final List<String> ids = signature.split(',');
  return ref
      .read(workoutRepositoryProvider)
      .getCompletedSetCountsForWorkouts(ids);
}
